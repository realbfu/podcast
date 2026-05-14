#!/usr/bin/env bash
# 把 report/ 資料夾部署到 GitHub Pages (gh-pages 分支)
# - 自動執行 gen_index.py 更新 index.html（無需手動維護）
# - 加入 .nojekyll 停用 Jekyll 處理
# - 用 git worktree 本地操作，不需 clone，網路不穩也能用
set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$REPO_ROOT"

REPORT_DIR="report"
REMOTE="origin"
BRANCH="gh-pages"

# ── Step 1: 自動產生 index.html ────────────────────────────────────────────
echo "📋 更新 index.html ..."
PYTHONUTF8=1 python "$REPO_ROOT/scripts/gen_index.py"

# ── Step 2: 確保 .nojekyll 存在（停用 Jekyll，避免 GitHub Pages 過濾檔案） ──
touch "$REPO_ROOT/$REPORT_DIR/.nojekyll"

# ── Step 3: 如有變更就 commit 到 master ────────────────────────────────────
cd "$REPO_ROOT"
git add "$REPORT_DIR/index.html" "$REPORT_DIR/.nojekyll" 2>/dev/null || true
if ! git diff --cached --quiet; then
  git commit -m "chore: 自動更新 index.html 及 .nojekyll"
  git push "$REMOTE" master
fi

# ── Step 4: 部署到 gh-pages ────────────────────────────────────────────────
echo "🚀 部署 $REPORT_DIR/ → $BRANCH ..."

git fetch "$REMOTE" "$BRANCH"
git branch -D "$BRANCH" 2>/dev/null || true

TMP=$(mktemp -d)
cleanup() {
  cd "$REPO_ROOT"
  git worktree remove --force "$TMP" 2>/dev/null || true
  git branch -D "$BRANCH" 2>/dev/null || true
  rm -rf "$TMP" 2>/dev/null || true
}
trap cleanup EXIT

git worktree add -b "$BRANCH" "$TMP" "remotes/$REMOTE/$BRANCH"

# 清除舊內容（保留 .git）
find "$TMP" -maxdepth 1 ! -name '.git' ! -path "$TMP" -exec rm -rf {} + 2>/dev/null || true

# 複製 report/ 所有內容到 worktree 根目錄
cp -r "$REPO_ROOT/$REPORT_DIR"/. "$TMP/"

# commit & push
cd "$TMP"
git add -A
if git diff --cached --quiet; then
  echo "✅ 無變更，跳過部署。"
else
  git commit -m "deploy: 更新 GitHub Pages ($(date '+%Y-%m-%d %H:%M'))"
  git push "$REMOTE" "$BRANCH"
  echo ""
  echo "✅ 部署完成！"
  echo "🌐 https://realbfu.github.io/podcast/"
  echo "⏳ 約 30 秒內生效"
fi
