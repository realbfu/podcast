Deploy this project to GitHub Pages and return the live URL.

## Steps

### Step 1: Check GitHub CLI authentication

Run in bash:
```bash
gh auth status
```
If not authenticated, run `gh auth login` and wait for the user to complete browser authentication before continuing.

---

### Step 2: Detect project info

```bash
# Get current folder name as default repo name
basename $(pwd)

# Check existing git remote
git remote -v
```

Identify:
- `REPO_NAME` = the remote repository name (from `git remote -v`) or the current folder name if no remote exists.
- `GITHUB_USER` = run `gh api user --jq .login` to get the authenticated username.

---

### Step 3: Ensure a GitHub repository exists and remote is correct

Run:
```bash
gh repo list --limit 100 --json name --jq '.[].name'
```

- **If `REPO_NAME` is already in the list** → verify the remote URL points to `https://github.com/GITHUB_USER/REPO_NAME.git`. If not, update it:
  ```bash
  git remote set-url origin https://github.com/GITHUB_USER/REPO_NAME.git
  ```
- **If `REPO_NAME` is NOT in the list** → create a new public repo and set the remote:
  ```bash
  gh repo create REPO_NAME --public --source=. --remote=origin
  ```

---

### Step 4: Verify Vite base path (skip if project is not Vite)

Check if `vite.config.ts` or `vite.config.js` exists.

If it does, ensure the `base` field is set to `'/REPO_NAME/'`. Read the file, then:
- If `base:` is already correct → skip.
- If `base:` is missing or wrong → edit the file and add/update:
  ```ts
  base: '/REPO_NAME/',
  ```
  Tell the user what was changed.

---

### Step 5: Build the project

Run:
```bash
npm run build
```

After the build succeeds, detect the output directory:
- Check if `dist/` exists → use `dist` (Vite default)
- Check if `build/` exists → use `build` (CRA default)
- If neither exists → stop and ask the user which folder contains the built output.

Set `BUILD_DIR` to the detected folder.

---

### Step 6: Install gh-pages if needed

```bash
npm ls gh-pages --depth=0 2>/dev/null || npm install --save-dev gh-pages
```

---

### Step 7: Push source code and deploy to gh-pages branch

```bash
# Push source code to current branch (create upstream if first push)
git add -A
git diff --cached --quiet || git commit -m "chore: deploy to GitHub Pages"
git push -u origin HEAD

# Deploy built output to gh-pages branch
npx gh-pages -d BUILD_DIR -b gh-pages
```

Replace `BUILD_DIR` with the directory detected in Step 5.

---

### Step 8: Enable GitHub Pages (first-time only)

Run:
```bash
gh api repos/GITHUB_USER/REPO_NAME/pages \
  --method POST \
  -f source='{"branch":"gh-pages","path":"/"}' 2>/dev/null \
  || echo "Pages already enabled"
```

---

### Step 9: Show the live URL

The GitHub Pages URL is always:
```
https://GITHUB_USER.github.io/REPO_NAME/
```

Display it clearly:
```
✅ 部署完成！
🌐 網址：https://GITHUB_USER.github.io/REPO_NAME/

⏳ GitHub Pages 首次部署需要約 1–3 分鐘才會生效，請稍後再開啟。
```

---

## Notes
- Use bash (not PowerShell) for all shell commands.
- The project root is the current working directory.
- If `npm run build` fails, stop immediately and show the error — do not deploy stale output.
- Do not force-push or reset any branch without user confirmation.
- If the repo is private, GitHub Pages requires a GitHub Pro/Team plan — warn the user if `gh repo create` defaults to private.
