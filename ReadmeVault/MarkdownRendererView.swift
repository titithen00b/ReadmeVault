import SwiftUI
import WebKit

struct MarkdownRendererView: NSViewRepresentable {
    let content: String
    let accentColor: Color

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let hex = colorToHex(accentColor)
        let html = generateHTML(markdown: content, accentHex: hex)
        webView.loadHTMLString(html, baseURL: URL(string: "https://github.com/"))
    }

    private func colorToHex(_ color: Color) -> String {
        guard let cgColor = NSColor(color).cgColor.converted(
            to: CGColorSpace(name: CGColorSpace.sRGB)!,
            intent: .defaultIntent,
            options: nil
        ) else { return "#6C63FF" }
        let r = Int((cgColor.components?[0] ?? 0) * 255)
        let g = Int((cgColor.components?[1] ?? 0) * 255)
        let b = Int((cgColor.components?[2] ?? 0) * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    private func generateHTML(markdown: String, accentHex: String) -> String {
        let rendered = parseMarkdown(markdown)
        let isDark = NSApp.effectiveAppearance.name == .darkAqua ||
                     NSApp.effectiveAppearance.name == .vibrantDark

        let bgColor = isDark ? "#1e1e2e" : "#ffffff"
        let textColor = isDark ? "#cdd6f4" : "#2d2d2d"
        let subTextColor = isDark ? "#a6adc8" : "#666666"
        let codeBg = isDark ? "#181825" : "#f4f4f8"
        let borderColor = isDark ? "#313244" : "#e8e8f0"
        let headingColor = isDark ? "#cba6f7" : accentHex
        let blockquoteBg = isDark ? "#181825" : "#f8f8ff"
        let tableHeaderBg = isDark ? "#313244" : "#f0f0f8"

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <style>
          * { box-sizing: border-box; margin: 0; padding: 0; }
          body {
            font-family: -apple-system, 'SF Pro Text', sans-serif;
            font-size: 14px;
            line-height: 1.75;
            color: \(textColor);
            background: \(bgColor);
            padding: 28px 32px 48px;
            max-width: 860px;
          }
          h1 {
            font-size: 28px;
            font-weight: 800;
            color: \(headingColor);
            margin: 0 0 20px;
            padding-bottom: 12px;
            border-bottom: 2px solid \(borderColor);
            letter-spacing: -0.5px;
          }
          h2 {
            font-size: 20px;
            font-weight: 700;
            color: \(headingColor);
            margin: 28px 0 12px;
            padding-bottom: 6px;
            border-bottom: 1px solid \(borderColor);
          }
          h3 {
            font-size: 16px;
            font-weight: 600;
            color: \(headingColor);
            margin: 20px 0 8px;
          }
          h4, h5, h6 {
            font-size: 14px;
            font-weight: 600;
            color: \(subTextColor);
            margin: 16px 0 6px;
          }
          p { margin: 10px 0; }
          a {
            color: \(accentHex);
            text-decoration: none;
            border-bottom: 1px solid \(accentHex)55;
            transition: border-color 0.2s;
          }
          a:hover { border-color: \(accentHex); }
          code {
            font-family: 'SF Mono', 'Menlo', monospace;
            font-size: 12px;
            background: \(codeBg);
            color: \(isDark ? "#f38ba8" : "#d63031");
            padding: 2px 6px;
            border-radius: 4px;
            border: 1px solid \(borderColor);
          }
          pre {
            background: \(codeBg);
            border: 1px solid \(borderColor);
            border-left: 3px solid \(accentHex);
            border-radius: 8px;
            padding: 16px 20px;
            overflow-x: auto;
            margin: 14px 0;
          }
          pre code {
            background: none;
            border: none;
            padding: 0;
            color: \(textColor);
            font-size: 13px;
            line-height: 1.6;
          }
          blockquote {
            background: \(blockquoteBg);
            border-left: 4px solid \(accentHex);
            border-radius: 0 8px 8px 0;
            padding: 12px 16px;
            margin: 14px 0;
            color: \(subTextColor);
          }
          ul, ol {
            padding-left: 24px;
            margin: 10px 0;
          }
          li { margin: 4px 0; }
          li::marker { color: \(accentHex); font-weight: bold; }
          table {
            border-collapse: collapse;
            width: 100%;
            margin: 16px 0;
            border-radius: 8px;
            overflow: hidden;
            border: 1px solid \(borderColor);
          }
          th {
            background: \(tableHeaderBg);
            padding: 10px 14px;
            text-align: left;
            font-weight: 600;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: \(subTextColor);
            border-bottom: 1px solid \(borderColor);
          }
          td {
            padding: 10px 14px;
            border-bottom: 1px solid \(borderColor);
          }
          tr:last-child td { border-bottom: none; }
          tr:nth-child(even) { background: \(isDark ? "#181825" : "#fafafa"); }
          hr {
            border: none;
            border-top: 1px solid \(borderColor);
            margin: 24px 0;
          }
          img { max-width: 100%; border-radius: 8px; }
          strong { font-weight: 700; color: \(isDark ? "#cdd6f4" : "#1a1a2e"); }
          em { font-style: italic; color: \(subTextColor); }
          .badge {
            display: inline-block;
            background: \(accentHex)20;
            color: \(accentHex);
            border: 1px solid \(accentHex)40;
            border-radius: 4px;
            padding: 1px 6px;
            font-size: 11px;
            font-weight: 600;
            margin: 1px;
          }
        </style>
        </head>
        <body>
        \(rendered)
        </body>
        </html>
        """
    }

    // Simple markdown parser
    private func parseMarkdown(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var html = ""
        var inCodeBlock = false
        var inTable = false
        var inList = false
        var listType = ""

        var i = 0
        while i < lines.count {
            let line = lines[i]

            // Code blocks
            if line.hasPrefix("```") {
                if inCodeBlock {
                    html += "</code></pre>\n"
                    inCodeBlock = false
                } else {
                    let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    html += "<pre><code class=\"language-\(lang)\">"
                    inCodeBlock = true
                }
                i += 1
                continue
            }

            if inCodeBlock {
                html += escapeHTML(line) + "\n"
                i += 1
                continue
            }

            // Close list if needed
            if !line.hasPrefix("- ") && !line.hasPrefix("* ") && !line.match(pattern: "^\\d+\\. ") {
                if inList {
                    html += "</\(listType)>\n"
                    inList = false
                }
            }

            // Headings
            if line.hasPrefix("######") {
                html += "<h6>\(inlineMarkdown(String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)))</h6>\n"
            } else if line.hasPrefix("#####") {
                html += "<h5>\(inlineMarkdown(String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)))</h5>\n"
            } else if line.hasPrefix("####") {
                html += "<h4>\(inlineMarkdown(String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)))</h4>\n"
            } else if line.hasPrefix("###") {
                html += "<h3>\(inlineMarkdown(String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)))</h3>\n"
            } else if line.hasPrefix("##") {
                html += "<h2>\(inlineMarkdown(String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)))</h2>\n"
            } else if line.hasPrefix("#") {
                html += "<h1>\(inlineMarkdown(String(line.dropFirst(1)).trimmingCharacters(in: .whitespaces)))</h1>\n"
            }
            // Blockquote
            else if line.hasPrefix("> ") {
                html += "<blockquote>\(inlineMarkdown(String(line.dropFirst(2))))</blockquote>\n"
            }
            // HR
            else if line == "---" || line == "***" || line == "___" {
                html += "<hr>\n"
            }
            // Unordered list
            else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                if !inList {
                    html += "<ul>\n"
                    inList = true
                    listType = "ul"
                }
                html += "<li>\(inlineMarkdown(String(line.dropFirst(2))))</li>\n"
            }
            // Ordered list
            else if line.match(pattern: "^\\d+\\. ") {
                if !inList {
                    html += "<ol>\n"
                    inList = true
                    listType = "ol"
                }
                let content = line.replacingOccurrences(of: "^\\d+\\. ", with: "", options: .regularExpression)
                html += "<li>\(inlineMarkdown(content))</li>\n"
            }
            // Table
            else if line.contains("|") {
                let cells = line.split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                if !inTable {
                    html += "<table>\n<thead><tr>"
                    for cell in cells { html += "<th>\(inlineMarkdown(cell))</th>" }
                    html += "</tr></thead>\n<tbody>\n"
                    inTable = true
                    i += 2 // skip separator line
                    continue
                } else {
                    html += "<tr>"
                    for cell in cells { html += "<td>\(inlineMarkdown(cell))</td>" }
                    html += "</tr>\n"
                }
            }
            // Empty line
            else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if inTable {
                    html += "</tbody></table>\n"
                    inTable = false
                }
                html += "\n"
            }
            // Paragraph
            else {
                html += "<p>\(inlineMarkdown(line))</p>\n"
            }
            i += 1
        }

        if inList { html += "</\(listType)>\n" }
        if inTable { html += "</tbody></table>\n" }

        return html
    }

    private func inlineMarkdown(_ text: String) -> String {
        var result = escapeHTML(text)
        // Bold + italic
        result = result.replacingOccurrences(of: "\\*\\*\\*(.*?)\\*\\*\\*", with: "<strong><em>$1</em></strong>", options: .regularExpression)
        // Bold
        result = result.replacingOccurrences(of: "\\*\\*(.*?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
        result = result.replacingOccurrences(of: "__(.*?)__", with: "<strong>$1</strong>", options: .regularExpression)
        // Italic
        result = result.replacingOccurrences(of: "\\*(.*?)\\*", with: "<em>$1</em>", options: .regularExpression)
        result = result.replacingOccurrences(of: "_(.*?)_", with: "<em>$1</em>", options: .regularExpression)
        // Code
        result = result.replacingOccurrences(of: "`(.*?)`", with: "<code>$1</code>", options: .regularExpression)
        // Strikethrough
        result = result.replacingOccurrences(of: "~~(.*?)~~", with: "<del>$1</del>", options: .regularExpression)
        // Linked images — badges: [![alt](img_url)](link_url)
        result = result.replacingOccurrences(
            of: "\\[!\\[([^\\]]*)\\]\\(([^)]+)\\)\\]\\(([^)]+)\\)",
            with: "<a href=\"$3\"><img src=\"$2\" alt=\"$1\" style=\"display:inline;vertical-align:middle;max-height:22px;border-radius:4px;\"></a>",
            options: .regularExpression
        )
        // Images
        result = result.replacingOccurrences(of: "!\\[([^\\]]*)\\]\\(([^)]+)\\)", with: "<img src=\"$2\" alt=\"$1\" style=\"max-height:22px;vertical-align:middle;border-radius:4px;\">", options: .regularExpression)
        // Links
        result = result.replacingOccurrences(of: "\\[([^\\]]+)\\]\\(([^)]+)\\)", with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        return result
    }

    private func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

extension String {
    func match(pattern: String) -> Bool {
        range(of: pattern, options: .regularExpression) != nil
    }
}
