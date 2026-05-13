Deploy this project's report/ folder to GitHub Pages and return the live URL.

This is a static HTML report project (no build step needed).
- GitHub user: realbfu
- Repo: podcast
- Deploy source: report/ directory → gh-pages branch
- Live URL: https://realbfu.github.io/podcast/

## Steps

### Step 1: Commit any pending changes

```bash
git add data/ report/ .claude/
git diff --cached --quiet || git commit -m "chore: 更新報告內容"
git push -u origin master
```

If `git push` fails due to no upstream, run:
```bash
git push --set-upstream origin master
```

---

### Step 2: Deploy report/ to gh-pages

```bash
npx gh-pages -d report -b gh-pages
```

---

### Step 3: Enable GitHub Pages (first-time only, skip if already enabled)

```bash
gh api repos/realbfu/podcast/pages \
  --method POST \
  -f source='{"branch":"gh-pages","path":"/"}' 2>/dev/null \
  || echo "Pages already enabled"
```

---

### Step 4: Show the live URL

```
✅ 部署完成！
🌐 網址：https://realbfu.github.io/podcast/

⏳ 首次部署需約 1–3 分鐘生效，已部署過的通常 30 秒內更新。
```

---

## Notes
- Use bash (not PowerShell) for all shell commands.
- Do NOT run `npm run build` — this project has no build step.
- Do NOT check for vite.config.ts — this is not a Vite project.
- Do NOT reinstall gh-pages — it's already in package.json.
- If `npx gh-pages` fails with permission error, retry once. If it fails again, show the error and stop.
