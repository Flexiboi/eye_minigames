// FiveM DUI virtual-cursor keyboard bridge.
// Plain browser JS version of the library's keys.ts.
(function () {
    const carets = new WeakMap();

    function caretOf(el) {
        return Math.min(carets.get(el) == null ? el.value.length : carets.get(el), el.value.length);
    }

    function setCaret(el, at) {
        carets.set(el, at);
        try { el.setSelectionRange(at, at); } catch (_) {}
    }

    function resetCaret() {
        const el = document.activeElement;
        if (el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement) {
            setCaret(el, el.value.length);
        }
    }

    function setNativeValue(el, value) {
        const proto = el instanceof HTMLTextAreaElement ? HTMLTextAreaElement : HTMLInputElement;
        const setter = Object.getOwnPropertyDescriptor(proto.prototype, "value");
        if (setter && setter.set) setter.set.call(el, value);
        else el.value = value;
        el.dispatchEvent(new Event("input", { bubbles: true }));
    }

    function apply(el, value, at) {
        setNativeValue(el, value);
        setCaret(el, at);
    }

    function edit(el, k) {
        const v = el.value;
        const at = caretOf(el);

        switch (k.key) {
            case "Backspace":
                if (at > 0) apply(el, v.slice(0, at - 1) + v.slice(at), at - 1);
                return;
            case "Delete":
                if (at < v.length) apply(el, v.slice(0, at) + v.slice(at + 1), at);
                return;
            case "ArrowLeft":
                setCaret(el, Math.max(0, at - 1));
                return;
            case "ArrowRight":
                setCaret(el, Math.min(v.length, at + 1));
                return;
        }

        if (k.key.length !== 1) return;
        apply(el, v.slice(0, at) + k.key + v.slice(at), at + 1);
    }

    function handleKey(k) {
        // Be defensive about keyboard data coming from different FiveM
        // builds. If Shift is explicitly held, preserve uppercase letters
        // even if the upstream key value was reported in lowercase.
        const key = (k.shift && typeof k.key === "string" &&
            k.key.length === 1 && /^[a-z]$/.test(k.key))
            ? k.key.toUpperCase()
            : k.key;

        const eventData = Object.assign({}, k, { key });
        const el = document.activeElement;
        (el || window).dispatchEvent(new KeyboardEvent("keydown", {
            key,
            code: k.code,
            shiftKey: !!k.shift,
            bubbles: true,
            cancelable: true
        }));

        if (el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement) {
            edit(el, eventData);
        }
    }

    window.DuiVirtualKeys = {
        handleKey,
        resetCaret
    };
})();
