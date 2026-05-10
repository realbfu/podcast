Deploy this project to Vercel as a static site and return the live URL.

## Steps

1. **Check Vercel CLI**
   Run `vercel --version` in bash. If the command fails, install it with:
   ```
   npm install -g vercel
   ```

2. **Check login status**
   Run `vercel whoami`. If not logged in, run `vercel login` and wait for the user to complete browser authentication, then continue.

3. **Ensure vercel.json exists**
   Check if `vercel.json` exists in the project root. If it does not exist, create it with this content so Vercel serves the `report/` folder as the public root and handles Chinese filenames correctly:
   ```json
   {
     "version": 2,
     "public": true,
     "builds": [
       { "src": "report/**", "use": "@vercel/static" }
     ],
     "routes": [
       { "src": "/(.*)", "dest": "/report/$1" }
     ]
   }
   ```

4. **Deploy to production**
   Run:
   ```
   vercel --prod --yes
   ```
   Capture the full output.

5. **Extract and show the URL**
   Parse the output for the production URL (the line starting with `https://` that contains the project domain, not a preview URL).
   Display it clearly to the user, e.g.:
   ```
   ✅ 部署完成！
   🌐 網址：https://your-project.vercel.app
   ```

## Notes
- Use bash (not PowerShell) for all shell commands.
- The project root is the current working directory.
- If deployment fails due to file size or count limits, remind the user that `data/` (raw SRT/VTT files) and `report/*.pdf` may be excluded via `.vercelignore` to reduce bundle size.
- Do not commit or push any code — only deploy.
