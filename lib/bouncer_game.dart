import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ball.dart';
import 'block.dart';
import 'block.dart' as create_blocks;

class BouncerGame extends StatefulWidget {
  const BouncerGame({super.key});

  @override
  State<BouncerGame> createState() => _BouncerGameState();
}

class _BouncerGameState extends State<BouncerGame> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AudioPlayer destroyBlockPlayer;
  late AudioPlayer winPlayer;
  late AudioPlayer losePlayer;

  // Screen size
  double screenWidth = 400.0;
  double screenHeight = 800.0;

  // Game objects
  late Ball ball;
  List<Block> blocks = [];

  // Paddle
  double paddleX = 0.0;
  double targetPaddleX = 0.0;

  // Constants 
  static const double paddleWidth = 180.0;
  static const double paddleHeight = 20.0;
  static const double sensitivity = 500.0;
  static const double smoothing = 0.15;
  static const double fixedDeltaTime = 1 / 60.0;
  static const double playTop = 120.0;
  static const double maxSpeed = 12.0;
  static const double cornerZone = 0.5 * 10.0; 

  // Game state
  StreamSubscription<UserAccelerometerEvent>? accelSubscription;
  double accumulatedTime = 0.0;
  double tilt = 0.0;
  bool soundOn = true;
  bool paused = false;
  bool gameWon = false;
  bool gameLost = false;
  int score = 0;

  bool get isGameActive => !paused && !gameWon && !gameLost;

  List<Color> get blockColors => create_blocks.createBlockColors();

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _initializeGame();
    _setupSensors();
    _setupAnimationController();
  }

  void _initializeAudio() {
    destroyBlockPlayer = AudioPlayer();
    winPlayer = AudioPlayer();
    losePlayer = AudioPlayer();
  }

  void _initializeGame() {
    // Create ball and blocks
    ball = Ball(x: screenWidth / 2, y: screenHeight / 2);
    blocks = _createBlocksFromMaps(create_blocks.createBlocks());

    // Center paddle
    final centerX = screenWidth / 2 - paddleWidth / 2;
    paddleX = centerX;
    targetPaddleX = centerX;
  }

  List<Block> _createBlocksFromMaps(List<Map<String, dynamic>> maps) {
    return maps.map((map) => 
      Block(x: map['x'], y: map['y'], colorIndex: map['colorIndex'])
    ).toList();
  }

  void _setupSensors() {
    accelSubscription = userAccelerometerEventStream().listen((event) {
      if (!isGameActive) return;
      tilt = event.x;
      if (tilt.abs() > 0.25) {
        final newTarget = (screenWidth / 2) + (tilt * sensitivity);
        targetPaddleX += (newTarget - targetPaddleX) * smoothing;
        targetPaddleX = targetPaddleX.clamp(0.0, screenWidth - paddleWidth);
      }
    });
  }

  void _setupAnimationController() {
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _controller.addListener(_gameLoop);
  }

  void _gameLoop() {
    accumulatedTime += 1 / 60.0;
    while (accumulatedTime >= fixedDeltaTime) {
      _gameStep(fixedDeltaTime);
      accumulatedTime -= fixedDeltaTime;
    }
    setState(() {});
  }

  void _gameStep(double dt) {
    if (!isGameActive) return;

    _updatePaddlePosition();
    ball.move(dt, 60.0);

    // ════════════════════════════════════════════
    // SPEED HELPER (comment out for FAST mode!)
    // TAME SPEED EARLY 
    if (ball.vx.abs() > 7.0) ball.vx *= 0.98;  
    if (ball.vy.abs() > 7.0) ball.vy *= 0.98;
    // ════════════════════════════════════════════

    _handleWallCollisions();
    _handleBlockCollisions();
    _handlePaddleCollision();
    _capBallSpeed();
    _checkWinLoseConditions();
  }

  void _updatePaddlePosition() {
    paddleX += (targetPaddleX - paddleX) * smoothing;
    paddleX = paddleX.clamp(0.0, screenWidth - paddleWidth);
  }

  void _handleWallCollisions() {
    const double gameLeft = 10;
    final double gameRight = screenWidth + 10;
    // CEILING
    if (ball.y <= playTop) {
      ball.y = playTop + ball.radius;
      ball.vy = -ball.vy;
    }
    // LEFT wall
    if (ball.x <= gameLeft) {
      ball.x = ball.radius + gameLeft;  // Push out to prevent sticking             
      ball.vx = -ball.vx;
    }
    
    // RIGHT wall  
    if (ball.x + ball.radius * 2 >= gameRight) {
      ball.x = gameRight - (ball.radius * 2);  // Push out to prevent sticking
      ball.vx = -ball.vx;
    }
  }

  void _handleBlockCollisions() {
    for (int i = blocks.length - 1; i >= 0; i--) {
      final block = blocks[i];
      final drawX = block.x - 15;
      final drawY = block.y + 50;
      final blockLeft = drawX;
      final blockRight = drawX + 55;
      final blockTop = drawY;
      final blockBottom = drawY + 25;
      
      final hitMargin = blocks.length > 1 ? 0.5 * ball.radius : 1.0 * ball.radius;

      if ((ball.x + hitMargin > blockLeft &&
          ball.x - hitMargin < blockRight) &&
          (ball.y + hitMargin > blockTop &&
          ball.y - hitMargin < blockBottom)) {
        
        // Push ball out and bounce
        double overlapX = 0.0, overlapY = 0.0;
        if (ball.x < blockLeft) {
          overlapX = blockLeft - ball.x;
          ball.x = blockLeft - ball.radius - 1;
        } else if (ball.x > blockRight) {
          overlapX = ball.x - blockRight;
          ball.x = blockRight + ball.radius + 1;
        }
        if (ball.y < blockTop) {
          overlapY = blockTop - ball.y;
          ball.y = blockTop - ball.radius - 1;
        } else if (ball.y > blockBottom) {
          overlapY = ball.y - blockBottom;
          ball.y = blockBottom + ball.radius + 1;
        }
        
        if (overlapX > overlapY) {
          ball.vx = -ball.vx; 
        } else {
          ball.vy = -ball.vy; 
        }

        // Remove block
        blocks.removeAt(i);
        score += 10;
        _playDestroySound();
        break;
      }
    }
  }

  void _handlePaddleCollision() {
    final paddleLeft = paddleX;
    final paddleRight = paddleX + paddleWidth;
    final paddleBottom = screenHeight - 150;   
    final paddleTop = paddleBottom - paddleHeight;  
    
    // Ball center + radius vs paddle
    final ballBottom = ball.y + ball.radius;
    final ballTop = ball.y - ball.radius;
    final ballLeft = ball.x - ball.radius;
    final ballRight = ball.x + ball.radius;

    // Check if ball overlaps paddle vertically AND horizontally
    if (ballBottom >= paddleTop && 
        ballTop <= paddleBottom &&  
        ballRight >= paddleLeft && 
        ballLeft <= paddleRight &&
        (ballLeft > cornerZone || ballRight < screenWidth - cornerZone)) {

      // Push ball above paddle
      ball.y = paddleTop - ball.radius;
      
      // Angle based on hit position
      final paddleCenter = paddleX + paddleWidth / 2;
      final hitPos = (ball.x - paddleCenter) / (paddleWidth / 2);
      
      ball.vy = -ball.vy.abs() * 1.08;  // Bounce up faster
      ball.vx = hitPos * 8.0;          // Left/right angle
    }
  }

  void _capBallSpeed() {
    final speed = sqrt(ball.vx * ball.vx + ball.vy * ball.vy);
    if (speed > maxSpeed) {
      ball.vx = ball.vx * (maxSpeed / speed);
      ball.vy = ball.vy * (maxSpeed / speed);
    }
  }

  void _checkWinLoseConditions() {
    // Lose condition
    if (ball.y + ball.radius * 2 >= screenHeight && !gameLost) {
      if (soundOn)     losePlayer.play(AssetSource('sounds/youlost.mp3'));
      gameLost = true;
      return;
    }

    // Win condition
    if (blocks.isEmpty && !gameWon) {
      if (soundOn) winPlayer.play(AssetSource('sounds/youwin.mp3'));
      gameWon = true;
    }
  }

  void _playDestroySound() {
    if (soundOn) {
      destroyBlockPlayer.play(AssetSource('sounds/destroy.wav'));
      destroyBlockPlayer.setVolume(1.0);
    }
  }

  void restart() {
    winPlayer.stop();
    losePlayer.stop();
    destroyBlockPlayer.stop();

    setState(() {
      blocks = _createBlocksFromMaps(create_blocks.createBlocks());
      accumulatedTime = 0.0;
      score = 0;
      gameWon = false;
      gameLost = false;
      ball = Ball(x: 20.0, y: 380.0);
      final centerX = screenWidth / 2 - paddleWidth / 2;
      paddleX = centerX;
      targetPaddleX = centerX;
    });
  }

  @override
  void dispose() {
    accelSubscription?.cancel();
    _controller.dispose();
    destroyBlockPlayer.dispose();
    winPlayer.dispose();
    losePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          screenWidth = constraints.maxWidth;
          screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              // Background
              Container(color: Colors.black),

              // Blocks
              ...blocks.map((block) {
                final colorIndex = block.colorIndex;
                return Positioned(
                  top: block.y + 50,
                  left: block.x - 15,
                  child: Container(
                    width: 56,
                    height: 25,
                    decoration: BoxDecoration(
                      color: blockColors[colorIndex],
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: const Offset(2, 2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Ball
              Positioned(
                top: ball.y - ball.radius,
                left: ball.x - ball.radius,
                child: Container(
                  width: ball.radius * 2,
                  height: ball.radius * 2,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF69B4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Paddle
              Positioned(
                bottom: 150,
                left: paddleX,
                child: Container(
                  width: paddleWidth,
                  height: paddleHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFADD8E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // HUD
              Positioned(
                top: 50,
                left: 20,
                right: 10,
                child: Column(
                  children: [
                    Row(children: [
                      Text('BOUNCER',
                          style: GoogleFonts.cherryCreamSoda(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.pause, size: 30, color: Colors.white),
                          onPressed: () => setState(() => paused = !paused)),
                      IconButton(
                          icon: Icon(soundOn ? Icons.volume_up : Icons.volume_off,
                              size: 30, color: Colors.white),
                          onPressed: () => setState(() => soundOn = !soundOn)),
                    ]),
                    Text('Tilt device to bounce ball and clear blocks!',
                        style: GoogleFonts.poppins(color: Colors.white)),
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.sports_esports_outlined,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 5),
                      Text('Score: $score',
                          style: GoogleFonts.poppins(color: Colors.white)),
                      const Spacer(),
                      Text('Blocks: ${blocks.length}',
                          style: GoogleFonts.poppins(color: Colors.white)),
                    ]),
                  ],
                ),
              ),

              // Game Over Overlay
              if (gameWon || gameLost)
                Positioned.fill(
                  child: Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            gameWon ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
                            size: 80,
                            color: gameWon ? Colors.amber : Colors.orangeAccent,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            gameWon ? 'You Won!' : 'You Lost!',
                            style: GoogleFonts.cherryCreamSoda(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: restart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Restart',
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
