# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter package called `swipe_cards` that provides Tinder-like swipe card functionality. It's published to pub.dev and supports right swipe (like), left swipe (nope), and up swipe (superlike) gestures.

## Development Commands

### Flutter Development
- `flutter pub get` - Install dependencies
- `flutter test` - Run unit tests 
- `flutter analyze` - Analyze Dart code for issues
- `flutter run` - Run the example app (from example/ directory)
- `flutter build apk` - Build Android APK (from example/ directory)
- `flutter build ios` - Build iOS app (from example/ directory)

### Working with Example App
- `cd example/` then `flutter run` - Run the demo app
- The example app demonstrates all swipe card functionality with colored cards

## Architecture

### Core Components

**SwipeCards Widget** (`lib/swipe_cards.dart:8-46`)
- Main widget that renders the card stack
- Manages MatchEngine and handles swipe events
- Configurable swipe directions and thresholds
- Supports custom tags for like/nope/superlike feedback

**MatchEngine** (`lib/swipe_cards.dart:221-259`)
- Controller for the swipe cards stack
- Manages current and next items in the stack
- Extends ChangeNotifier for state management
- Provides `cycleMatch()` and `rewindMatch()` functionality

**SwipeItem** (`lib/swipe_cards.dart:261-320`)
- Wrapper for individual card data
- Contains content and action callbacks
- Manages decision state (undecided/like/nope/superlike)
- Supports slide update callbacks for real-time feedback

**DraggableCard** (`lib/draggable_card.dart:11-56`)
- Handles the drag gesture and animations
- Manages card positioning, rotation, and slide animations
- Controls swipe thresholds and region detection
- Supports elastic back animation when swipe is unsuccessful

**ProfileCard** (`lib/profile_card.dart:3-10`)
- Simple wrapper container for card content
- Provides consistent card styling base

### Key Features

**Animation System**
- Two main animations: slideBack (elastic return) and slideOut (completion)
- Rotation based on drag position and direction
- Scale animation for back card (currently commented out for performance)

**Swipe Detection**
- Configurable swipe thresholds (default 0.15 of screen width/height)
- Three swipe regions: left (nope), right (like), up (superlike)
- Individual swipe direction toggles (leftSwipeAllowed, rightSwipeAllowed, upSwipeAllowed)

**Performance Optimizations**
- Card rebuilding minimization through key management
- Disabled secondary animations for better performance
- Anchor bounds initialization for proper positioning

## Package Structure

- `lib/swipe_cards.dart` - Main export file with core widgets
- `lib/draggable_card.dart` - Drag gesture handling and animations
- `lib/profile_card.dart` - Basic card container
- `example/` - Demo Flutter app showing usage
- `pubspec.yaml` - Package configuration (Flutter SDK >=1.17.0, Dart >=2.17.5)

## Example Usage Pattern

```dart
MatchEngine _matchEngine = MatchEngine(swipeItems: _swipeItems);

SwipeCards(
  matchEngine: _matchEngine,
  itemBuilder: (BuildContext context, int index) => YourCardWidget(),
  onStackFinished: () => handleStackComplete(),
  itemChanged: (SwipeItem item, int index) => handleItemChange(),
  upSwipeAllowed: true,
  leftSwipeAllowed: true,
  rightSwipeAllowed: true,
)
```

## Testing

- Run `flutter test` from project root for unit tests
- Use `flutter run` in example/ directory to test functionality manually
- The example app provides buttons for programmatic swiping to test all scenarios