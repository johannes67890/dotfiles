"""Render Claude's Markdown answers as Qt rich text, with highlighted code (used by the quickshell menu)."""
import re
import sys

import markdown

md = markdown.Markdown(
    extensions=["fenced_code", "codehilite", "tables", "sane_lists"],
    extension_configs={"codehilite": {"noclasses": True, "pygments_style": "github-dark", "guess_lang": False}},
)
# Answers can carry web content, and Qt loads <img> sources and background images (background="…",
# url(…)). Raw HTML in an answer is therefore shown as text, and Markdown images are dropped.
md.preprocessors.deregister("html_block")
md.inlinePatterns.deregister("html")
html = md.convert(sys.argv[1])
html = re.sub(r"<img[^>]*>", "", html, flags=re.I)
# Inline code gets a dark background (code inside blocks starts with <span></span> and is left alone).
html = re.sub(r"(?<!</span>)<code>", '<code style="background-color:#2a2a2a">', html)
# Qt ignores the background on <div>; a one-cell table gives code blocks their box and padding.
html = re.sub(r'<div class="codehilite" style="background: ([^;"]+)[^"]*">\s*<pre[^>]*>', r'<table width="100%" cellpadding="10" bgcolor="\1"><tr><td><pre>', html)
html = html.replace("</pre></div>", "</pre></td></tr></table>")
print(html)
