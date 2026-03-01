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
  late AnimationController _controller;
  late AudioPlayer sfxPlayer;

  // Screen size
  double screenWidth = 400.0;
  double screenHeight = 800.0;

  // Blocks
  late List<Map<String, dynamic>> blocks; // ← created from helper function
  final List<Color> blockColors = createBouncerBlockColors(); // colors from helper

  // Ball
  double ballX = 20.0; // Start position (top-left of ball)
  double ballY = 380.0; // Start position
  final double ballRadius = 10.0;

  // Paddle
  final double paddleHeight = 20.0;
  final double paddleWidth = 180.0;
  double paddleX = 0.0; // Paddle start position (updated in initState)

  // Paddle control 
  static const double normalSensitivity = 350.0;  // How far paddle moves per tilt: higher=faster 
  static const double moreSensitivity = 400.0; // Can be adjusted for difficulty
  static const double smoothing = 0.25;  // Speed of paddle slide: 0.1=smooth, 0.3=quick, 0.5=instant

  // Ball velocity (pixels per frame)
  double vx = 4.0; // horizontal speed
  double vy = 5.0; // vertical speed, positive=down

  // Accelerometer subscription
  late StreamSubscription<UserAccelerometerEvent> accelSubscription;
  double targetPaddleX = 0.0;  // Smooth target
  double accumulatedTime = 0.0;
  final double fixedDeltaTime = 1/60.0; // ~16ms per frame
  double tilt = 0.0;  // Current tilt value for display

  bool get isGameActive => !paused && !gameWon && !gameLost;
  bool soundOn = true;
  bool paused = false;
  bool gameWon = false;
  bool gameLost = false;
  int score = 0;

  // ======== ====== Game initialize ======== ========

  @override
  void initState() {
    super.initState();
    sfxPlayer = AudioPlayer();

    // Initialize blocks from helper function
    blocks = createBouncerBlocks(); 

    // GAME START: Get screen size and set initial paddle position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        screenWidth = size.width;
        screenHeight = size.height;
        paddleX = screenWidth / 2 - paddleWidth / 2; // Center paddle
        targetPaddleX = screenWidth / 2 - paddleWidth / 2; // Center target as well
      });
    });

    // DURING GAMEPLAY: Listen to accelerometer for paddle control
    accelSubscription = userAccelerometerEventStream().listen(
      (UserAccelerometerEvent event) {
        if (!isGameActive) return;

          tilt = event.x; 
          final sensitivity = (tilt < 0) ? moreSensitivity : normalSensitivity; // More sensitivity when tilting left (negative)

                    // Very small deadzone: ignore tiny noise only
          if (tilt.abs() > 0.2) { // deadzone threshold: ignore very small tilts
             double newTarget = (screenWidth / 2) + (tilt * sensitivity);

            // SMOOTH the TARGET too! (stops jerking)
            targetPaddleX += (newTarget - targetPaddleX) * smoothing;
            targetPaddleX = targetPaddleX.clamp(0.0, screenWidth - paddleWidth);
          }
          // ← When tilt < 0.5, NOTHING HAPPENS (paddle stays still, no drift)
        
      },
    );

    // Animation for game loop (calls setState every frame)
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1), // ignored for game
    )..repeat(); // loop forever

    // Update game state on each frame, using fixed timestep for consistent physics
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
    if (!isGameActive) return;

    // SMOOTH PADDLE - moves towards target each frame, creating a natural feel
    paddleX += (targetPaddleX - paddleX) * smoothing; // Move a fraction towards target
    paddleX = paddleX.clamp(0.0, screenWidth - paddleWidth);

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

      // if collision detected, bounce based on hit position and remove block
      if ((ballX + hitMargin > blockLeft &&
          ballX - hitMargin < blockRight) &&
          (ballY + hitMargin > blockTop &&
          ballY - hitMargin < blockBottom)) {
        // Find closest edge and push ball outside
        double overlapX = 0.0;
        double overlapY = 0.0;
        
        // Horizontal push
        if (ballX < blockLeft) {
          overlapX = blockLeft - ballX;
          ballX = blockLeft - ballRadius - 1;  // Push left
        } else if (ballX > blockRight) {
          overlapX = ballX - blockRight;
          ballX = blockRight + ballRadius + 1;  // Push right
        }
        
        // Vertical push
        if (ballY < blockTop) {
          overlapY = blockTop - ballY;
          ballY = blockTop - ballRadius - 1;  // Push up
        } else if (ballY > blockBottom) {
          overlapY = ballY - blockBottom;
          ballY = blockBottom + ballRadius + 1;  // Push down
        }
        
        // Choose biggest push direction (less overlap)
        if (overlapX > overlapY) {
          vx = -vx;  // Horizontal bounce
        } else {
          vy = -vy;  // Vertical bounce
        }

        // Remove block and update score
        blocks.removeAt(i);
        score += 10;
        if (soundOn) sfxPlayer.play(AssetSource('sounds/destroy.wav'));
        hitBlock = true;
        break;  
      }
    }

    // 2. PADDLE COLLISION 
    final paddleLeft = paddleX;
    final paddleRight = paddleX + paddleWidth; 
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
    final double speedScale = 60.0;

    ballX += vx * speedScale * dt;
    ballY += vy * speedScale * dt;


    // 5. SPEED CAP - keeps paddle boost but prevents runaway
    final maxSpeed = 12.0;
    final ballSpeed = sqrt(vx * vx + vy * vy);

    // Cap downward speed before row 3
    if (vy > 7.5) vy = 7.5; // vy=7.5px/frame < 25px block = no tunnel

    if (ballSpeed > maxSpeed) {
      vx = vx * (maxSpeed / ballSpeed);
      vy = vy * (maxSpeed / ballSpeed);
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
      ballX = 20.0;
      ballY = 380.0;
      vx = 4.0;
      vy = 5.0;
      paddleX = screenWidth / 2 - paddleWidth / 2; // Center paddle
      targetPaddleX = screenWidth / 2 - paddleWidth / 2;  
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
                  width: paddleWidth,
                  height: paddleHeight,
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
                        ),
                        Spacer(),
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
                        Spacer(),
                        Text('Tilt: ${tilt.toStringAsFixed(2)}', 
                          style: GoogleFonts.poppins(color: Colors.white)
                        ),
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