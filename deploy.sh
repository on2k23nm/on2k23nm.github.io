#!/bin/bash

# Deploy script for GitHub Pages
# This script builds the Jekyll site and pushes it to the GitHub Pages repository

set -e  # Exit on error

# GITHUB_PAGES_REPO="https://github.com/on2k23nm/on2k23nm.github.io.git"
GITHUB_PAGES_REPO="git@github.com:on2k23nm/on2k23nm.github.io.git"
GITHUB_PAGES_BRANCH="master"  # Change to 'main' if you rename the branch on GitHub
SITE_DIR="_site"

echo "📦 Building Jekyll site..."
jekyll build

echo "📁 Preparing deployment..."
cd "$SITE_DIR"

# Initialize git if not already a git repo
if [ ! -d .git ]; then
    echo "🔧 Initializing git repository..."
    git init
    git remote add origin "$GITHUB_PAGES_REPO"
else
    echo "✓ Git repository already initialized"
    # Ensure remote is up to date
    git remote set-url origin "$GITHUB_PAGES_REPO"
fi

# Configure git user (if not already configured)
if [ -z "$(git config user.email)" ]; then
    git config user.email "deploy@github.com"
    git config user.name "Deploy Bot"
fi

echo "📝 Adding files..."
git add -A

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "✓ No changes to deploy"
else
    echo "💾 Committing changes..."
    git commit -m "Deploy: $(date +'%Y-%m-%d %H:%M:%S')"
    
    echo "🚀 Pushing to GitHub Pages..."
    git push -u --force origin "$GITHUB_PAGES_BRANCH"
    
    echo "✅ Deployment successful!"
    echo "Your site will be available at: https://on2k23nm.github.io"
fi

cd ..
