// Arms the DUI runtime as early as possible.
//
// This is only the fallback path, for when the ?dui=1 query parameter is
// readable. The authoritative signal is the { action: 'duiInit' } message Lua
// sends once the browser has painted, which cursor.js handles on its own.
// Relying on the query string alone was fragile: if CEF hands back an empty
// location.search for a nui:// URL, the page silently never armed and the
// cursor and keyboard bridge were both dead with no error anywhere.
window.addEventListener('load', () => {
    try {
        const dui = new URLSearchParams(window.location.search).get('dui') === '1';
        if (dui && window.DuiVirtualCursor) {
            window.DuiVirtualCursor.activate(null);
        }
    } catch (_) {}
});
