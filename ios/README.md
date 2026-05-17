# TheNeckApp iOS

iOS native app (Swift + SwiftUI, iOS 17+).

## First-time setup on Mac

```bash
cd ios
chmod +x bootstrap.sh
./bootstrap.sh
open TheNeckApp.xcodeproj
```

The script installs Homebrew + XcodeGen if missing, then generates `TheNeckApp.xcodeproj` from `project.yml`.

## Structure

```
ios/
├── project.yml                 # XcodeGen config
├── bootstrap.sh                # First-time setup
├── TheNeckApp/                 # App sources
│   ├── TheNeckAppApp.swift     # Entry point
│   ├── Core/
│   │   └── ScoreEngine/        # Pure score logic, no UIKit
│   │       ├── Models.swift
│   │       └── ScoreEngine.swift
│   └── Features/
│       └── Home/
│           └── HomeView.swift  # Mock home screen
└── TheNeckAppTests/
    └── ScoreEngineTests.swift  # Swift Testing
```

## Running tests

In Xcode: `Cmd+U`

Or from command line:
```bash
xcodebuild test -scheme TheNeckApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Regenerating the project

After adding new source files, re-run:
```bash
xcodegen generate
```
