#!/bin/bash

echo "🔐 Installing git-shield global pre-commit hook..."

# Install gitleaks if missing
if ! command -v gitleaks &> /dev/null; then
  echo "📦 Gitleaks not found. Installing..."
  if command -v brew &> /dev/null; then
    brew install gitleaks
  elif command -v go &> /dev/null; then
    go install github.com/gitleaks/gitleaks/v8@latest
    export PATH="$PATH:$(go env GOPATH)/bin"
  else
    echo "❌ Cannot install gitleaks. Please install manually: https://github.com/gitleaks/gitleaks"
    exit 1
  fi
fi

# Set up global Git template directory
TEMPLATE_DIR=$(git config --global init.templateDir)
if [ -z "$TEMPLATE_DIR" ]; then
  TEMPLATE_DIR="$HOME/.git-template"
  git config --global init.templateDir "$TEMPLATE_DIR"
fi

HOOKS_DIR="$TEMPLATE_DIR/hooks"
mkdir -p "$HOOKS_DIR"

echo "📂 Installing to: $HOOKS_DIR"

# Write pre-commit hook
cat << 'EOF' > "$HOOKS_DIR/pre-commit"
#!/bin/bash
# git-shield: installed by git-shield installer

echo "🔍 Running Gitleaks scan on staged files..."

if ! command -v gitleaks &> /dev/null; then
  echo "❌ Gitleaks is not installed. Please install it first."
  exit 1
fi

TMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

FILES=$(git diff --cached --name-only --diff-filter=ACM)

for FILE in $FILES; do
  if [ -f "$FILE" ]; then
    mkdir -p "$TMP_DIR/$(dirname "$FILE")"
    git show ":$FILE" > "$TMP_DIR/$FILE" 2>/dev/null || true
  fi
done

gitleaks detect --source "$TMP_DIR" --no-git --redact -v
STATUS=$?

if [ $STATUS -ne 0 ]; then
  echo "❌ Commit blocked due to potential secrets!"
  exit 1
fi

echo "✅ No secrets detected!"
exit 0
EOF

chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Pre-commit hook installed to $HOOKS_DIR/pre-commit"
echo "📌 Run 'git init' in any existing repo to activate it."
