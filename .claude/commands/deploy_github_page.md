Deploy this project's report/ folder to GitHub Pages and return the live URL.

- GitHub user: realbfu
- Repo: podcast
- Deploy source: report/ directory → gh-pages branch
- Live URL: https://realbfu.github.io/podcast/
- Deploy script: scripts/deploy_gh_pages.sh

## Steps

### Step 1: 確認 index.html 已包含所有新簡報

檢查 `report/index.html` 的 `.grid` 區塊，確認每份新 HTML 都有對應的 `<a class="card">` 卡片。
如果缺少，在正確的日期順序位置補上，格式：

```html
<a class="card" href="<檔名>.html">
  <span class="tag tag-<類型>"><節目名></span>
  <span class="title"><標題></span>
  <span class="date">YYYY-MM-DD</span>
</a>
```

tag 類型對照：
- `tag-morning` → 早晨財經速解讀、財經皓角
- `tag-gooaye`  → 股癌
- `tag-taiwan`  → 台股達人秀、楚狂人、台股相關
- `tag-other`   → 其他節目

### Step 2: Commit master 上的所有變更

```bash
git add data/ report/ .claude/ scripts/
git diff --cached --quiet || git commit -m "chore: 更新報告內容"
git push -u origin master
```

若 push 失敗重試一次即可（OneDrive 網路偶爾不穩）。

### Step 3: 執行部署腳本

```bash
bash scripts/deploy_gh_pages.sh
```

腳本會：
1. `git clone --depth 1` 取最新 gh-pages 分支到暫存目錄
2. 清除舊內容（移除 node_modules 等垃圾）
3. 把 report/ 完整複製過去
4. commit + push 到 gh-pages
5. 程式結束自動清除暫存目錄

### Step 4: 啟用 GitHub Pages（僅首次，已啟用可跳過）

```bash
gh api repos/realbfu/podcast/pages \
  --method POST \
  -f source='{"branch":"gh-pages","path":"/"}' 2>/dev/null \
  || echo "Pages already enabled"
```

### Step 5: 回報結果

```
✅ 部署完成！
🌐 網址：https://realbfu.github.io/podcast/
⏳ 已部署過的通常 30 秒內更新；首次部署約 1–3 分鐘。
```

---

## 常見錯誤排除

| 症狀 | 原因 | 修法 |
|------|------|------|
| 新簡報沒出現在首頁 | index.html 缺少該卡片 | Step 1 補卡片再重部署 |
| `npx gh-pages` 掛住 / `bad object` | npm gh-pages 快取損壞 | 改用 `bash scripts/deploy_gh_pages.sh` |
| `git push` 失敗（Empty reply） | OneDrive 網路不穩 | 重試一次即可 |
| gh-pages 分支有 node_modules | 舊版 npx gh-pages 部署錯誤 | 腳本下次執行會自動清除 |

---

## Notes
- 只用 bash（Git Bash），不用 PowerShell
- **不需要** `npm run build`，這是純靜態 HTML 專案
- **不需要** `npx gh-pages`，改用 `scripts/deploy_gh_pages.sh`
