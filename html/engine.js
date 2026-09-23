(function () {
    const STEP = 1000 / 60;
    const MAX_STEPS = 4;
    const rafNative = window.requestAnimationFrame.bind(window);
    let pending = new Map();
    let nextId = 1, running = false, lastT = 0, acc = 0;

    function pump(ts) {
        if (!lastT) lastT = ts;
        let elapsed = ts - lastT;
        lastT = ts;
        if (elapsed > 250) elapsed = 250;
        acc += elapsed;

        let steps = 0;
        while (acc >= STEP && steps < MAX_STEPS) { acc -= STEP; steps++; }
        if (steps === MAX_STEPS) acc = 0;

        for (let s = 0; s < steps && pending.size; s++) {
            const due = pending;
            pending = new Map();
            due.forEach((cb) => { try { cb(ts); } catch (e) {} });
        }

        if (pending.size) rafNative(pump);
        else { running = false; lastT = 0; acc = 0; }
    }

    window.requestAnimationFrame = function (cb) {
        const id = nextId++;
        pending.set(id, cb);
        if (!running) { running = true; lastT = 0; acc = 0; rafNative(pump); }
        return id;
    };
    window.cancelAnimationFrame = function (id) { pending.delete(id); };
})();

const MG = (function () {
    const games = {};
    let current = null;
    let raf = null;
    let timer = null;
    let ended = false;
    let sessionNonce = null;   // per-game token from Lua; required to report a result

    const $ = (id) => document.getElementById(id);

    /* ---- Lua bridge ---- */
    function post(name, body) {
        const url = `https://${resName()}/${name}`;
        fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(body || {})
        }).catch(() => {});
    }
    function resName() {
        return (typeof GetParentResourceName === 'function')
            ? GetParentResourceName() : 'eye_minigames';
    }

    /* ---- Timer ---- */
    function startTimer(seconds, onExpire) {
        timer = { duration: seconds * 1000, start: performance.now(), onExpire };
        tick();
    }
    function tick() {
        if (!timer) return;
        const elapsed = performance.now() - timer.start;
        const remain = Math.max(0, timer.duration - elapsed);
        const pct = remain / timer.duration;
        $('timer-fill').style.width = (pct * 100) + '%';
        $('timer-text').textContent = (remain / 1000).toFixed(1);
        $('timer-fill').style.background = pct < 0.25
            ? 'linear-gradient(90deg, var(--danger), #fff)'
            : 'linear-gradient(90deg, var(--accent), #fff)';
        if (remain <= 0) {
            const fn = timer.onExpire; timer = null;
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

    /* ---- Round dots ---- */
    function setDots(total, states) {
        const c = $('dots'); c.innerHTML = '';
        for (let i = 0; i < total; i++) {
            const d = document.createElement('div');
            d.className = 'dot' + (states && states[i] ? ' ' + states[i] : '');
            c.appendChild(d);
        }
    }

    /* ---- Lifecycle ---- */
    function open(payload) {
        ended = false;
        sessionNonce = payload.nonce || null;
        if (typeof SFX !== 'undefined') {
            if (payload.sound === false) SFX.setEnabled(false);
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
        $('hud-timer').style.visibility = timer ? 'visible' : 'visible';
    }

    function cleanup() {
        stopTimer();
        if (current && typeof current.destroy === 'function') {
            try { current.destroy(); } catch (e) {}
        }
        current = null;
        document.onkeydown = null;
    }

    function end(success) {
        if (ended) return;
        ended = true;
        cleanup();
        if (typeof SFX !== 'undefined') SFX.play(success ? 'success' : 'fail');

        const flash = $('flash');
        flash.className = success ? 'win' : 'lose';
        $('flash-text').textContent = success ? 'Success' : 'Failed';

        setTimeout(() => {
            $('root').classList.add('hidden');
            flash.className = 'hidden';
            $('board').innerHTML = '';
            post('result', { success: success, nonce: sessionNonce });
            sessionNonce = null;
        }, 850);
    }

    /* ---- Global cancel key ---- */
    document.addEventListener('keydown', (e) => {
        if (ended || !current) return;
        if (e.key === 'Escape') {
            const allow = current.__allowCancel !== false;
            if (allow) end(false);
        }
    });

    /* ---- Message in from Lua ---- */
    window.addEventListener('message', (ev) => {
        const d = ev.data || {};
        if (d.action === 'open') open(d.payload || {});
    });

    return {
        games,
        register(id, def) { games[id] = def; },
        _internal: { end }
    };
})();
