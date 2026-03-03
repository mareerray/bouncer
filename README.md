# Bouncer 🏐
A retro-style Flutter mobile game inspired by the classic 90s bouncing ball games.
This project demonstrates how to integrate device hardware sensors, real-time animation, and simple 2D physics in Flutter.

![Bouncer app](assets/images/bouncer.png)

## 📱 Screenshots

| Grid View | Full Image | Full Image Zoom|
| ---------- | ---------------- | --------- |
| ![Fav Images](assets/images/favimages.png) | ![Full Image](assets/images/fullimage.png) | ![Full Image Zoom](assets/images/fullimagezoom.png) |   

## 🎮 Overview
Bouncer challenges the player to destroy all the blocks on the screen using a bouncing ball.
Instead of using traditional touch controls, the player tilts their physical device to move a paddle horizontally — thanks to accelerometer input.
The main goal is to keep the ball from falling off the bottom of the screen while clearing all blocks.

## ✨ Key Features
Hardware Sensor Integration: Uses the sensors_plus package to map phone tilt to paddle movement.

Physics-Based Gameplay: Follows the law of reflection — the angle of incidence equals the angle of reflection during collisions.

Smooth Real-Time Animation: Powered by Flutter’s AnimationController or Ticker for fast, smooth gameplay.

Accurate 2D Positioning: Built using Stack and Positioned widgets for pixel-perfect control of game elements.

## 🕹️ Game Rules

| Event	                 | Behavior                                   |
| ---------------------- | ------------------------------------------ |
| Ball Movement	| The ball moves in a straight line until it hits something. |
| Top or Bottom Collision	| The ball's vertical velocity reverses; horizontal stays the same. |
| Wall Collision	| The ball's horizontal velocity reverses; vertical stays the same.| 
| Winning	| Destroy every block to see the "You Won!" message. |
| Losing	| If the ball touches the bottom, the game ends with a "You Lost!" message. |
| Paddle Limits	| The paddle cannot move outside the screen boundary. |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- A physical mobile device (emulators do not support accelerometer-based input)

### Installation Steps
1. Clone the repository:

```
git clone https://github.com/mareerray/bouncer.git
````

2. Navigate into the project folder:

```
cd bouncer
```
3. Install dependencies:

```
flutter pub get
````

4. Run the app on your connected device:
```
flutter run -d <device-id>
````

### Android Phone Connection
1. Enable Developer Options:
- Go to Settings → About Phone → Tap Build Number 7 times
- Go back to Settings → Developer Options → Enable USB Debugging

2. Connect & Check:

```
# Connect phone with USB cable
flutter devices

# Should show: (example)
SM-G998B (mobile) -  abc123def456 -  android-arm64 -  Android 14 (API 34)

# Choose specific device (if multiple connected)
flutter run -d <device-id>

# example
flutter run -d abc123def456
````
### Troubleshooting Commands
```
# List all available devices
flutter devices

# Clean & rebuild (if app crashes)
flutter clean
flutter pub get
flutter run

# Run in release mode (faster)
flutter run --release

# Choose specific device (if multiple connected)
flutter run -d <device-id>
````

## 📂 Project Structure
```
bouncer/
├── lib/
│   ├── main.dart
│   ├── ball.dart
│   ├── block.dart
│   └── bouncer_game.dart
├── assets/
│   └── sounds/    
├── pubspec.yaml   # manages dependencies and assets
````

## 🔮 Planned Enhancements

- Introduce difficulty levels (e.g., ball speed, paddle size)

- Include in-game power-ups and time-based levels

## Author
[Mayuree Reunsati](https://github.com/mareerray)