#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "TheNeckApp bootstrap"
echo "===================="

if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -d /opt/homebrew/bin ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

if ! command -v xcodegen &> /dev/null; then
  echo "Installing XcodeGen..."
  brew install xcodegen
fi

echo "Generating Xcode project..."
xcodegen generate

echo ""
echo "Done. Open the project with:"
echo "  open TheNeckApp.xcodeproj"
