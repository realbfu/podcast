#!/usr/bin/env python3
"""
gen_index.py
自動掃描 report/ 所有 HTML 簡報，產生 index.html。
部署前自動執行，無需手動維護 index.html。
"""
import re
import sys
from pathlib import Path
from html.parser import HTMLParser

REPORT_DIR = Path(__file__).parent.parent / "report"
OUTPUT = REPORT_DIR / "index.html"

EXCLUDE = {"index.html", "index-Jeff-X1.html", "index-Jeff-X1-2.html"}


class MetaExtractor(HTMLParser):
    """從 HTML 擷取 <title> 與第一個 class="subtitle" 的內容"""
    def __init__(self):
        super().__init__()
        self._in = None
        self.title = ""
        self.subtitle = ""

    def handle_starttag(self, tag, attrs):
        d = dict(attrs)
        cls = d.get("class", "")
        if tag == "title":
            self._in = "title"
        elif "subtitle" in cls and not self.subtitle:
            self._in = "subtitle"

    def handle_endtag(self, tag):
        if tag in ("title", "div", "span", "h1", "h2"):
            self._in = None

    def handle_data(self, data):
        if self._in == "title":
            self.title += data
        elif self._in == "subtitle":
            self.subtitle += data


def extract_meta(path: Path) -> tuple:
    """回傳 (title, subtitle) 字串"""
    p = MetaExtractor()
    try:
        p.feed(path.read_text(encoding="utf-8", errors="ignore")[:8000])
    except Exception:
        pass
    title = p.title.strip()
    subtitle = p.subtitle.strip()

    # 清理 title：移除日期前綴
    title = re.sub(r"^\d{4}[/\-]\d{1,2}([/\-]\d{1,2})?\s*", "", title)
    title = re.sub(r"\s*市場重點簡報\s*$", "", title).strip()

    return title, subtitle


def get_card_title(stem: str, html_title: str, subtitle: str) -> str:
    """決定卡片顯示標題，優先用 subtitle（更有資訊）"""
    # 早晨財經速解讀：subtitle 就是當集主題
    if "早晨財經速解讀" in stem and subtitle:
        return subtitle
    # 其他節目：若有有意義的 subtitle 就用它，否則用 html_title
    if subtitle and subtitle not in ("", html_title):
        return subtitle
    return html_title if html_title else stem


def classify(stem: str) -> tuple:
    """回傳 (tag_class, tag_label)"""
    if "早晨財經速解讀" in stem:
        return "tag-morning", "早晨財經速解讀"

    if "財經皓角" in stem:
        # 從 "財經皓角286" 這類格式抓 EP 號
        m = re.search(r"財經皓角(\d+)", stem)
        ep = f" EP{m.group(1)}" if m else ""
        return "tag-morning", f"財經皓角{ep}"

    # 股癌：EP\d+_市場重點簡報（無額外節目名）
    if re.match(r"EP\d+_市場重點簡報$", stem):
        m = re.search(r"EP(\d+)", stem)
        return "tag-gooaye", f"股癌 EP{m.group(1)}"

    if "台股達人秀" in stem:
        m = re.search(r"[Ee][Pp](\d+)", stem)
        ep = f" EP{m.group(1)}" if m else ""
        return "tag-taiwan", f"台股達人秀{ep}"

    if "財富狂犇" in stem:
        return "tag-taiwan", "財富狂犇"

    if "楚狂人" in stem:
        return "tag-taiwan", "楚狂人"

    if "台積電" in stem or "聯發科" in stem or "台股" in stem:
        return "tag-taiwan", "台股"

    # 有 EP 編號且有節目名
    m_ep = re.search(r"[Ee][Pp](\d+(?:[-–]\d+)?)", stem)
    if m_ep:
        # 取節目名：移除日期段、EP 編號段、市場重點簡報後綴
        label = stem
        label = re.sub(r"\d{4}_\d+_\d*_?", "", label)
        label = re.sub(r"[Ee][Pp]\d+[-–]?\d*_?", "", label)
        label = re.sub(r"_?市場重點簡報.*", "", label).strip("_")
        if label:
            return "tag-other", f"{label}"

    # fallback
    label = re.sub(r"(_市場重點簡報.*|\d{4}_\d+_\d*_?)", "", stem).strip("_")
    return "tag-other", label or "其他"


def sort_key(stem: str):
    m = re.match(r"(\d{4})_(\d{1,2})_(\d{1,2})", stem)
    if m:
        return (int(m.group(1)), int(m.group(2)), int(m.group(3)), 9999)
    m = re.match(r"(\d{4})_(\d{1,2})", stem)
    if m:
        return (int(m.group(1)), int(m.group(2)), 1, 9999)
    m = re.search(r"[Ee][Pp](\d+)", stem)
    if m:
        return (2000, 1, 1, int(m.group(1)))
    return (1900, 1, 1, 0)


def format_date(stem: str) -> str:
    m = re.match(r"(\d{4})_(\d{1,2})_(\d{1,2})", stem)
    if m:
        return f"{m.group(1)}-{int(m.group(2)):02d}-{int(m.group(3)):02d}"
    m = re.match(r"(\d{4})_(\d{1,2})", stem)
    if m:
        return f"{m.group(1)}-{int(m.group(2)):02d}"
    return ""


CSS = """\
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: #0f1115;
      color: #e0e6f0;
      font-family: 'Segoe UI', 'PingFang TC', 'Noto Sans TC', sans-serif;
      min-height: 100vh;
      padding: 40px 24px 60px;
    }
    header { text-align: center; margin-bottom: 40px; }
    header h1 { font-size: 2rem; color: #4ea1ff; letter-spacing: 0.05em; margin-bottom: 8px; }
    header p { color: #7a8ba0; font-size: 0.9rem; }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 16px;
      max-width: 1100px;
      margin: 0 auto;
    }
    .card {
      background: #171b22;
      border: 1px solid #262c38;
      border-radius: 10px;
      padding: 18px 20px;
      text-decoration: none;
      transition: border-color 0.2s, transform 0.15s;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .card:hover { border-color: #4ea1ff; transform: translateY(-2px); }
    .card .tag {
      font-size: 0.7rem;
      font-weight: 700;
      letter-spacing: 0.08em;
      padding: 2px 8px;
      border-radius: 4px;
      align-self: flex-start;
    }
    .tag-morning { background: #1a3a5c; color: #4ea1ff; }
    .tag-gooaye  { background: #3a2a10; color: #ffd166; }
    .tag-taiwan  { background: #1a3a28; color: #5ce88a; }
    .tag-other   { background: #2a1a3a; color: #c084fc; }
    .card .title { font-size: 0.95rem; color: #e0e6f0; line-height: 1.4; }
    .card .date  { font-size: 0.78rem; color: #5a6a80; }\
"""


def main():
    files = sorted(
        [f for f in REPORT_DIR.glob("*.html")
         if f.name not in EXCLUDE and not f.name.startswith("index")],
        key=lambda f: sort_key(f.stem),
        reverse=True,
    )

    cards = []
    for f in files:
        html_title, subtitle = extract_meta(f)
        tag_class, tag_label = classify(f.stem)
        card_title = get_card_title(f.stem, html_title, subtitle)
        date_str = format_date(f.stem)
        cards.append(
            f'    <a class="card" href="{f.name}">\n'
            f'      <span class="tag {tag_class}">{tag_label}</span>\n'
            f'      <span class="title">{card_title}</span>\n'
            f'      <span class="date">{date_str}</span>\n'
            f'    </a>'
        )

    html = (
        '<!DOCTYPE html>\n'
        '<html lang="zh-TW">\n'
        '<head>\n'
        '  <meta charset="UTF-8" />\n'
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0" />\n'
        '  <title>投資 Podcast 市場重點簡報</title>\n'
        '  <style>\n'
        + CSS + '\n'
        '  </style>\n'
        '</head>\n'
        '<body>\n'
        '  <header>\n'
        '    <h1>投資 Podcast 市場重點簡報</h1>\n'
        '    <p>點選卡片即可瀏覽完整簡報</p>\n'
        '  </header>\n'
        '  <div class="grid">\n'
        + "\n\n".join(cards) + "\n"
        '  </div>\n'
        '</body>\n'
        '</html>\n'
    )

    OUTPUT.write_text(html, encoding="utf-8")
    print(f"✅ index.html 已更新，共 {len(cards)} 份簡報")


if __name__ == "__main__":
    main()
