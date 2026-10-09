// Marked 12's synchronous GFM parser is shared by preview and both exporters.
(function () {
    var renderer = new marked.Renderer();
    // Preserve the previous parser's policy for embedded HTML.
    renderer.html = function () { return '<!-- raw HTML omitted -->'; };
    var renderTable = renderer.table;
    renderer.table = function (header, body) {
        return '<div class="table-scroll" role="region" aria-label="表格" tabindex="0">'
            + renderTable.call(this, header, body) + '</div>\n';
    };

    function safeURL(href, image) {
        var normalized;
        try {
            normalized = decodeURIComponent(href)
                .replace(/&#(x[0-9a-f]+|[0-9]+);?/gi, function (_, code) {
                    return String.fromCharCode(code[0].toLowerCase() === 'x'
                        ? parseInt(code.slice(1), 16) : parseInt(code, 10));
                })
                .replace(/&colon;/gi, ':')
                .replace(/&(?:tab|newline);/gi, '')
                .replace(/[\u0000-\u0020\u007f]/g, '')
                .toLowerCase();
        } catch (_) {
            return '';
        }
        if (/^(javascript|vbscript|file):/.test(normalized)) { return ''; }
        if (/^data:/.test(normalized)
            && !(image && /^data:image\/(png|gif|jpeg|webp);/.test(normalized))) { return ''; }
        return href;
    }

    var parser = new marked.Marked({
        gfm: true,
        breaks: false,
        async: false,
        renderer: renderer,
        walkTokens: function (token) {
            if (token.type === 'link' || token.type === 'image') {
                token.href = safeURL(token.href, token.type === 'image');
            }
        }
    });
    globalThis.renderMarkdown = function (source) { return parser.parse(source); };
})();
