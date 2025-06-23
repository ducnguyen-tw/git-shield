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

# === 3. Check if state file exists ===
STATE_FILE="$HOME/.git-shield/installed_repos.txt"
if [ ! -f "$STATE_FILE" ]; then
  echo "ℹ️ No state file found at $STATE_FILE. Skipping per-repo cleanup."
  echo "✅ Uninstallation complete."
  exit 0
fi

# === 4. Automatically remove from all tracked repos ===
while read repo; do
  if [ -f "$repo/.git/hooks/pre-commit" ] && grep -q "git-shield" "$repo/.git/hooks/pre-commit"; then
    rm "$repo/.git/hooks/pre-commit"
    echo "🗑️ Removed pre-commit from: $repo"
  else
    echo "⚠️ Skipped (not a git-shield hook): $repo"
  fi
done < "$STATE_FILE"

rm "$STATE_FILE"
echo "🧼 Removed state file at $STATE_FILE"

echo "✅ git-shield fully uninstalled from system and all tracked repos."
