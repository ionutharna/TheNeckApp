#!/bin/bash
set -e

REPO_URL="https://github.com/ionutharna/TheNeckApp.git"
REPO_DIR="$HOME/Developer/TheNeckApp"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SHARE="$HOME/.local/share"

echo "==> TheNeckApp Mac setup"

mkdir -p "$LOCAL_BIN" "$LOCAL_SHARE"
export PATH="$LOCAL_BIN:$PATH"

if ! command -v xcodegen &> /dev/null; then
  echo "==> Installing XcodeGen binary (no brew, user-local)..."
  TMP=$(mktemp -d)
  curl -fsSL "https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip" -o "$TMP/xcodegen.zip"
  unzip -q "$TMP/xcodegen.zip" -d "$TMP"
  cp "$TMP/xcodegen/bin/xcodegen" "$LOCAL_BIN/xcodegen"
  chmod +x "$LOCAL_BIN/xcodegen"
  mkdir -p "$LOCAL_SHARE/xcodegen"
  cp -R "$TMP/xcodegen/share/xcodegen/." "$LOCAL_SHARE/xcodegen/" 2>/dev/null || true
  rm -rf "$TMP"

  if ! grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  fi
  if ! grep -q '.local/bin' "$HOME/.bash_profile" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bash_profile"
  fi
fi

if [[ ! -d "$REPO_DIR" ]]; then
  echo "==> Cloning repository..."
  mkdir -p "$HOME/Developer"
  git clone "$REPO_URL" "$REPO_DIR"
else
  echo "==> Repository exists, pulling latest..."
  cd "$REPO_DIR"
  git pull --rebase || true
fi

cd "$REPO_DIR/ios"
echo "==> Generating Xcode project..."
xcodegen generate

echo "==> Opening Xcode..."
open TheNeckApp.xcodeproj

echo ""
echo "==> Done! In Xcode: select iPhone 16 Pro, press Cmd+R."
