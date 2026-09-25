// FiveM DUI virtual cursor page-side runtime.
// Plain browser JS build of the library's cursor.ts, adapted for this resource.
//
// IMPORTANT CHANGE FROM THE ORIGINAL:
//
// The original armed itself only when it could read `?dui=1` out of
// window.location.search. That made the entire cursor and keyboard bridge
// depend on CEF parsing a query string off a `nui://` URL. When that read
// comes back empty the failure is silent and confusing: the minigame still
// renders (engine.js listens for messages unconditionally), but no cursor
// element is ever created and no key handler is ever installed. That looks
// exactly like "the UI shows but my mouse and keyboard do nothing".
//
// Lua now also sends an explicit { action: 'duiInit' } message, and the page
// arms itself on either signal. The query string is kept as a fallback.
(function () {
    const handlers = [];
    const HOT = "button, a, input, select, textarea, [data-hot]";
    const FOCUSABLE = "input, textarea, select, [contenteditable=''], [contenteditable='true']";

    let armed = false;
    let cursorEl = null;

    // last position pushed by Lua, 0..1. kept so click-to-focus knows where
    // the virtual cursor actually is: the DOM's own mouse coordinates are not
    // reliable in an offscreen browser.
    let cx = 0.5;
    let cy = 0.5;

    function isHot(t) {
        return t instanceof Element && !!t.closest(HOT);
    }

    function parse(data) {
        if (typeof data !== "string") return data || null;
        try { return JSON.parse(data); } catch (_) { return null; }
    }

    function queryFlag() {
        try { return new URLSearchParams(window.location.search).get("dui") === "1"; }
        catch (_) { return false; }
    }

    function isDuiDocument() {
        return armed || queryFlag();
    }

    function onMessage(fn) {
        handlers.push(fn);
        return function () {
            const i = handlers.indexOf(fn);
            if (i !== -1) handlers.splice(i, 1);
        };
    }

    function elementAtCursor() {
        const x = Math.max(0, Math.min(1, cx)) * window.innerWidth;
        const y = Math.max(0, Math.min(1, cy)) * window.innerHeight;
        return document.elementFromPoint(x, y);
    }

    // An offscreen CEF browser has no window focus, so a synthesized mouse
    // press does not reliably move DOM focus into a text field the way a real
    // click does. Without this, typing into an <input> silently does nothing
    // because document.activeElement never leaves <body>.
    function focusAtCursor() {
        const el = elementAtCursor();
        if (!el) return;

        const target = el.closest(FOCUSABLE);

        if (target) {
            try { target.focus({ preventScroll: true }); }
            catch (_) { try { target.focus(); } catch (__) {} }
            return;
        }

        // Clicking away from a field should drop focus, so keys go back to the
        // document-level handlers the minigames install.
        const active = document.activeElement;
        if (active && active !== document.body && active.closest &&
            active.closest(FOCUSABLE)) {
            try { active.blur(); } catch (_) {}
        }
    }

    function buildCursor() {
        if (cursorEl && cursorEl.isConnected) return cursorEl;
        if (!document.body) return null;

        const existing = document.getElementById("cursor");
        if (existing) {
            cursorEl = existing;
            return cursorEl;
        }

        const el = document.createElement("div");
        el.id = "cursor";
        el.style.transform = 'translate3d(' +
            (cx * 100) + 'vw,' +
            (cy * 100) + 'vh,0)';
        document.body.appendChild(el);
        cursorEl = el;

        if (window.DuiVirtualScroll) window.DuiVirtualScroll.setupScroll(el);

        addEventListener("mousedown", function () {
            el.classList.add("down");
            focusAtCursor();
        });

        addEventListener("mouseup", function () {
            el.classList.remove("down");
            if (window.DuiVirtualKeys) window.DuiVirtualKeys.resetCaret();
        });

        addEventListener("mouseover", function (e) {
            el.classList.toggle("hot", isHot(e.target));
        });

        addEventListener("mouseout", function (e) {
            el.classList.toggle("hot", isHot(e.relatedTarget));
        });

        return el;
    }

    // Arms the page: DUI styling on, virtual cursor drawn, keyboard bridge live.
    // Safe to call repeatedly and at any point in the page lifecycle.
    function activate(info) {
        armed = true;

        if (info) {
            if (info.api) window.__duiApi = info.api;
            if (info.session) window.__duiSession = String(info.session);
        }

        if (document.documentElement) {
            document.documentElement.classList.add("dui-document");
        }

        if (!buildCursor()) {
            // body not parsed yet. try again as soon as it is.
            document.addEventListener("DOMContentLoaded", function () {
                buildCursor();
            }, { once: true });
        }
    }

    function setupCursor() {
        if (!isDuiDocument()) return;
        activate(null);
    }

    function renderCursor(el, x, y) {
        if (!el || !Number.isFinite(x) || !Number.isFinite(y)) return;

        // Keep this entirely inside CEF. The browser receives mousemove from
        // SendDuiMouseMove(), so no SendDuiMessage round-trip is needed for
        // the local visual cursor. This removes the message-queue latency.
        const w = document.documentElement.clientWidth || window.innerWidth || 1;
        const h = document.documentElement.clientHeight || window.innerHeight || 1;

        cx = Math.max(0, Math.min(1, x / w));
        cy = Math.max(0, Math.min(1, y / h));

        el.style.transform = `translate3d(${x}px, ${y}px, 0)`;
    }

    function moveCursor(x, y) {
        if (!Number.isFinite(x) || !Number.isFinite(y)) return;
        const el = buildCursor();
        if (!el) return;
        renderCursor(el, x, y);
    }

    // SendDuiMouseMove() from Lua arrives here as a normal CEF mouse event.
    // Follow it directly instead of waiting for a Lua SendDuiMessage packet.
    // This is the key difference for a busy/React-heavy minigame: the visual
    // cursor is now on the same event path as hover, drag and click.
    addEventListener("mousemove", function (event) {
        if (!armed) return;
        const el = buildCursor();
        if (!el) return;
        renderCursor(el, event.clientX, event.clientY);
    }, { passive: true });

    // The listener is installed unconditionally and at script load. It has to
    // be, or a duiInit arriving before the page armed itself would be dropped.
    addEventListener("message", function (event) {
        const msg = parse(event.data);
        if (!msg || typeof msg !== "object") return;

        if (msg.action === "duiInit") {
            activate(msg);
            return;
        }

        if (msg.action === "cursorMove") {
            if (!armed) activate(null);
            moveCursor(Number(msg.x), Number(msg.y));
            return;
        }

        if (msg.action === "key") {
            if (window.DuiVirtualKeys) window.DuiVirtualKeys.handleKey(msg);
            return;
        }

        if (msg.action === "wheel") {
            if (window.DuiVirtualScroll) window.DuiVirtualScroll.handleWheel(Number(msg.dy) || 0);
            return;
        }

        handlers.slice().forEach(function (fn) {
            try { fn(msg); } catch (_) {}
        });
    });

    window.DuiVirtualCursor = {
        onMessage,
        setupCursor,
        activate,
        isDui: isDuiDocument
    };

    // The normal fullscreen NUI keeps its normal OS cursor. Only DUI pages draw
    // the virtual cursor into their own texture.
    if (queryFlag()) {
        if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", setupCursor, { once: true });
        } else {
            setupCursor();
        }
    }
})();
