#!/usr/bin/env bash
# 把 report/ 資料夾部署到 GitHub Pages (gh-pages 分支)
# 使用 git worktree（本地操作），不需完整 clone，網路不穩也能用
set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$REPO_ROOT"

REPORT_DIR="report"
REMOTE="origin"
BRANCH="gh-pages"

echo "🚀 部署 $REPORT_DIR/ → $BRANCH ..."

# 確保 fetch 到最新 gh-pages 遠端狀態
echo "📡 fetch $BRANCH ..."
git fetch "$REMOTE" "$BRANCH"

# 移除殘留的本地 gh-pages branch（避免 worktree 衝突）
git branch -D "$BRANCH" 2>/dev/null || true

# 建立 worktree（從遠端 gh-pages 建立新本地分支）
TMP=$(mktemp -d)
cleanup() {
  cd "$REPO_ROOT"
  git worktree remove --force "$TMP" 2>/dev/null || true
  git branch -D "$BRANCH" 2>/dev/null || true
  rm -rf "$TMP" 2>/dev/null || true
}
trap cleanup EXIT

git worktree add -b "$BRANCH" "$TMP" "remotes/$REMOTE/$BRANCH"

# 清除舊內容（保留 .git 目錄）
find "$TMP" -maxdepth 1 ! -name '.git' ! -path "$TMP" -exec rm -rf {} + 2>/dev/null || true

# 複製 report/ 所有內容到 worktree 根目錄
cp -r "$REPO_ROOT/$REPORT_DIR"/. "$TMP/"

# 如有變更則 commit & push
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
