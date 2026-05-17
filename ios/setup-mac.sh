#!/bin/bash
set -e

REPO_URL="https://github.com/ionutharna/TheNeckApp.git"
REPO_DIR="$HOME/Developer/TheNeckApp"

echo "==> TheNeckApp Mac setup"

if ! command -v brew &> /dev/null; then
  echo "==> Installing Homebrew (non-interactive)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -d /opt/homebrew/bin ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /usr/local/Homebrew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v xcodegen &> /dev/null; then
  echo "==> Installing XcodeGen..."
  brew install xcodegen
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
echo "==> Done! Press Cmd+R in Xcode to run on iPhone 16 Pro simulator."
