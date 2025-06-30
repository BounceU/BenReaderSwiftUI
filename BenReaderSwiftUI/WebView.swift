//
//  WebView.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/14/25.
//


import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    
    
    // 1
    let url: URL
    var colors: [String]
    var fontSize: CGFloat
    var spacing: CGFloat
    var sides: CGFloat
    
    var webCoord: WebCoordinator;
    //var wv: WKWebView

    
    // 2
    func makeUIView(context: Context) -> WKWebView {
        webCoord.webview = WKWebView()
        return webCoord.webview!
    }
    
    // 3
    func updateUIView(_ webView: WKWebView, context: Context) {

        let request = URLRequest(url: url)
    
        webView.load(request)
        
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.bouncesHorizontally = false
        
        // Disable zooming
        webView.configuration.userContentController.addUserScript(self.getZoomDisableScript())
        
        webView.configuration.userContentController.addUserScript(self.scriptForChangingColor())
        
        // Fix css
        let userScript: WKUserScript = WKUserScript(
                 source:
                    self.getCSS(),
                 injectionTime: .atDocumentEnd,
                 forMainFrameOnly: true
             )
        
             webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.addUserScript(self.getHighlightingScript())
        webView.configuration.userContentController.addUserScript(self.resetBodyScript())
        webCoord.webview = webView
        
        
    }
    
    private func resetBodyScript() -> WKUserScript {
        let source: String = """
          const originalBody = document.body.getHTML();

        function resetBody() {
            document.body.setHTMLUnsafe(originalBody); const style = document.createElement('style');
        }
        """
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
    
    private func getHighlightingScript() -> WKUserScript {
        let source: String = """
        
        function containsLettersOrNumbers(str) {
          const regex = /[a-zA-Z0-9]+/; // Matches any letter (uppercase or lowercase) or any digit
          return regex.test(str);
        }
        
        function highlightNthSentence(n) {
            n += 1
            let sentenceCount = 0;
            const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT, null, false);
            let node;
            let foundSentence = false;

            const highlightSpan = document.createElement('span');
            highlightSpan.classList.add('highlight');

            while ((node = walker.nextNode())) {
                if (node.nodeType === Node.TEXT_NODE) {
                    const text = node.nodeValue;
                    if (text.trim() == "") continue;
                    if(!containsLettersOrNumbers(text.trim()) && !text.trim().includes("...") && !text.trim().includes("…")) continue;
                    let lastIndex = 0;
                    let match;
                    const sentenceRegex = /(?<!\\.)([.?])(?![\\.])['"”]?\\s*|(?=<[^>]*?>)/g; // Matches .?! followed by optional space, or the start of any HTML tag

                    while ((match = sentenceRegex.exec(text)) !== null) {
                        let sentenceEnd = match.index + match[0].length;
                        
                        
                        // If the match is a tag, the sentence ends *before* the tag
                        if (match[0].startsWith('<')) {
                            sentenceEnd = match.index;
                        }

                        if (sentenceEnd > lastIndex) {
        
                            let newText = text.substring(lastIndex, sentenceEnd);
                                
                            if (newText.trim() == "") {
                                lastIndex = sentenceEnd;
                                continue;
                            }
                            if(!containsLettersOrNumbers(newText.trim()) && !newText.trim().includes("...") && !newText.trim().includes("…")) {
                                lastIndex = sentenceEnd;
                                continue;
                            }

        
                            sentenceCount++;
                            if (sentenceCount === n) {
                                const range = document.createRange();
                                range.setStart(node, lastIndex);
                                range.setEnd(node, sentenceEnd);

                                // Handle partial text nodes: if the sentence spans the end of a text node
                                // and the beginning of another, it gets tricky. For simplicity, we assume
                                // sentences largely reside within single text nodes or are broken by elements.
                                // A more robust solution for cross-node sentences would be much more complex.

                                try {
                                    range.surroundContents(highlightSpan);
                                    foundSentence = true;
                                    return; // Found and highlighted, so exit
                                } catch (e) {
                                    // This error often occurs if the range contains partial nodes or crosses
                                    // element boundaries in a complex way that surroundContents can't handle.
                                    // In such cases, we might need to manually insert spans.
                                    console.warn("Could not surround contents directly, attempting manual highlight:", e);
                                    // Fallback for complex ranges (less ideal, as it modifies the DOM more aggressively)
                                    const sentenceText = text.substring(lastIndex, sentenceEnd);
                                    const highlightedTextNode = document.createTextNode(sentenceText);
                                    const replacementSpan = document.createElement('span');
                                    replacementSpan.classList.add('highlight');
                                    replacementSpan.appendChild(highlightedTextNode);

                                    // Replace the original text portion with the new span
                                    const afterText = document.createTextNode(text.substring(sentenceEnd));
                                    node.nodeValue = text.substring(0, lastIndex); // Trim original node
                                    node.parentNode.insertBefore(replacementSpan, node.nextSibling);
                                    node.parentNode.insertBefore(afterText, replacementSpan.nextSibling);

                                    foundSentence = true;
                                    return;
                                }
                            }
                        }
                        lastIndex = sentenceEnd;
                    }

                    // Handle remaining text in the node if it doesn't end with a punctuation or tag
                    if (lastIndex < text.length) {
                        sentenceCount++;
                        if (sentenceCount === n) {
                            const range = document.createRange();
                            range.setStart(node, lastIndex);
                            range.setEnd(node, text.length);
                            try {
                                range.surroundContents(highlightSpan);
                                foundSentence = true;
                                return;
                            } catch (e) {
                                console.warn("Could not surround remaining contents directly, attempting manual highlight:", e);
                                const sentenceText = text.substring(lastIndex);
                                const highlightedTextNode = document.createTextNode(sentenceText);
                                const replacementSpan = document.createElement('span');
                                replacementSpan.classList.add('highlight');
                                replacementSpan.appendChild(highlightedTextNode);

                                // Replace the original text portion with the new span
                                node.nodeValue = text.substring(0, lastIndex); // Trim original node
                                node.parentNode.insertBefore(replacementSpan, node.nextSibling);
                                foundSentence = true;
                                return;
                            }
                        }
                    }

                } else if (node.nodeType === Node.ELEMENT_NODE) {
                    // If the current node is an element and it has children,
                    // the walker will delve into its children.
                    // If it's an empty tag (e.g., <br>), it won't have text content,
                    // but if a sentence ends just before it, that's handled by the text node logic.
                    // The crucial part is that a *closing* tag signals a sentence end.
                    // However, TreeWalker processes nodes in document order.
                    // We need to detect a sentence ending *before* the current element.

                    // If the *previous* sibling was a text node and it didn't end with punctuation,
                    // or if an element's *closing* tag should signal a sentence end for its content.
                    // This is implicitly handled by the regex detecting `(?=<[^/]*?>)` at the *end* of a text node.
                    // If the element is a block-level element, its mere presence (and closing) can imply a sentence break.
                    // For the given example `<em>`, the 'is' ends before `</em>`.
                    // The current logic handles this by looking for `(?=<[^/]*?>)` within the text node *before* the tag.

                    // To handle the end of a tag signaling a sentence explicitly for the current element:
                    // If this element has no text content (e.g., <img>, <br>), or if its content
                    // was already processed, and we are now at its *closing* implied position.
                    // This is a complex aspect with TreeWalker, as it gives you the element node itself.
                    // We'll rely on the text node processing to catch `<em>` closures by detecting the tag start.
                }
            }

            if (!foundSentence) {
                console.log(`Sentence ${n} not found or not enough sentences.`);
            }
        }



        function scrollToClass(className) {
            // Find the first element with the specified class
            const targetElement = document.querySelector(`.${className}`);

            // If the element exists, scroll it into view
            if (targetElement) {
                targetElement.scrollIntoView({
                    behavior: 'smooth', // Optional: for smooth scrolling animation
                    block: 'nearest'      // Optional: align the top of the element with the top of the viewport
                });
            } else {
                console.warn(`Element with class '${className}' not found.`);
            }
        }

        """
        
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
    
    private func getZoomDisableScript() -> WKUserScript {
        let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" + "head.appendChild(meta);"
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
    
    private func scriptForChangingColor() -> WKUserScript {
        let source: String = """
        function refreshCSS(color1, color2, sides, spacing, fontSize) {

            document.querySelectorAll('style').forEach(e => e.remove());
            document.querySelectorAll('link[rel="stylesheet"]').forEach(e => e.remove());
            document.querySelectorAll('*').forEach(e => e.removeAttribute('style'));
            const styleEle = document.createElement('style');
            styleEle.type = "text/css"
            styleEle.innerHTML = `
                                     :root {
                                     --bg: ${color1};
                                     --fg: ${color2};
                                     --sides: ${sides}%;
                                     --spacing: ${spacing}%;
                                     --fs: ${fontSize}px;

                                     }

                                     .highlight {
                                       background-color: darkgreen;
                                       border-radius: 0.2em;
                                     }

                                     /* This assumes geometric header shrinkage */
                                     /* Also, it tries to make h2 be 1em */
                                     html,
                                     body,
                                     div,

                                     applet,
                                     object,
                                     iframe,
                                     h1,
                                     h2,
                                     h3,
                                     h4,
                                     h5,
                                     h6,
                                     p,
                                     blockquote,
                                     pre,
                                     a,
                                     abbr,
                                     acronym,
                                     address,
                                     big,
                                     cite,
                                     code,
                                     del,
                                     dfn,
                                     em,
                                     img,
                                     ins,
                                     kbd,
                                     q,
                                     s,
                                     samp,
                                     small,
                                     strike,
                                     strong,
                                     sub,
                                     sup,
                                     tt,
                                     var,
                                     b,
                                     u,
                                     i,
                                     center,
                                     dl,
                                     dt,
                                     dd,
                                     fieldset,
                                     form,
                                     label,
                                     legend,
                                     table,
                                     caption,
                                     tbody,
                                     tfoot,
                                     thead,
                                     tr,
                                     th,
                                     td,
                                     article,
                                     aside,
                                     canvas,
                                     details,
                                     embed,
                                     figure,
                                     figcaption,
                                     footer,
                                     header,
                                     hgroup,
                                     menu,
                                     nav,
                                     output,
                                     ruby,
                                     section,
                                     summary,
                                     time,
                                     mark,
                                     audio,
                                     video {
                                       margin-right: 0;
                                       padding: 0;
                                       border: 0;
                                       font-size: var(--fs);
                                       vertical-align: baseline;
                                       margin: var(--sides);
                                       margin-bottom: var(--spacing);
                                       line-height: 1.5em;
                                       background-color: var(--bg);
                                       color: var(--fg);
                                       scroll-padding-top: 20%;
                                       scroll-padding-bottom: 20%;
                                     }

                                     /* optimal sizing see http://demosthenes.info/blog/578/Crafting-Optimal-Type-Sizes-For-Web-Pages */
                                     /* kobo and nook dislike this */
                                     /* */
                                     /*html */
                                     /*  font-size: 62.5% */
                                     /*body */
                                     /*  font-size: 1.6rem */
                                     /*  line-height: 2.56rem */
                                     /*  text-rendering: optimizeLegibility */
                                     table {
                                       border-collapse: collapse;
                                       border-spacing: 0;
                                     }

                                     /* end reset */
                                     @page {
                                       margin-top: 30px;
                                       margin-bottom: 20px;
                                     }

                                     div.cover {
                                       text-align: center;
                                       page-break-after: always;
                                       padding: 0px;
                                       margin: 0px;
                                     }

                                     div.cover img {
                                       height: 100%;
                                       max-width: 100%;
                                       padding: 10px;
                                       margin: 0px;
                                       background-color: #cccccc;
                                     }

                                     .half {
                                       max-width: 50%;
                                     }

                                     .tenth {
                                       max-width: 10%;
                                       width: 10%;
                                     }

                                     .cover-img {
                                       height: 100%;
                                       max-width: 100%;
                                       padding: 0px;
                                       margin: 0px;
                                     }

                                     /* font plan- serif text, sans headers */
                                     h1,
                                     h2,
                                     h3,
                                     h4,
                                     h5,
                                     h6 {
                                       hyphens: none !important;
                                       -moz-hyphens: none !important;
                                       -webkit-hyphens: none !important;
                                       adobe-hyphenate: none !important;
                                       page-break-after: avoid;
                                       page-break-inside: avoid;
                                       text-indent: 0px;
                                       text-align: left;
                                       font-family: "Bookerly", Helvetica, Arial, sans-serif;
                                     }

                                     h1 {
                                       font-size: 1.6em;
                                       margin-bottom: 3.2em;
                                       padding-top: 3em;
                                     }

                                     .title h1 {
                                       margin-bottom: 0px;
                                       margin-top: 3.2em;
                                     }


                                     h2 {
                                       font-size: 1em;
                                       margin-top: 0.5em;
                                       margin-bottom: 0.5em;
                                     }

                                     h3 {
                                       font-size: 0.625em;
                                     }

                                     h4 {
                                       font-size: 0.391em;
                                     }

                                     h5 {
                                       font-size: 0.244em;
                                     }

                                     h6 {
                                       font-size: 0.153em;
                                     }

                                     /* Do not indent first paragraph. Mobi will need class='first-para' */
                                     h1+p,
                                     h2+p,
                                     h3+p,
                                     h4+p,
                                     h5+p,
                                     h6+p {
                                       text-indent: 0;
                                     }

                                     @import url('https://fonts.cdnfonts.com/css/bookerly');

                                     p {
                                       /* paperwhite defaults to sans */
                                       font-family: "Bookerly", "Palatino", "Times New Roman", Caecilia, serif;
                                       -webkit-hyphens: auto;
                                       -moz-hyphens: auto;
                                       hyphens: auto;
                                       hyphenate-after: 3;
                                       hyphenate-before: 3;
                                       hyphenate-lines: 2;
                                       -webkit-hyphenate-after: 3;
                                       -webkit-hyphenate-before: 3;
                                       -webkit-hyphenate-lines: 2;
                                       text-align: justify;
                                       text-indent: 1em;
                                     }

                                     p.first-para,
                                     p.first-para-chapter,
                                     p.note-p-first {
                                       text-indent: 0;
                                     }

                                     p.first-para-chapter::first-line {
                                       /* handle run-in */
                                       font-variant: small-caps;
                                     }

                                     p.no-indent {
                                       text-indent: 0;
                                     }

                                     .no-hyphens {
                                       hyphens: none !important;
                                       -moz-hyphens: none !important;
                                       -webkit-hyphens: none !important;
                                       adobe-hyphenate: none !important;
                                     }

                                     .rtl {
                                       direction: rtl;
                                       float: right;
                                     }

                                     .drop {
                                       overflow: hidden;
                                       line-height: 89%;
                                       height: 0.8em;
                                       font-size: 281%;
                                       margin-right: 0.075em;
                                       float: left;
                                     }

                                     .dropcap {
                                       line-height: 100%;
                                       font-size: 341%;
                                       margin-right: 0.075em;
                                       margin-top: -0.22em;
                                       float: left;
                                       height: 0.8em;
                                     }

                                     /* lists */
                                     ul,
                                     ol,
                                     dl {
                                       margin: 1em 0 1em 0;
                                       text-align: left;
                                     }

                                     li {
                                       font-family: "Palatino", "Times New Roman", Caecilia, serif;
                                       line-height: 1.5em;
                                       orphans: 2;
                                       widows: 2;
                                       text-align: justify;
                                       text-indent: 0;
                                       margin: 0;
                                     }

                                     li p {
                                       /* Fix paragraph indenting inside of lists */
                                       text-indent: 0em;
                                     }

                                     dt {
                                       font-weight: bold;
                                       font-family: Helvetica, Arial, sans-serif;
                                     }

                                     dd {
                                       line-height: 1.5em;
                                       font-family: "Palatino", "Times New Roman", Caecilia, serif;
                                     }

                                     dd p {
                                       /* Fix paragraph indenting inside of definition lists */
                                       text-indent: 0em;
                                     }

                                     blockquote {
                                       margin-left: 1em;
                                       margin-right: 1em;
                                       line-height: 1.5em;
                                       font-style: italic;
                                     }

                                     blockquote p.first-para,
                                     blockquote p {
                                       text-indent: 0;
                                     }

                                     pre,
                                     tt,
                                     code,
                                     samp,
                                     kbd {
                                       font-family: "Courier New", Courier, monospace;
                                       word-wrap: break-word;
                                     }

                                     pre {
                                       font-size: 0.8em;
                                       line-height: 1.2em;
                                       margin-left: 1em;
                                       /* margin-top: 1em */
                                       margin-bottom: 1em;
                                       white-space: pre-wrap;
                                       display: block;
                                     }

                                     img {
                                       border-radius: 0.3em;
                                       -webkit-border-radius: 0.3em;
                                       -webkit-box-shadow: rgba(0, 0, 0, 0.15) 0 1px 4px;
                                       box-shadow: rgba(0, 0, 0, 0.15) 0 1px 4px;
                                       box-sizing: border-box;
                                       border: white 0.5em solid;
                                       /* Don't go too big on images, let reader zoom in if they care to */
                                       max-width: 80%;
                                       max-height: 80%;
                                     }

                                     img.pwhack {
                                       /* Paperwhite hack */
                                       width: 100%;
                                     }

                                     .group {
                                       page-break-inside: avoid;
                                     }

                                     .caption {
                                       text-align: center;
                                       font-size: 0.8em;
                                       font-weight: bold;
                                     }

                                     p img {
                                       border-radius: 0;
                                       border: none;
                                     }

                                     figure {
                                       /* These first 3 should center figures */
                                       padding: 1em;
                                       background-color: #cccccc;
                                       border: 1px solid black;
                                       text-align: center;
                                     }

                                     figure figcaption {
                                       text-align: center;
                                       font-size: 0.8em;
                                       font-weight: bold;
                                     }

                                     div.div-literal-block-admonition {
                                       margin-left: 1em;
                                       background-color: #cccccc;
                                     }

                                     div.note,
                                     div.tip,
                                     div.hint {
                                       margin: 1em 0 1em 0 !important;
                                       background-color: #cccccc;
                                       padding: 1em !important;
                                       /* kindle is finnicky with borders, bottoms dissappear, width is ignored */
                                       border-top: 0px solid #cccccc;
                                       border-bottom: 0px dashed #cccccc;
                                       page-break-inside: avoid;
                                     }

                                     /* sidebar */
                                     p.note-title,
                                     .admonition-title {
                                       margin-top: 0;
                                       /*mobi doesn't like div margins */
                                       font-variant: small-caps;
                                       font-size: 0.9em;
                                       text-align: center;
                                       font-weight: bold;
                                       font-style: normal;
                                       -webkit-hyphens: none;
                                       -moz-hyphens: none;
                                       hyphens: none;
                                       /* margin:0 1em 0 1em */
                                     }

                                     div.note p,
                                     .note-p {
                                       text-indent: 1em;
                                       margin-left: 0;
                                       margin-right: 0;
                                     }

                                     /*  font-style: italic */
                                     /* Since Kindle doesn't like multiple classes have to have combinations */
                                     div.note p.note-p-first {
                                       text-indent: 0;
                                       margin-left: 0;
                                       margin-right: 0;
                                     }

                                     /* Tables */
                                     table {
                                       /*width: 100% */
                                       page-break-inside: avoid;
                                       border: 1px;
                                       /* centers on kf8 */
                                       margin: 1em auto;
                                       border-collapse: collapse;
                                       border-spacing: 0;
                                     }

                                     th {
                                       font-variant: small-caps;
                                       padding: 5px !important;
                                       vertical-align: baseline;
                                       border-bottom: 1px solid black;
                                     }

                                     td {
                                       font-family: "Palatino", "Times New Roman", Caecilia, serif;
                                       font-size: small;
                                       hyphens: none;
                                       -moz-hyphens: none;
                                       -webkit-hyphens: none;
                                       padding: 5px !important;
                                       page-break-inside: avoid;
                                       text-align: left;
                                       text-indent: 0;
                                       vertical-align: baseline;
                                     }

                                     td:nth-last-child {
                                       border-bottom: 1px solid black;
                                     }

                                     .zebra {
                                       /* shade background by groups of three */
                                     }

                                     .zebra tr th {
                                       background-color: white;
                                     }

                                     .zebra tr:nth-child(6n-1),
                                     .zebra tr:nth-child(6n+0),
                                     .zebra tr:nth-child(6n+1) {
                                       background-color: #cccccc;
                                     }

                                     sup {
                                       vertical-align: super;
                                       font-size: 0.5em;
                                       line-height: 0.5em;
                                     }

                                     sub {
                                       vertical-align: sub;
                                       font-size: 0.5em;
                                       line-height: 0.5em;
                                     }

                                     table.footnote {
                                       margin: 0.5em 0em 0em 0em;
                                     }

                                     .footnote {
                                       font-size: 0.8em;
                                     }

                                     .footnote-link {
                                       font-size: 0.8em;
                                       vertical-align: super;
                                     }

                                     .tocEntry-1 a {
                                       /* empty */
                                       font-weight: bold;
                                       text-decoration: none;
                                       color: black;
                                     }

                                     .tocEntry-2 a {
                                       margin-left: 1em;
                                       text-indent: 1em;
                                       text-decoration: none;
                                       color: black;
                                     }

                                     .tocEntry-3 a {
                                       text-indent: 2em;
                                       text-decoration: none;
                                       color: black;
                                     }

                                     .tocEntry-4 a {
                                       text-indent: 3em;
                                       text-decoration: none;
                                       color: black;
                                     }

                                     .copyright-top {
                                       margin-top: 6em;
                                     }

                                     .page-break-before {
                                       page-break-before: always;
                                     }

                                     .page-break-after {
                                       page-break-after: always;
                                     }

                                     .center {
                                       text-indent: 0;
                                       text-align: center;
                                       margin-left: auto;
                                       margin-right: auto;
                                       display: block;
                                     }

                                     .right {
                                       text-align: right;
                                     }

                                     .left {
                                       text-align: left;
                                     }

                                     .f-right {
                                       float: right;
                                     }

                                     .f-left {
                                       float: left;
                                     }

                                     /* Samples */
                                     .ingredient {
                                       page-break-inside: avoid;
                                     }

                                     .box-example {
                                       background-color: #8ae234;
                                       margin: 2em;
                                       padding: 1em;
                                       border: 2px dashed #ef2929;
                                     }

                                     .blue {
                                       background-color: blue;
                                     }

                                     .dashed {
                                       border: 2px dashed #ef2929;
                                     }

                                     .padding-only {
                                       padding: 1em;
                                     }

                                     .margin-only {
                                       margin: 2em;
                                     }

                                     .smaller {
                                       font-size: 0.8em;
                                     }

                                     .em1 {
                                       font-size: 0.5em;
                                     }

                                     .em2 {
                                       font-size: 0.75em;
                                     }

                                     .em3 {
                                       font-size: 1em;
                                     }

                                     .em4 {
                                       font-size: 1.5em;
                                     }

                                     .em5 {
                                       font-size: 2em;
                                     }

                                     .per1 {
                                       font-size: 50%;
                                     }

                                     .per2 {
                                       font-size: 75%;
                                     }

                                     .per3 {
                                       font-size: 100%;
                                     }

                                     .per4 {
                                       font-size: 150%;
                                     }

                                     .per5 {
                                       font-size: 200%;
                                     }

                                     .mousepoem p {
                                       line-height: 0;
                                       margin-left: 1em;
                                     }

                                     .per100 {
                                       font-size: 100%;
                                       line-height: 0.9em;
                                     }

                                     .per90 {
                                       font-size: 90%;
                                       line-height: 0.9em;
                                     }

                                     .per80 {
                                       font-size: 80%;
                                       line-height: 0.9em;
                                     }

                                     .per70 {
                                       font-size: 70%;
                                       line-height: 0.9em;
                                     }

                                     .per60 {
                                       font-size: 60%;
                                       line-height: 0.9em;
                                     }

                                     .per50 {
                                       font-size: 50%;
                                       line-height: 1.05em;
                                     }

                                     .per40 {
                                       font-size: 40%;
                                       line-height: 0.9em;
                                     }

                                     .size1 {
                                       font-size: x-small;
                                     }

                                     .size2 {
                                       font-size: small;
                                     }

                                     .size3 {
                                       /* default */
                                       font-size: medium;
                                     }

                                     .size4 {
                                       font-size: large;
                                     }

                                     .size5 {
                                       font-size: x-large;
                                     }

                                     /* Poetic margins */
                                     .stanza {
                                       margin-top: 1em;
                                       font-family: serif;
                                       padding-left: 1em;
                                     }

                                     .stanza p {
                                       padding-left: 1em;
                                     }

                                     .poetry {
                                       margin: 1em;
                                     }

                                     /*line number */
                                     .ln {
                                       float: left;
                                       color: #999999;
                                       font-size: 0.8em;
                                       font-style: italic;
                                     }

                                     .pos1 {
                                       margin-left: 1em;
                                       text-indent: -1em;
                                     }

                                     .pos2 {
                                       margin-left: 2em;
                                       text-indent: -1em;
                                     }

                                     .pos3 {
                                       margin-left: 3em;
                                       text-indent: -1em;
                                     }

                                     .pos4 {
                                       margin-left: 4em;
                                       text-indent: -1em;
                                     }

                                     @font-face {
                                       font-family: Inconsolata Mono;
                                       font-style: normal;
                                       font-weight: normal;
                                       src: url("Inconsolata.otf");
                                     }`;
            document.getElementsByTagName('head')[0].appendChild(styleEle);
        }
        """
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
    
    private func getCSS() -> String {
        
        return  """
     refreshCSS("\(colors.first!)", "\(colors.last!)", \(sides), \(spacing), \(fontSize));
     """;
        
        
    }

}
