// FiveM DUI virtual-cursor scrolling/drag bridge.
// Plain browser JS version of the library's scroll.ts.
(function () {
    function scrollableAt(x, y) {
        let el = document.elementFromPoint(x, y);
        while (el && el !== document.documentElement) {
            const overflow = getComputedStyle(el).overflowY;
            if (/(auto|scroll)/.test(overflow) && el.scrollHeight > el.clientHeight) return el;
            el = el.parentElement;
        }
        return null;
    }

    let px = 0;
    let py = 0;
    let dragging = null;
    let dragFrom = 0;

    function setupScroll(cursor) {
        addEventListener("mousemove", function (e) {
            px = e.clientX;
            py = e.clientY;
            if (!dragging) return;
            dragging.scrollTop -= e.clientY - dragFrom;
            dragFrom = e.clientY;
        });

        addEventListener("mousedown", function (e) {
            dragging = scrollableAt(e.clientX, e.clientY);
            dragFrom = e.clientY;
            if (dragging) cursor.classList.add("grab");
        });

        addEventListener("mouseup", function () {
            dragging = null;
            cursor.classList.remove("grab");
        });
    }

    function handleWheel(dy) {
        const el = scrollableAt(px, py);
        if (el) el.scrollTop += dy;
    }

    window.DuiVirtualScroll = { setupScroll, handleWheel };
})();
