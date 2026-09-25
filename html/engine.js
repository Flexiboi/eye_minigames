window.duiController = window.duiController || {
    ready: false,
    sessionId: null,
    resource: null,
    init: function() {
        this.ready = true;
        console.log('DUI Controller initialized');
        
    },
    setSession: function(sessionId) {
        this.sessionId = sessionId;
    },
    setResource: function(resource) {
        this.resource = resource;
    }
};
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
        window.duiController.init();
    });
} else {
    window.duiController.init();
}

const MG = (function () {
    const games = {};
    let current = null;
    let raf = null;
    let timer = null;
    let ended = false;
    let sessionNonce = null;
    let duiMode = false;
    let duiPropMode = false;
    let duiPreview = false;
    let duiController = false;
    let duiSession = null;
    let duiSeed = 0;
    let captureOnly = false;
    let allowCancelFlag = true;
    let duiClockOffset = 0;
    let lastMouseForward = 0;
    let lastClockForward = 0;
    let applyingDuiInput = false;
    let duiClockTimer = null;
    const nativeRandom = Math.random;

    const $ = (id) => document.getElementById(id);

    function setDuiSeed(seed) {
        if (!duiMode || !Number.isFinite(Number(seed))) {
            Math.random = nativeRandom;
            return;
        }
        let state = (Number(seed) >>> 0) || 1;
        Math.random = function () {
            state = (Math.imul(1664525, state) + 1013904223) >>> 0;
            return state / 4294967296;
        };
    }

    function syncedNow() {
        if (duiMode && duiController) {
            return performance.now() + duiClockOffset;
        }
        return performance.now();
    }

    function forwardDuiClock(force) {
        if (!duiController || !duiSession) return;
        const now = performance.now();
        if (!force && now - lastClockForward < 500) return;
        lastClockForward = now;
        
        const timerData = timer ? {
            duration: timer.duration,
            remaining: Math.max(0, timer.duration - (now - timer.start + (duiClockOffset || 0)))
        } : null;
        
        post('duiClock', {
            elapsed: now - (window.__duiStartTime || now),
            timer: timerData
        });
    }
    function inputPayload(e) {
        let key = e.key || '';

        // CEF/FiveM can occasionally report alphabetic key values
        // in lowercase even when Shift is held. Preserve the actual
        // Shift state for letter keys.
        if (e.shiftKey && key.length === 1 && /^[a-z]$/.test(key)) {
            key = key.toUpperCase();
        }

        return {
            type: e.type === 'pointermove' ? 'mousemove' :
                (e.type === 'pointerdown' ? 'mousedown' :
                (e.type === 'pointerup' ? 'mouseup' : e.type)),
            key: key,
            code: e.code || '',
            location: typeof e.location === 'number' ? e.location : 0,
            repeat: !!e.repeat,
            ctrlKey: !!e.ctrlKey,
            shiftKey: !!e.shiftKey,
            altKey: !!e.altKey,
            metaKey: !!e.metaKey
        };
}

    function forwardDuiKeyboard(e) {
        if (!captureOnly || !duiController || !duiSession || ended) return;
        if (e.type !== 'keydown' && e.type !== 'keyup') return;
        if (e.isComposing) return;

        // Escape must be handled by the fullscreen NUI controller, not sent
        // into the hidden keyboard bridge / DUI page. Doing this here (at
        // capture phase) makes cancellation reliable even when the hidden
        // input has focus and the normal document key handler is bypassed.
        if (e.type === 'keydown' && e.key === 'Escape') {
            e.preventDefault();
            e.stopPropagation();
            if (allowCancelFlag) {
                post('closed', { nonce: sessionNonce });
            }
            return;
        }

        const payload = inputPayload(e);
        post('duiInput', payload);
        if (e.type === 'keydown') e.preventDefault();
    }

    function installDuiCapture() {
        if (!captureOnly || !duiController) return;
        document.addEventListener('keydown', forwardDuiKeyboard, true);
        document.addEventListener('keyup', forwardDuiKeyboard, true);
    }

    function removeDuiCapture() {
        document.removeEventListener('keydown', forwardDuiKeyboard, true);
        document.removeEventListener('keyup', forwardDuiKeyboard, true);
        if (duiClockTimer) clearInterval(duiClockTimer);
        duiClockTimer = null;
    }

    let duiLastFocusedElement = null;

    document.addEventListener('focusin', (e) => {
        if (isDuiDocument()) {
            duiLastFocusedElement = e.target || null;
        }
    }, true);

    document.addEventListener('focusout', (e) => {
        if (isDuiDocument() && duiLastFocusedElement === e.target) {
            setTimeout(() => {
                if (!document.activeElement || document.activeElement === document.body) {
                    duiLastFocusedElement = null;
                }
            }, 0);
        }
    }, true);

    function dispatchDuiInput(d) {
        if (!duiMode || !d || typeof d.type !== 'string') return;
        if (d.type === 'keydown' || d.type === 'keyup') {
            applyingDuiInput = true;
            const active = (duiLastFocusedElement && duiLastFocusedElement.isConnected)
                ? duiLastFocusedElement
                : (document.activeElement || document.body);
            const ev = new KeyboardEvent(d.type, {
                key: d.key || '',
                code: d.code || '',
                location: d.location || 0,
                repeat: !!d.repeat,
                ctrlKey: !!d.ctrlKey,
                shiftKey: !!d.shiftKey,
                altKey: !!d.altKey,
                metaKey: !!d.metaKey,
                bubbles: true,
                cancelable: true,
                view: window
            });
            try { active.dispatchEvent(ev); } catch (_) {}

            // Synthetic KeyboardEvents are not trusted and therefore do not
            // perform the browser's default text-editing action. When the
            // DUI currently has a real <input>, <textarea>, or contenteditable
            // focused, reproduce the edit explicitly so password/text fields
            // remain fully usable through the NUI -> DUI input bridge.
            if (d.type === 'keydown' && !d.ctrlKey && !d.metaKey && !d.altKey) {
                try {
                    const tag = (active.tagName || '').toLowerCase();
                    const editable = active.isContentEditable ||
                        tag === 'input' || tag === 'textarea';

                    if (editable && typeof d.key === 'string') {
                        if (d.key === 'Backspace' || d.key === 'Delete') {
                            if (tag === 'input' || tag === 'textarea') {
                                const value = String(active.value || '');
                                const start = Number.isFinite(active.selectionStart)
                                    ? active.selectionStart : value.length;
                                const end = Number.isFinite(active.selectionEnd)
                                    ? active.selectionEnd : start;

                                if (d.key === 'Backspace') {
                                    const from = start === end ? Math.max(0, start - 1) : start;
                                    active.value = value.slice(0, from) + value.slice(end);
                                    active.setSelectionRange(from, from);
                                } else {
                                    const to = start === end ? Math.min(value.length, end + 1) : end;
                                    active.value = value.slice(0, start) + value.slice(to);
                                    active.setSelectionRange(start, start);
                                }
                                active.dispatchEvent(new Event('input', { bubbles: true }));
                            }
                        } else if (d.key.length === 1) {
                            if (tag === 'input' || tag === 'textarea') {
                                const value = String(active.value || '');
                                const start = Number.isFinite(active.selectionStart)
                                    ? active.selectionStart : value.length;
                                const end = Number.isFinite(active.selectionEnd)
                                    ? active.selectionEnd : start;
                                const next = value.slice(0, start) + d.key + value.slice(end);
                                active.value = next;
                                const caret = start + d.key.length;
                                active.setSelectionRange(caret, caret);
                                active.dispatchEvent(new Event('input', { bubbles: true }));
                            } else if (active.isContentEditable) {
                                document.execCommand('insertText', false, d.key);
                            }
                        }
                    }
                } catch (_) {}
            }

            applyingDuiInput = false;
            return;
        }

        if (duiController) return;
        if (typeof d.x !== 'number' || typeof d.y !== 'number') return;
        const x = Math.max(0, Math.min(1, d.x)) * window.innerWidth;
        const y = Math.max(0, Math.min(1, d.y)) * window.innerHeight;
        const target = document.elementFromPoint(x, y) || document.body;

        if (d.type === 'wheel') {
            target.dispatchEvent(new WheelEvent('wheel', {
                clientX: x, clientY: y, deltaX: Number(d.deltaX || 0),
                deltaY: Number(d.deltaY || 0), bubbles: true, cancelable: true, view: window
            }));
        } else if (d.type === 'mouseleave') {
            target.dispatchEvent(new MouseEvent('mouseleave', {
                clientX: x, clientY: y, bubbles: false, cancelable: true, view: window
            }));
        } else if (d.type === 'mousemove' || d.type === 'mousedown' || d.type === 'mouseup') {
            target.dispatchEvent(new MouseEvent(d.type, {
                clientX: x, clientY: y, button: Number(d.button || 0),
                buttons: Number(d.buttons || 0), bubbles: true, cancelable: true, view: window
            }));
            if (d.type === 'mouseup' && Number(d.button || 0) === 0) {
                target.dispatchEvent(new MouseEvent('click', {
                    clientX: x, clientY: y, button: 0, buttons: 0,
                    bubbles: true, cancelable: true, view: window
                }));
            }
        }
        applyingDuiInput = false;
    }

    function isDuiDocument() {
        // Prefer the runtime's own view: it is armed by Lua's duiInit message
        // and does not depend on CEF exposing a query string on a nui:// URL.
        try {
            if (window.DuiVirtualCursor && window.DuiVirtualCursor.isDui()) return true;
        } catch (e) {}
        try {
            return new URLSearchParams(window.location.search).get('dui') === '1';
        } catch (e) {
            return false;
        }
    }
    function bridgeToNui(name, body) {
        if (!isDuiDocument() || typeof window.invokeNative !== 'function') return;
        try {
            window.invokeNative('sendNUIMessage', JSON.stringify({
                action: '__eye_dui_bridge',
                name: name,
                body: body || {}
            }));
        } catch (e) {}
    }

    function apiBase() {
        if (window.__duiApi) return window.__duiApi;
        try {
            return new URLSearchParams(window.location.search).get('api') || '';
        } catch (e) {
            return '';
        }
    }

    function duiSessionId() {
        if (duiSession) return duiSession;
        if (window.__duiSession) return window.__duiSession;
        try {
            return new URLSearchParams(window.location.search).get('session') || null;
        } catch (e) {
            return null;
        }
    }

    function post(name, body) {
        const payload = body || {};

        // A DUI browser has no NUI callback channel, so `fetch` at
        // https://resource/name silently fails there. Only 'result' and
        // 'closed' actually need to reach Lua, and they go over the server's
        // HTTP endpoint instead. Everything else is a no-op from the DUI.
        if (isDuiDocument()) {
            if (name !== 'result' && name !== 'closed') return;

            const base = apiBase();
            if (!base) {
                console.warn('[DUI] no ?api= base url, result cannot be reported');
                return;
            }

            payload.session = duiSessionId();

            fetch(`${base}/${name}`, {
                method: 'POST',
                // text/plain keeps this a CORS "simple request", so the
                // browser skips the OPTIONS preflight entirely.
                headers: { 'Content-Type': 'text/plain;charset=UTF-8' },
                body: JSON.stringify(payload)
            }).catch(() => {});
            return;
        }

        fetch(`https://${resName()}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(payload)
        }).catch(() => {});
    }
    function resName() {
        if (typeof GetParentResourceName === 'function') return GetParentResourceName();
        try {
            const q = new URLSearchParams(window.location.search);
            return q.get('resource') || 'eye_minigames';
        } catch (e) {
            return 'eye_minigames';
        }
    }
    window.addEventListener('message', (ev) => {
        const d = (typeof ev.data === 'string')
            ? (() => { try { return JSON.parse(ev.data) || {}; } catch (e) { return {}; } })()
            : (ev.data || {});
        if (d.action !== '__eye_dui_bridge' || isDuiDocument()) return;
        if (typeof d.name !== 'string') return;
        const allowed = { duiReady: true, result: true, closed: true, duiGameEnded: true, duiClock: true, duiViewport: true, duiInput: true };
        if (!allowed[d.name]) return;
        post(d.name, d.body || {});
    });

    function reportDuiViewport() {
        if (!isDuiDocument()) return;
        try {
            const q = new URLSearchParams(window.location.search);
            post('duiViewport', {
                dui: true,
                session: q.get('session') || null,
                width: Math.max(1, Math.round(window.innerWidth || document.documentElement.clientWidth || 1)),
                height: Math.max(1, Math.round(window.innerHeight || document.documentElement.clientHeight || 1))
            });
        } catch (e) {}
    }

    window.addEventListener('load', () => {
        try {
            const q = new URLSearchParams(window.location.search);
            if (q.get('dui') === '1') {
                reportDuiViewport();
                post('duiReady', {
                    dui: true,
                    session: q.get('session') || null,
                    gamesReady: !!(games && games.vaultspin),
                    gameCount: Object.keys(games).length
                });
            }
        } catch (e) {}
    }, { once: true });

    window.addEventListener('resize', reportDuiViewport);

    function startTimer(seconds, onExpire) {
        const duration = seconds * 1000;
        const startTime = syncedNow();
        timer = { 
            duration: duration, 
            start: startTime, 
            onExpire: duiPreview ? null : onExpire 
        };
        if (duiMode && duiController) {
            forwardDuiClock(true);
        }
        tick();
    }
    
    function tick() {
        if (!timer) return;
        const now = syncedNow();
        const elapsed = now - timer.start;
        const remain = Math.max(0, timer.duration - elapsed);
        const pct = remain / timer.duration;
        
        const fill = $('timer-fill');
        const text = $('timer-text');
        
        if (fill) {
            fill.style.width = (pct * 100) + '%';
            fill.style.background = pct < 0.25
                ? 'linear-gradient(90deg, var(--danger), #fff)'
                : 'linear-gradient(90deg, var(--accent), #fff)';
        }
        
        if (text) {
            text.textContent = (remain / 1000).toFixed(1);
        }
        
        if (duiMode && duiController && duiSession) {
            if (!window.__lastClockForward || now - window.__lastClockForward >= 500) {
                window.__lastClockForward = now;
                forwardDuiClock(false);
            }
        }
        
        if (remain <= 0) {
            const fn = timer.onExpire;
            timer = null;
            if (fn) fn();
            return;
        }
        raf = requestAnimationFrame(tick);
    }
    
    function stopTimer() {
        if (raf) cancelAnimationFrame(raf);
        raf = null; timer = null;
    }
    function addTime(ms) {
        if (timer) timer.start += ms;
    }

    function setDots(total, states) {
        const c = $('dots'); c.innerHTML = '';
        for (let i = 0; i < total; i++) {
            const d = document.createElement('div');
            d.className = 'dot' + (states && states[i] ? ' ' + states[i] : '');
            c.appendChild(d);
        }
    }


    // The visible DUI browser cannot receive FiveM's NUI cursor directly.
    // The fullscreen NUI owns the cursor while the DUI is rendered in-world,
    // so forward the actual DOM mouse events to Lua. Lua raycasts those
    // normalized coordinates onto the configured world/prop screen.
    let duiMouseCaptureInstalled = false;
    let duiMouseOverlay = null;

    function duiMousePayload(e) {
        const w = Math.max(1, window.innerWidth || document.documentElement.clientWidth || 1);
        const h = Math.max(1, window.innerHeight || document.documentElement.clientHeight || 1);

        return {
            type: e.type,
            x: Math.max(0, Math.min(1, Number(e.clientX || 0) / w)),
            y: Math.max(0, Math.min(1, Number(e.clientY || 0) / h)),
            screenX: Number(e.clientX || 0),
            screenY: Number(e.clientY || 0),
            button: Number.isFinite(Number(e.button)) ? Number(e.button) : 0,
            buttons: Number(e.buttons || 0),
            deltaX: Number(e.deltaX || 0),
            deltaY: Number(e.deltaY || 0)
        };
    }

    function forwardDuiMouse(e) {
        if (!captureOnly || !duiController || !duiSession || ended) return;

        // Only the fullscreen NUI capture layer should forward mouse input.
        // The actual DUI document is never allowed to re-forward its own events.
        if (isDuiDocument()) return;

        const eventType = e.type === 'pointermove' ? 'mousemove' :
            (e.type === 'pointerdown' ? 'mousedown' :
            (e.type === 'pointerup' ? 'mouseup' : e.type));

        if (eventType !== 'mousemove' && eventType !== 'mousedown' &&
            eventType !== 'mouseup' && eventType !== 'wheel') return;

        // Mousemove can fire hundreds of times per second. Keep the NUI
        // callback rate bounded while sending button events immediately.
        if (e.type === 'mousemove') {
            const now = performance.now();
            if (now - lastMouseForward < 8) return;
            lastMouseForward = now;
        }

        const payload = duiMousePayload(e);
        post('duiInput', payload);

        // NUI is only an input transport here; do not let the hidden page
        // consume clicks/scrolling or select anything.
        if (e.cancelable) e.preventDefault();
    }

    function installDuiMouseCapture() {
        if (duiMouseCaptureInstalled || !captureOnly || !duiController || isDuiDocument()) return;

        // NUI can otherwise have no hit-testable element when the normal
        // minigame root is hidden. Create a transparent fullscreen hit target
        // so Chromium/CEF always delivers real mouse events while SetNuiFocus
        // is active. The element never draws anything and only exists as an
        // input transport.
        const overlay = document.createElement('div');
        overlay.id = '__eye_dui_mouse_capture';
        overlay.style.cssText = [
            'position:fixed',
            'inset:0',
            'width:100vw',
            'height:100vh',
            'z-index:2147483647',
            'background:transparent',
            'opacity:0.001',
            'pointer-events:auto',
            'cursor:default',
            'user-select:none',
            '-webkit-user-select:none'
        ].join(';');
        document.body.appendChild(overlay);
        duiMouseOverlay = overlay;

        overlay.addEventListener('mousemove', forwardDuiMouse, true);
        overlay.addEventListener('mousedown', forwardDuiMouse, true);
        overlay.addEventListener('mouseup', forwardDuiMouse, true);
        overlay.addEventListener('pointermove', forwardDuiMouse, true);
        overlay.addEventListener('pointerdown', forwardDuiMouse, true);
        overlay.addEventListener('pointerup', forwardDuiMouse, true);
        overlay.addEventListener('wheel', forwardDuiMouse, { capture: true, passive: false });

        // Keep window listeners too. This covers browser-generated mouse
        // events which originate outside the overlay during focus/cursor
        // transitions.
        window.addEventListener('mousemove', forwardDuiMouse, true);
        window.addEventListener('mousedown', forwardDuiMouse, true);
        window.addEventListener('mouseup', forwardDuiMouse, true);
        window.addEventListener('pointermove', forwardDuiMouse, true);
        window.addEventListener('pointerdown', forwardDuiMouse, true);
        window.addEventListener('pointerup', forwardDuiMouse, true);
        window.addEventListener('wheel', forwardDuiMouse, { capture: true, passive: false });

        duiMouseCaptureInstalled = true;
    }

    function removeDuiMouseCapture() {
        if (!duiMouseCaptureInstalled) return;

        window.removeEventListener('mousemove', forwardDuiMouse, true);
        window.removeEventListener('mousedown', forwardDuiMouse, true);
        window.removeEventListener('mouseup', forwardDuiMouse, true);
        window.removeEventListener('pointermove', forwardDuiMouse, true);
        window.removeEventListener('pointerdown', forwardDuiMouse, true);
        window.removeEventListener('pointerup', forwardDuiMouse, true);
        window.removeEventListener('wheel', forwardDuiMouse, true);

        if (duiMouseOverlay) {
            duiMouseOverlay.removeEventListener('mousemove', forwardDuiMouse, true);
            duiMouseOverlay.removeEventListener('mousedown', forwardDuiMouse, true);
            duiMouseOverlay.removeEventListener('mouseup', forwardDuiMouse, true);
            duiMouseOverlay.removeEventListener('pointermove', forwardDuiMouse, true);
            duiMouseOverlay.removeEventListener('pointerdown', forwardDuiMouse, true);
            duiMouseOverlay.removeEventListener('pointerup', forwardDuiMouse, true);
            duiMouseOverlay.removeEventListener('wheel', forwardDuiMouse, true);
            try { duiMouseOverlay.remove(); } catch (_) {}
            duiMouseOverlay = null;
        }

        duiMouseCaptureInstalled = false;
    }

    let duiKeyboardCapture = null;

    function installDuiKeyboardCapture() {
        if (!captureOnly) return;
        installDuiMouseCapture();
        removeDuiKeyboardCapture();

        const input = document.createElement('input');
        input.type = 'text';
        input.autocomplete = 'off';
        input.autocorrect = 'off';
        input.autocapitalize = 'off';
        input.spellcheck = false;
        input.tabIndex = 0;
        input.setAttribute('aria-hidden', 'true');
        input.style.cssText = [
            'position:fixed',
            'left:-10000px',
            'top:-10000px',
            'width:1px',
            'height:1px',
            'opacity:0',
            'pointer-events:none'
        ].join(';');

        document.body.appendChild(input);
        duiKeyboardCapture = input;

        const focusCapture = () => {
            if (!duiKeyboardCapture || !captureOnly) return;
            if (document.activeElement !== duiKeyboardCapture) {
                try { duiKeyboardCapture.focus({ preventScroll: true }); }
                catch (_) { try { duiKeyboardCapture.focus(); } catch (__) {} }
            }
        };

        input.addEventListener('blur', () => setTimeout(focusCapture, 0));
        setTimeout(focusCapture, 0);
    }

    function removeDuiKeyboardCapture() {
        removeDuiMouseCapture();
        if (!duiKeyboardCapture) return;
        try { duiKeyboardCapture.blur(); } catch (_) {}
        try { duiKeyboardCapture.remove(); } catch (_) {}
        duiKeyboardCapture = null;
    }

    function open(payload) {
        const incomingSession = payload && payload.duiSession ? String(payload.duiSession) : null;
        if (incomingSession && duiSession === incomingSession && (current || captureOnly)) {
            return;
        }
        if (current || timer || duiClockTimer) {
            cleanup();
        }

        ended = false;
        duiMode = !!payload.duiPreview || !!payload.duiController || !!payload.duiMode;
        duiPreview = !!payload.duiPreview;
        duiController = !!payload.duiController;
        duiPropMode = !!payload.prop && duiController;
        duiSession = payload.duiSession || null;
        duiSeed = payload.duiSeed || 0;
        captureOnly = !!payload.captureOnly;

        // Second safety net. If duiInit was missed (sent before the page's
        // scripts were live, say) the open payload carries the same details,
        // so the cursor and keyboard bridge still come up.
        if (payload.duiMode && window.DuiVirtualCursor) {
            try {
                window.DuiVirtualCursor.activate({
                    session: payload.duiSession || null,
                    api: payload.duiApi || null
                });
            } catch (e) {}
        }
        allowCancelFlag = payload.allowCancel !== false;
        duiClockOffset = 0;
        lastMouseForward = 0;
        lastClockForward = 0;
        window.__duiStartTime = performance.now();
        setDuiSeed(duiSeed);
        removeDuiCapture();
        
        const stage = $('stage');
        if (duiMode) {
            stage.classList.add('dui-mode');
            stage.style.width = '100vw';
            stage.style.height = '100vh';
            stage.style.maxWidth = '100vw';
            stage.style.maxHeight = '100vh';
            stage.style.borderRadius = '0';
        } else {
            stage.classList.remove('dui-mode');
            stage.style.width = '';
            stage.style.height = '';
            stage.style.maxWidth = '';
            stage.style.maxHeight = '';
            stage.style.borderRadius = '';
        }
        
        if (duiController && captureOnly) installDuiCapture();
        sessionNonce = payload.nonce || null;
        if (captureOnly) {
            $('root').classList.add('hidden');
            installDuiKeyboardCapture();
            return;
        }
        if (typeof SFX !== 'undefined') {
            if (duiPreview) SFX.setEnabled(false);
            else if (payload.sound === false) SFX.setEnabled(false);
            else SFX.setEnabled(true);
            if (typeof payload.volume === 'number') SFX.setVolume(payload.volume);
        }
        const game = games[payload.game];
        $('root').classList.remove('hidden');
        $('flash').className = 'hidden';

        const name = game ? game.title : payload.game;
        $('hud-name').textContent = name;
        $('hud-tag').textContent = 'SECURE TASK';
        $('hint').textContent = (game && game.hint) ? game.hint : '';
        $('board').innerHTML = '';
        setDots(0);

        if (!game) { return end(false); }

        const api = {
            board: $('board'),
            cfg: payload,
            startTimer, stopTimer, addTime, setDots,
            setHint: (t) => { $('hint').textContent = t || ''; },
            setTag:  (t) => { $('hud-tag').textContent = t || ''; },
            succeed: () => end(true),
            fail:    () => end(false),
            shake:   () => { $('stage').classList.add('shake');
                             if (typeof SFX !== 'undefined') SFX.play('bad');
                             setTimeout(() => $('stage').classList.remove('shake'), 320); },
            sfx:     (name) => { if (typeof SFX !== 'undefined') SFX.play(name); },
            rand: (a, b) => a + Math.random() * (b - a),
            randInt: (a, b) => Math.floor(a + Math.random() * (b - a + 1))
        };

        current = game.run(api) || {};
        current.__allowCancel = allowCancelFlag;
        $('hud-timer').style.visibility = timer ? 'visible' : 'visible';
        
        if (duiMode && duiController) {
            setTimeout(() => forwardDuiClock(true), 100);
        }
    }

    function cleanup() {
        removeDuiCapture();
        removeDuiKeyboardCapture();
        stopTimer();
        if (current && typeof current.destroy === 'function') {
            try { current.destroy(); } catch (e) {}
        }
        current = null;
        document.onkeydown = null;
    }
    function fullReset() {
        cleanup();
        ended = true;
        duiMode = false;
        duiController = false;
        duiPreview = false;
        duiPropMode = false;
        captureOnly = false;
        duiSession = null;
        sessionNonce = null;
        allowCancelFlag = true;
        Math.random = nativeRandom;

        const stage = $('stage');
        stage.classList.remove('dui-mode');
        stage.style.width = '';
        stage.style.height = '';
        stage.style.maxWidth = '';
        stage.style.maxHeight = '';
        stage.style.borderRadius = '';

        $('root').classList.add('hidden');
        $('flash').className = 'hidden';
        $('board').innerHTML = '';
    }

    function end(success) {
        if (ended) return;

        const flash = $('flash');
        flash.className = success ? 'win' : 'lose';
        $('flash-text').textContent = success ? 'Success' : 'Failed';

        if (duiPreview) {
            ended = true;
            return;
        }

        ended = true;
        cleanup();
        if (typeof SFX !== 'undefined') SFX.play(success ? 'success' : 'fail');

        if (duiController && duiSession) {
            post('duiGameEnded', { 
                success: success, 
                nonce: sessionNonce 
            });
        }

        const sendFinalResult = () => {
            $('root').classList.add('hidden');
            flash.className = 'hidden';
            $('board').innerHTML = '';
            post('result', { success: success, nonce: sessionNonce });
            sessionNonce = null;
        };

        if (duiController) {
            sendFinalResult();
        } else {
            setTimeout(sendFinalResult, 850);
        }
    }

    document.addEventListener('keydown', (e) => {
        if (captureOnly && e.key === 'Escape') {
            e.preventDefault();
            e.stopPropagation();
            if (!allowCancelFlag) return;
            post('closed', { nonce: sessionNonce });
            cleanup();
            return;
        }
        if (ended || !current) return;
        if (e.key === 'Escape') {
            const allow = current.__allowCancel !== false;
            if (allow) end(false);
        }
    });

    // SendDuiMessage does not always hand the page a parsed object the way
    // SendNUIMessage does; depending on build it can arrive as a raw JSON
    // string. cursor.js already guarded against this, engine.js did not, which
    // would drop the 'open' message and leave the DUI blank.
    function readMessage(data) {
        if (typeof data === 'string') {
            try { return JSON.parse(data) || {}; } catch (e) { return {}; }
        }
        return data || {};
    }

    window.addEventListener('message', (ev) => {
        const d = readMessage(ev.data);
        if (d.action === 'open') {
            open(d.payload || {});
        } else if (d.action === 'close') {
            fullReset();
        } else if (d.action === 'duiCaptureOnly') {
            const payload = d.payload || {};
            payload.duiController = true;
            payload.duiPreview = false;
            payload.captureOnly = true;
            open(payload);
        } else if (d.action === 'duiOpen') {
            const payload = d.payload || {};
            payload.duiPreview = !d.controller;
            payload.duiController = !!d.controller;
            payload.duiSession = d.session || null;
            payload.duiSeed = d.seed || 0;
            open(payload);
        } else if (d.action === 'duiInput') {
            dispatchDuiInput(d.event || {});
        } else if (d.action === 'duiClock') {
            const c = d.clock || {};
            if (typeof c.elapsed === 'number') {
                const local = performance.now() - (window.__duiStartTime || performance.now());
                duiClockOffset = c.elapsed - local;
            }
            if (timer && c.timer && typeof c.timer.remaining === 'number') {
                const now = syncedNow();
                const remainingMs = Math.max(0, c.timer.remaining);
                timer.start = now - (timer.duration - remainingMs);
                if (timer.start > now) {
                    timer.start = now - timer.duration;
                }
                if (timer.start < now - timer.duration) {
                    timer.start = now - timer.duration;
                }
            }
        }
    });

    window.addEventListener('beforeunload', () => {
        Math.random = nativeRandom;
    });

    return {
        games,
        register(id, def) { games[id] = def; },
        _internal: { end }
    };
})();
