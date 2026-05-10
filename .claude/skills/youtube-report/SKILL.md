---
name: youtube-report
description: 接收 YouTube 或 Podcast 連結，自動下載字幕、產生市場重點簡報（HTML + PDF）並輸出到 report/，最後回傳 summary。當使用者貼 URL 或說「幫我處理這個影片／Podcast」時觸發。
---

# youtube-report — 連結 → 市場重點簡報

## 觸發時機
- 使用者貼 YouTube URL（`youtube.com/watch`、`youtube.com/live`、`youtu.be/`）
- 使用者貼 Podcast URL（Apple Podcasts、Spotify、RSS 等）
- 說「幫我處理這個影片」「這個 YouTube」「做這個報告」並附上網址

## 完整流程

### Step 1：取得影片資訊

將 JSON dump 寫入暫存檔再讀取（避免 Windows 終端機中文亂碼）：

```bash
python -m yt_dlp --dump-json --skip-download --no-warnings "<URL>" \
  > "C:/Users/user/OneDrive/Desktop/JeffClaude/investment/podcast/data/tmp_info.json"
```

再用 Python 讀取（**必須加 `PYTHONUTF8=1`**）：

```bash
PYTHONUTF8=1 python -c "
import json
with open('C:/Users/user/OneDrive/Desktop/JeffClaude/investment/podcast/data/tmp_info.json', encoding='utf-8') as f:
    d = json.load(f)
print('title:', d.get('title'))
print('upload_date:', d.get('upload_date'))
print('channel:', d.get('channel'))
print('duration:', d.get('duration_string'))
"
```

取出：
- `title` — 影片標題
- `upload_date` — 上傳日期（格式 YYYYMMDD，轉成 YYYY_M_D）
- `channel` — 頻道名稱
- `duration_string` — 時長

### Step 2：下載字幕（VTT）

```bash
python -m yt_dlp \
  --write-subs \
  --write-auto-subs \
  --sub-langs "zh-Hant,zh-TW,zh-Hans,zh,en" \
  --skip-download \
  --no-warnings \
  --output "C:/Users/user/OneDrive/Desktop/JeffClaude/investment/podcast/data/%(upload_date>%Y_%m_%d)s_%(channel)s_%(title)s.%(ext)s" \
  "<URL>" 2>&1
```

> **注意**：環境未安裝 ffmpeg，yt-dlp 無法自動轉 SRT，字幕會以 `.vtt` 格式儲存。下載後用 `ls -lt data/` 找最新的 `.vtt` 或 `.srt` 檔。

若無任何字幕，改加 `--sub-langs "en"` 下載英文自動字幕，報告中標注「字幕語言：英文自動生成」。

### Step 3：解析字幕為純文字

VTT 格式需用 Python 清理（去時間戳、HTML tag、去重複相鄰行）：

```bash
PYTHONUTF8=1 python -c "
import re

vtt_path = '<實際檔案路徑>'
with open(vtt_path, encoding='utf-8') as f:
    content = f.read()

lines = []
for line in content.split('\n'):
    line = line.strip()
    if not line:
        continue
    if line.startswith('WEBVTT') or line.startswith('Kind:') or line.startswith('Language:'):
        continue
    if re.match(r'^\d{2}:\d{2}', line):
        continue
    line = re.sub(r'<[^>]+>', '', line)
    line = re.sub(r'&amp;', '&', line)
    if line:
        lines.append(line)

deduped = []
prev = None
for l in lines:
    if l != prev:
        deduped.append(l)
        prev = l

print('\n'.join(deduped))
"
```

整理重點時抓：
- 節目名稱、集數、日期、主持人
- 美股 / 台股 / 加密貨幣漲跌數據
- 個股財報、營收、Capex
- 央行 / 政策事件
- 主持人核心觀點與金句
- 5~8 個 Takeaway

### Step 4：產出 HTML 簡報

**CSS 樣式完整複製** `report/` 目錄中最新的 `.html`，不重新發明樣式。

頁面結構（12~16 頁）：
1. Cover — 節目名、副標、日期主持人
2. 目錄 — 本期重點議題
3. 市場數據頁 — `<table class="index-table">`
4. 主題頁 × N — `card` / `grid-2` / `grid-3` / `quote`
5. Takeaway — `<span class="tag">` 分類標籤

### Step 5：命名規則

| 判斷依據 | 檔名格式 |
|---------|---------|
| 頻道名 / 標題含「早晨財經」 | `YYYY_M_D_早晨財經速解讀_市場重點簡報` |
| 頻道名含「股癌」或標題有 EP 編號 | `EP<N>_市場重點簡報` |
| 頻道名含「台股達人」 | `ep<N>_台股達人秀_市場重點簡報` |
| 其他 | `YYYY_M_D_<頻道名簡稱>_市場重點簡報` |

日期格式：`upload_date` 的 YYYYMMDD 轉為 `YYYY_M_D`（月日不補零）。  
檔案存至 `report/<檔名>.html` 和 `report/<檔名>.pdf`。

### Step 6：轉 PDF

```bash
cd "C:/Users/user/OneDrive/Desktop/JeffClaude/investment/podcast"
bash scripts/html_to_pdf.sh "report/<檔名>.html" "report/<檔名>.pdf"
```

### Step 7：清理暫存檔

```bash
rm "C:/Users/user/OneDrive/Desktop/JeffClaude/investment/podcast/data/tmp_info.json"
```

### Step 8：回傳 Summary

產出格式（約 300~500 字）：

```
📋 **<節目名> — <標題/副標>**
<日期> · <主持人>

**<主題1>**
• 重點1
• 重點2

**<主題2>**
...

📌 **Takeaway**
• ...
```

若從 Discord 觸發，用 reply 工具回傳。

## 注意事項

- SRT / VTT 存入 `data/` 保留備份，不刪除
- 已存在同名 PDF 時詢問是否重做，預設跳過
- `python -m yt_dlp` 路徑固定（Scripts 未加入 PATH）
- **所有 Python 指令必須加 `PYTHONUTF8=1`**，否則中文標題 / 頻道名會亂碼
- `--dump-json` 輸出需先寫入暫存 JSON 再讀取，不能直接 pipe 給 Python
- ffmpeg 未安裝，字幕只能下載 VTT，用 Python 手動解析純文字
- OneDrive 路徑含空格時用雙引號包覆
- PDF 轉換用 bash，不用 PowerShell
- Podcast 連結若 yt-dlp 不支援，改用 `--extract-audio` 或直接請使用者提供字幕檔
