# 投資 Podcast & YouTube 筆記專案

## 用途
把投資理財 podcast / YouTube 的字幕逐字稿，整理成視覺化的市場重點簡報（HTML + PDF），方便快速複習。

支援兩種輸入方式：
- **直接貼連結**：YouTube / Podcast URL → Claude 自動下載字幕、產報告、回傳摘要
- **手動放檔案**：把 SRT / VTT 放進 `data/` → 輸入「更新資料」觸發批次處理

## 目錄結構
```
.
├── data/              # 輸入：原始字幕檔（SRT / VTT）備份
├── report/            # 輸出：整理好的簡報（HTML + PDF）
├── scripts/
│   ├── html_to_pdf.sh       # 用 headless Chrome 把 HTML 轉 PDF
│   └── deploy_gh_pages.sh   # 把 report/ 部署到 GitHub Pages（gh-pages 分支）
└── .claude/
    ├── commands/
    │   ├── deploy_github_page.md  # /deploy_github_page 技能
    │   └── deploy_vercel.md
    └── skills/
        ├── youtube-report/    # 連結 → 自動下載字幕 → 產報告
        └── update-data/       # 偵測 data/ 新檔案 → 批次產報告
```

## 觸發方式

### 方式一：貼連結（推薦）
使用者直接貼 YouTube 或 Podcast 連結，Claude 自動：
1. 用 `yt-dlp` 取得影片資訊與字幕（VTT/SRT）
2. 解析逐字稿，產生 HTML 簡報
3. 轉換 PDF
4. 回傳 300~500 字摘要

### 方式二：手動放檔
1. 把 SRT / VTT 放進 `data/`
2. 輸入「**更新資料**」（或 update data / 更新）
3. Claude 觸發 `update-data` 技能批次處理

## 簡報風格規範
- 黑底（#0f1115）+ 藍標題（#4ea1ff）+ 黃強調（#ffd166）的暗色主題
- 第 1 頁 cover、第 2 頁目錄、最後一頁 Takeaway
- 中間頁面以 `card` / `grid-2` / `grid-3` / `quote` 元件構成
- 每頁固定 1280×720（16:9），列印時自動分頁
- 風格參考：`report/EP659_市場重點簡報.html`、`report/2026_5_8_早晨財經速解讀_市場重點簡報.html`

## 命名規則
報告檔名格式：`<日期或EP編號>_<節目名>_市場重點簡報.{html,pdf}`
- 早晨財經速解讀：`2026_5_8_早晨財經速解讀_市場重點簡報.pdf`
- 股癌：`EP657_市場重點簡報.pdf`
- 台股達人秀：`ep327_台股達人秀_市場重點簡報.pdf`

## GitHub Pages 部署

觸發指令：`/deploy_github_page`

**`report/index.html` 不需手動維護** — 每次執行 `scripts/deploy_gh_pages.sh` 時自動執行 `scripts/gen_index.py` 重建。

部署流程（兩步驟）：
1. `git add data/ report/ .claude/ scripts/ && git commit && git push origin master`
2. `bash scripts/deploy_gh_pages.sh`

腳本做的事：
- 執行 `gen_index.py` 自動掃描 report/ 所有 HTML，重建 index.html
- 建立 `.nojekyll` 停用 Jekyll（避免 GitHub Pages 過濾非標準檔名）
- `git worktree` 取 gh-pages → 清除舊內容 → 複製 report/ → commit + push

## 已知環境細節
- Windows 11 + OneDrive 同步資料夾。Chrome headless 直接寫入 OneDrive 路徑常出現「存取被拒」 → `html_to_pdf.sh` 已內建「先寫 Temp 再 mv」的對策
- Chrome 路徑：`C:\Program Files\Google\Chrome\Application\chrome.exe`
- Shell 用 bash（git bash），不要用 PowerShell 處理檔案路徑
- **ffmpeg 未安裝**：yt-dlp 無法自動轉 SRT，字幕以 VTT 格式存入 `data/`，需用 Python 解析
- **Python 輸出中文**：所有 Python 指令前加 `PYTHONUTF8=1`，否則中文會亂碼
- **yt-dlp 取影片資訊**：需加 `--no-warnings` 並 `>` 寫入暫存 JSON，再用 Python 讀取，避免亂碼
