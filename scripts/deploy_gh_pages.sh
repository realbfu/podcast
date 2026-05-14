#!/usr/bin/env bash
# 把 report/ 資料夾部署到 GitHub Pages (gh-pages 分支)
# 使用 git clone 暫存目錄，不依賴 npm gh-pages 套件（避免快取損壞問題）
set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$REPO_ROOT"

REPORT_DIR="report"
REMOTE_URL="$(git remote get-url origin)"
BRANCH="gh-pages"

echo "🚀 部署 $REPORT_DIR/ → $BRANCH ..."

# 建立暫時目錄，程式結束時自動清除
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# shallow clone gh-pages 分支（只取最新一層，速度快）
echo "📦 clone $BRANCH ..."
git clone --branch "$BRANCH" --single-branch --depth 1 "$REMOTE_URL" "$TMP/deploy"
cd "$TMP/deploy"

# 清除舊內容（保留 .git 目錄）
find . -maxdepth 1 ! -name '.git' ! -path '.' -exec rm -rf {} + 2>/dev/null || true

# 複製 report/ 所有內容到 clone 根目錄
cp -r "$REPO_ROOT/$REPORT_DIR"/. .

# 如有變更則 commit & push
git add -A
if git diff --cached --quiet; then
  echo "✅ 無變更，跳過部署。"
else
  git commit -m "deploy: 更新 GitHub Pages ($(date '+%Y-%m-%d %H:%M'))"
  git push origin "$BRANCH"
  echo ""
  echo "✅ 部署完成！"
  echo "🌐 https://realbfu.github.io/podcast/"
  echo "⏳ 約 30 秒內生效"
fi
