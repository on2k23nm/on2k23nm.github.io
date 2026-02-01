# GitHub Pages Deployment Setup

## Current Setup
- **Private Source Repo**: https://github.com/on2k23nm/on2k23nm-blog-source
- **Public Site Repo**: https://github.com/on2k23nm/on2k23nm.github.io
- **Live Site**: https://on2k23nm.github.io

## First-Time Setup Instructions

### Step 1: Create the GitHub Pages Repository

Go to GitHub and create a **new public repository** named exactly: `on2k23nm.github.io`

- Repository name: `on2k23nm.github.io`
- Description: "Compiled output for on2k23nm blog"
- Public: Yes
- Initialize with README: No

### Step 2: Configure GitHub Pages

1. Go to Repository Settings → Pages
2. Set Source to "Deploy from a branch"
3. Branch: `main`
4. Folder: `/ (root)`

### Step 3: Initial Deployment

Run this command from your workspace:

```bash
cd /home/onkar/BLOG/public_repo
./deploy.sh
```

This will:
- Build the Jekyll site to `_site/`
- Initialize git in `_site/`
- Push compiled output to `on2k23nm.github.io`

### Step 4: Verify

Visit https://on2k23nm.github.io to see your live site!

## Regular Deployments

After making changes to your blog:

```bash
cd /home/onkar/BLOG/public_repo
./deploy.sh
```

This script automatically:
- Rebuilds your site
- Commits changes with timestamp
- Pushes to GitHub Pages
- Works only if there are changes to deploy

## Workflow Summary

```
Edit markdown/content in private repo (on2k23nm-blog-source)
         ↓
Run: git push origin main  (backup source code)
         ↓
Run: ./deploy.sh  (from public_repo)
         ↓
Jekyll builds to _site/
         ↓
_site/ is pushed to on2k23nm.github.io (public)
         ↓
Site updates at https://on2k23nm.github.io
```

## Important Notes

✅ **What's private**: Source markdown, configurations, drafts  
✅ **What's public**: Only the compiled HTML/CSS/JS in _site/  
✅ **Benefits**: 
- Source code stays private
- Blog is publicly accessible
- Clean separation of concerns

⚠️ **Remember**:
- The `_site/` folder is auto-generated, don't edit it directly
- Always edit files in the source repo and redeploy
- The deploy script commits with timestamp, so you have history

## Troubleshooting

### "fatal: remote origin already exists"
This means _site/ is already a git repo. Just push:
```bash
cd _site
git push origin main
```

### Changes not showing up
Wait a few seconds for GitHub Pages to rebuild, then refresh (Ctrl+Shift+R for hard refresh).

### Can't push to GitHub
Make sure:
1. You have push access to on2k23nm.github.io repo
2. You're authenticated with GitHub
3. Run: `git remote -v` to check the URL

## To Deploy Manually (if deploy.sh has issues)

```bash
cd /home/onkar/BLOG/public_repo

# Build
jekyll build

# Deploy
cd _site
git add -A
git commit -m "Deploy: $(date)"
git push origin main
```
