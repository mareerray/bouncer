import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bouncer_blocks.dart';

class BouncerGame extends StatefulWidget {
  const BouncerGame({super.key});

  @override
  State<BouncerGame> createState() => _BouncerGameState();
}

class _BouncerGameState extends State<BouncerGame> with TickerProviderStateMixin{
  double paddleX = 180.0; // Paddle start position
  double screenWidth = 400.0;
  double screenHeight = 800.0;
  double ballX = 200.0;
  double ballY = 400.0;
  double vx = 4.0; // horizontal speed
  double vy = 5.0; // vertical speed, positive=down
  late AnimationController _controller;
  final double ballRadius = 10.0;
  final double paddleHeight = 20.0;

  double targetPaddleX = 200.0;  // Smooth target
  double lastTilt = 0.0;  // For smoothing
  static const double sensitivity = 200.0;  // Tune: higher=faster response
  static const double smoothing = 0.25;  // 0.1=smooth, 0.3=quick, 0.5=instant

  late StreamSubscription<UserAccelerometerEvent> accelSubscription;
  final double speed = 15.0; // How fast paddle moves

  double accumulatedTime = 0.0;
  final double fixedDeltaTime = 1/60.0; // ~16ms per frame

  late AudioPlayer sfxPlayer;
  bool soundOn = true;
  bool paused = false;
  int score = 0;
  
  late List<Map<String, dynamic>> blocks; // ← now late, created in initState
  final List<Color> blockColors = createBouncerBlockColors(); // colors from helper
  
  bool gameWon = false;
  bool gameLost = false;

  // ======== ====== Game initialize ======== ========

  @override
  void initState() {
    super.initState();

    sfxPlayer = AudioPlayer();
    blocks = createBouncerBlocks(); // Initialize blocks from helper function

    // Get screen size first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        screenWidth = size.width;
        screenHeight = size.height;
      });
    });

    accelSubscription = userAccelerometerEventStream().listen
      ((UserAccelerometerEvent event) {
      if (!paused && !gameWon && !gameLost) {
        lastTilt = lastTilt * 0.7 + event.x * 0.3;  // Low-pass filter (smooths noise)
        
        // 1. ignore small noise (deadzone)
        if (event.x.abs() < 0.1) {  // Deadzone: ignore tiny noise (tune 0.08-0.15)
          return;  // Skip updating target
        }
        
        // 2. use same sensitivity on left and right
        double adjustedTilt = lastTilt;

        // 3. convert tilt into paddle target
        targetPaddleX = (screenWidth / 2) + (adjustedTilt * sensitivity);
        targetPaddleX = targetPaddleX.clamp(0.0, screenWidth - 150.0);

      }
    });

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1), // ignored for game
    )..repeat(); // loop forever

    _controller.addListener(() {
      final delta = 1/60.0; // Approximate frame delta
      accumulatedTime += delta;
      while (accumulatedTime >= fixedDeltaTime) {
        updatePositions(fixedDeltaTime);
        accumulatedTime -= fixedDeltaTime;
      }
      setState(() {}); // Update UI every frame
    });
  }

  // ======== ====== Game logic ======== ========

  void updatePositions(double dt) {
    if (paused || gameWon || gameLost) return;

    // SMOOTH PADDLE - moves towards target each frame, creating a natural feel
    paddleX += (targetPaddleX - paddleX) * smoothing;
    paddleX = paddleX.clamp(0.0, screenWidth - 150.0);

    // 1. BLOCKS LOOP backward to safely remove blocks while iterating
    bool hitBlock = false; // To prevent multiple hits in one frame

    for (int i = blocks.length - 1; i >= 0 && !hitBlock; i--) {
      final block = blocks[i];
      final drawX = block['x']! - 15; 
      final drawY = block['y']! + 50;
      final blockLeft = drawX;
      final blockRight = drawX + 55;
      final blockTop = drawY;
      final blockBottom = drawY + 25;
      
      // ANY OVERLAP = hit (ball radius included)
      final hitMargin = 0.8 * ballRadius;

      if ((ballX + hitMargin > blockLeft &&
          ballX - hitMargin < blockRight) &&
          (ballY + hitMargin > blockTop &&
          ballY - hitMargin < blockBottom)) {
        // Bounce direction: closer to side hit
        final centerX = (blockLeft + blockRight) / 2;
        final centerY = (blockTop + blockBottom) / 2;
        final dx = (ballX - centerX).abs();
        final dy = (ballY - centerY).abs();
        
        if (dx > dy) {
          vy = -vy;  // Horizontal-ish hit (top/bottom)
        } else {
          vx = -vx;  // Vertical-ish hit (sides)
        }
        
        blocks.removeAt(i);
        // setState(() {}); // Update UI immediately after block removal 
        score += 10;
        if (soundOn) sfxPlayer.play(AssetSource('sounds/destroy.wav'));
        hitBlock = true;
        break;  
      }
    }

    // 2. PADDLE COLLISION 
    final paddleLeft = paddleX;
    final paddleRight = paddleX + 150; 
    final paddleTop = screenHeight - 180; // 150 + 30 (paddle height) = 180
    final paddleBottom = screenHeight - 150; 

    if (ballY + ballRadius >= paddleTop && 
        ballY <= paddleBottom + ballRadius * 2 &&  
        ballX + ballRadius >= paddleLeft && 
        ballX - ballRadius <= paddleRight) {

      ballY = paddleTop - ballRadius - 2.5;  
      final paddleCenter = paddleX + 75;
      final hitPos = (ballX - paddleCenter) / 75.0;
      
      vy = -vy.abs() * 1.08;  // Fixed syntax + faster bounce
      vx = hitPos * 8.0;  // Sharper angles
    }

    // 3. CEILING COLLISION - prevents ball from getting stuck in blocks
    final playTop = 150.0;
    if (ballY <= playTop) {
      vy = -vy;
      ballY = playTop + ballRadius;
    }

    // 4. MOVE BALL (post-collision)
    ballX += vx * dt * 60;
    ballY += vy * dt * 60;

    // 5. SPEED CAP - keeps paddle boost but prevents runaway
    final maxSpeed = 12.0;
    final speed = sqrt(vx * vx + vy * vy);

    // Cap downward speed before row 3
    if (vy > 7.5) vy = 7.5; // vy=7.5px/frame < 25px block = no tunnel

    if (speed > maxSpeed) {
      vx = vx * (maxSpeed / speed);
      vy = vy * (maxSpeed / speed);
    }

    // 6. WALLS + FRAME COLLISION (push ball fully inside)
    // LEFT / RIGHT
    final ballLeft = ballX;
    final ballRight = ballX + ballRadius * 2;

    if (ballLeft <= 0) {
      ballX = 0;                    // push to left edge
      vx = -vx;
    } else if (ballRight >= screenWidth) {
      ballX = screenWidth - ballRadius * 2;  // push to right edge
      vx = -vx;
    }

    // TOP (bounce)
    if (ballY <= 0) {
      ballY = 0;
      vy = -vy;
    }

    // 7. WIN/LOSE MESSAGES (after blocks change)
    // do NOT bounce at bottom; just detect lose
    if (ballY + ballRadius * 2 >= screenHeight && !gameLost) {
      // ball touched bottom edge
      if (soundOn) sfxPlayer.play(AssetSource('sounds/youlost.mp3'));
      gameLost = true;
      return;
    }

    if (blocks.isEmpty && !gameWon) {
      if (soundOn) sfxPlayer.play(AssetSource('sounds/youwin.mp3'));
      gameWon = true;
    } 
  }
  

  // ======== ====== Game restart ======== ========

  void restart() {
    sfxPlayer.stop();

    setState(() {  
      blocks = createBouncerBlocks(); // Reset blocks from helper function
      accumulatedTime = 0.0;
      score = 0;
      gameWon = false;
      gameLost = false;
      ballX = screenWidth / 2;
      ballY = 400.0;
      vx = 3.0;
      vy = 4.0;
      paddleX = screenWidth / 2 - 50;
    });
  }

  @override
  void dispose() {
    accelSubscription.cancel();
    _controller.dispose();
    sfxPlayer.dispose();
    super.dispose();
  }

  // ======== ====== UI build ======== ========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          screenWidth = constraints.maxWidth;
          screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              // Game background
              Container(color: Colors.black),

              // Game Element: Colorful Blocks 
              ...blocks.map((block) {
                final rawIndex = block['colorIndex'];
                final colorIndex = rawIndex is num ? rawIndex.toInt() : 0;

                return Positioned(
                  top: block['y']! + 50,
                  left: block['x']! - 15,
                  child: Container(
                    width: 56,
                    height: 25,
                    decoration: BoxDecoration(
                      color: blockColors[colorIndex],
                      borderRadius: BorderRadius.circular(3),
                      // border: Border.all(color: Colors.white, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Game Element: Ball
              Positioned(
                top: ballY,
                left: ballX,
                child: Container(
                  width: ballRadius * 2,
                  height: ballRadius * 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF69B4), 
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Game Element: Paddle
              Positioned(
                bottom: 150,
                left: paddleX,
                child: Container(
                  width: 150,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFADD8E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // HUD: Score, blocks left, tilt, pause/sound buttons
              Positioned(
                top: 50,
                left: 20,
                right: 10,
                child: Column(
                  children: [
                    Row(  // Title + pause + sound
                      children: [
                        Text('BOUNCER', 
                        style: GoogleFonts.cherryCreamSoda(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                        ),                        Spacer(),
                        IconButton(icon: Icon(Icons.pause, size: 30, color: Colors.white), 
                          onPressed: () => setState(() => paused = !paused)),
                        IconButton(icon: Icon(soundOn ? Icons.volume_up : Icons.volume_off, size: 30, color: Colors.white,), 
                          onPressed: () => setState(() => soundOn = !soundOn)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Tilt device to bounce ball and clear blocks!', 
                          style: GoogleFonts.poppins(color: Colors.white)
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.sports_esports_outlined, size: 18, color: Colors.white),
                        SizedBox(width: 5),
                        Text('Score: $score | Blocks: ${blocks.length}', 
                          style: GoogleFonts.poppins(color: Colors.white)
                        ),
                        // Spacer(),
                        // Text('Tilt: ${lastTilt.toStringAsFixed(1)} P:${paddleX.toStringAsFixed(0)}', 
                        //   style: GoogleFonts.poppins(color: Colors.white)
                        // ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),

              // Win/Lose overlay + Restart button
              if (gameWon || gameLost)
                Positioned.fill(
                  child: Container(
                    color: Colors.black87,  // Semi-dark overlay
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            gameWon ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
                            size: 80,
                            color: gameWon ? Colors.amber : Colors.orangeAccent,
                          ),
                          SizedBox(height: 15),
                          Text(
                            gameWon ? 'You Won!' : 'You Lost!',
                            style: GoogleFonts.cherryCreamSoda(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: restart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: 
                              Text(
                                'Restart', 
                                style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
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