#!/bin/bash

set -e

echo "🧹 Uninstalling git-shield..."

# === 1. Remove global template hook ===
TEMPLATE_DIR=$(git config --global init.templateDir || true)
HOOK_PATH="$TEMPLATE_DIR/hooks/pre-commit"

if [ -n "$TEMPLATE_DIR" ] && [ -f "$HOOK_PATH" ]; then
  if grep -q "git-shield" "$HOOK_PATH"; then
    rm "$HOOK_PATH"
    echo "🗑️ Removed global pre-commit hook from $HOOK_PATH"
  else
    echo "⚠️ Found a pre-commit hook, but it wasn't installed by git-shield."
    echo "❌ Not removing to avoid breaking your setup."
  fi
else
  echo "✅ No global pre-commit hook found."
fi

# === 2. Unset init.templateDir ===
git config --global --unset init.templateDir && echo "⚙️ Git global templateDir unset."

# === 3. Remove pre-commit from current repo if marker exists ===
REPO_DIR=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$REPO_DIR" ] && [ -f "$REPO_DIR/.git/hooks/pre-commit" ]; then
  if grep -q "git-shield" "$REPO_DIR/.git/hooks/pre-commit"; then
    rm "$REPO_DIR/.git/hooks/pre-commit"
    echo "🗑️ Removed pre-commit hook from current repo: $REPO_DIR"
  else
    echo "⚠️ Current repo has a pre-commit hook, but not installed by git-shield."
  fi
fi


echo "✅ git-shield fully uninstalled from system and all tracked repos."
