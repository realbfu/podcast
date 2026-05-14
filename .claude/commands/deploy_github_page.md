Deploy this project's report/ folder to GitHub Pages and return the live URL.

- GitHub user: realbfu
- Repo: podcast
- Deploy source: report/ directory → gh-pages branch
- Live URL: https://realbfu.github.io/podcast/
- Deploy script: `bash scripts/deploy_gh_pages.sh`

## 完整流程（一個指令搞定）

### Step 1: Commit master 上的所有變更

```bash
git add data/ report/ .claude/ scripts/
git diff --cached --quiet || git commit -m "chore: 更新報告內容"
git push -u origin master
```

若 push 失敗（OneDrive 網路偶爾不穩）：重試一次即可。

---

### Step 2: 執行部署腳本

```bash
bash scripts/deploy_gh_pages.sh
```

腳本會自動完成以下所有事項：
1. **執行 `gen_index.py`** — 掃描 report/ 所有 HTML，重建 index.html（無需手動維護）
2. **建立 `.nojekyll`** — 停用 GitHub Pages 的 Jekyll 處理，避免過濾非標準檔名
3. 若 index.html / .nojekyll 有變更，自動 commit 到 master
4. `git worktree` 取 gh-pages → 清除舊內容 → 複製 report/ → commit + push

---

### Step 3: 啟用 GitHub Pages（僅首次，已啟用可跳過）

```bash
gh api repos/realbfu/podcast/pages \
  --method POST \
  -f source='{"branch":"gh-pages","path":"/"}' 2>/dev/null \
  || echo "Pages already enabled"
```

---

### Step 4: 回報結果

```
✅ 部署完成！
🌐 https://realbfu.github.io/podcast/
⏳ 約 30 秒內生效
```

---

## 注意事項

- 只用 bash（Git Bash），不用 PowerShell
- **不需要** 手動更新 `report/index.html` — `gen_index.py` 自動處理
- **不需要** `npx gh-pages` — 改用 `scripts/deploy_gh_pages.sh`
- **不需要** `npm run build` — 純靜態 HTML 專案

## 故障排除

| 症狀 | 原因 | 解法 |
|------|------|------|
| git push 失敗 empty reply | OneDrive 網路不穩 | 重試一次 |
| worktree 衝突 | 殘留本地 branch | 腳本自動刪除，重新執行即可 |
| 簡報出現在 gh-pages 但首頁看不到 | 之前手動維護 index.html 時漏掉 | 執行腳本會自動重建完整 index.html |
