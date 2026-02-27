import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';

class BouncerGame extends StatefulWidget {
  const BouncerGame({super.key});

  @override
  State<BouncerGame> createState() => _BouncerGameState();
}

class _BouncerGameState extends State<BouncerGame> with TickerProviderStateMixin{
  double paddleX = 200.0; // Paddle start position
  double screenWidth = 400.0;
  double screenHeight = 800.0;
  double ballX = 220.0;
  double ballY = 220.0;
  double vx = 4.0; // horizontal speed
  double vy = 5.0; // vertical speed, positive=down
  late AnimationController _controller;
  final double ballRadius = 10.0;
  final double paddleHeight = 20.0;

  double targetPaddleX = 200.0;  // Smooth target
  double lastTilt = 0.0;  // For smoothing
  static const double sensitivity = 150.0;  // Tune: higher=faster response
  static const double smoothing = 0.15;  // 0.1=smooth, 0.3=responsive

  late StreamSubscription<UserAccelerometerEvent> accelSubscription;
  final double speed = 15.0; // How fast paddle moves

  double accumulatedTime = 0.0;
  final double fixedDeltaTime = 1/60.0; // ~16ms per frame

  late AudioPlayer sfxPlayer;
  bool soundOn = true;
  bool paused = false;
  int score = 0;

  List<Map<String, double>> blocks = [
    {'x': 20.0, 'y': 100.0}, {'x': 80.0, 'y': 100.0}, {'x': 140.0, 'y': 100.0}, {'x': 200.0, 'y': 100.0}, {'x': 260.0, 'y': 100.0}, {'x': 320.0, 'y': 100.0},
    {'x': 20.0, 'y': 130.0}, {'x': 80.0, 'y': 130.0}, {'x': 140.0, 'y': 130.0}, {'x': 200.0, 'y': 130.0}, {'x': 260.0, 'y': 130.0}, {'x': 320.0, 'y': 130.0},
    {'x': 20.0, 'y': 160.0}, {'x': 80.0, 'y': 160.0}, {'x': 140.0, 'y': 160.0}, {'x': 200.0, 'y': 160.0}, {'x': 260.0, 'y': 160.0}, {'x': 320.0, 'y': 160.0},
    {'x': 20.0, 'y': 190.0}, {'x': 80.0, 'y': 190.0}, {'x': 140.0, 'y': 190.0}, {'x': 200.0, 'y': 190.0}, {'x': 260.0, 'y': 190.0}, {'x': 320.0, 'y': 190.0},
    {'x': 20.0, 'y': 220.0}, {'x': 80.0, 'y': 220.0}, {'x': 140.0, 'y': 220.0}, {'x': 200.0, 'y': 220.0}, {'x': 260.0, 'y': 220.0}, {'x': 320.0, 'y': 220.0}
  ];
  
  bool gameWon = false;
  bool gameLost = false;

  // ======== ====== Game initialize ======== ========

  @override
  void initState() {
    super.initState();

    sfxPlayer = AudioPlayer();

    // Get screen size first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        screenWidth = size.width;
        screenHeight = size.height;
      });
    });

    accelSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      if (!paused && !gameWon && !gameLost) {
        lastTilt = event.x;

        if (event.x.abs() < 0.1) {  // Deadzone: ignore tiny noise (tune 0.08-0.15)
          return;  // Skip updating target
        }

        // Non-linear: boost left (-), tame right (+)
        double tiltInput = event.x;
        double adjustedTilt = tiltInput < 0 
          ? tiltInput * 1.5  // 50% more sensitive LEFT
          : tiltInput * 0.8; // Tame RIGHT overshoot
        // Map tilt: event.x negative=left, positive=right
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

  // SMOOTH PADDLE (keep first)
  paddleX += (targetPaddleX - paddleX) * smoothing;
  paddleX = paddleX.clamp(0.0, screenWidth - 150.0);
  
  // PADDLE COLLISION FIRST (before ball moves!)
  final paddleLeft = paddleX;
  final paddleRight = paddleX + 150;
  final paddleTop = screenHeight - 180;
  final paddleBottom = screenHeight - 150;

  if (ballY + ballRadius >= paddleTop && 
      ballY <= paddleBottom + ballRadius * 2 &&  // Wider hit window
      ballX + ballRadius >= paddleLeft && 
      ballX - ballRadius <= paddleRight) {

    ballY = paddleTop - ballRadius - 3;  // HARSH pushback FIRST
    final paddleCenter = paddleX + 75;
    final hitPos = (ballX - paddleCenter) / 75.0;
    
    vy = -vy.abs() * 1.08;  // Fixed syntax + faster bounce
    vx = hitPos * 8.0;  // Sharper angles
  }

  final playTop = 220.0;
  if (ballY <= playTop) {
    vy = -vy;
    ballY = playTop + ballRadius;
  }

  // NOW move ball (post-collision)
  ballX += vx * dt * 60;
  ballY += vy * dt * 60;

  // SPEED CAP - keeps paddle boost but prevents runaway
  final maxSpeed = 12.0;
  final speed = sqrt(vx * vx + vy * vy);
  if (speed > maxSpeed) {
    vx = vx * (maxSpeed / speed);
    vy = vy * (maxSpeed / speed);
  }

  // Walls + Frame 
  if (ballX <= 0 || ballX >= screenWidth - ballRadius * 2) vx = -vx;
  if (ballY <= 0) vy = -vy;

    // Blocks loops backward to safely remove blocks while iterating
    // Replace block loop:

    for (int i = blocks.length - 1; i >= 0; i--) {
      final block = blocks[i];
      final bx = block['x']!;
      final by = block['y']!;
      final blockLeft = bx;
      final blockRight = bx + 55;
      final blockTop = by;
      final blockBottom = by + 25;
      
      // ANY OVERLAP = hit (ball radius included)
      final hitMargin = 1.5 * ballRadius;
      if (ballX + hitMargin > blockLeft &&
          ballX - hitMargin < blockRight &&
          ballY + hitMargin > blockTop &&
          ballY - hitMargin < blockBottom) {
        
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
        score += 10;
        if (soundOn) sfxPlayer.play(AssetSource('sounds/destroy.wav'));
        break;  // One block per frame
      }
    }
    if (blocks.isEmpty) {
      if (soundOn) sfxPlayer.play(AssetSource('sounds/youwin.mp3'));
      gameWon = true;
    } 
    if (ballY >= screenHeight - 170) {
      // if (soundOn) sfxPlayer.play(AssetSource('sounds/youlost.mp3'));
      gameLost = true;
    }
  }
  

  // ======== ====== Game restart ======== ========

  void restart() {
    sfxPlayer.stop();

    setState(() {  
      blocks = [
        {'x': 20.0, 'y': 100.0}, {'x': 80.0, 'y': 100.0}, {'x': 140.0, 'y': 100.0}, {'x': 200.0, 'y': 100.0}, {'x': 260.0, 'y': 100.0}, {'x': 320.0, 'y': 100.0},
        {'x': 20.0, 'y': 130.0}, {'x': 80.0, 'y': 130.0}, {'x': 140.0, 'y': 130.0}, {'x': 200.0, 'y': 130.0}, {'x': 260.0, 'y': 130.0}, {'x': 320.0, 'y': 130.0},
        {'x': 20.0, 'y': 160.0}, {'x': 80.0, 'y': 160.0}, {'x': 140.0, 'y': 160.0}, {'x': 200.0, 'y': 160.0}, {'x': 260.0, 'y': 160.0}, {'x': 320.0, 'y': 160.0},
        {'x': 20.0, 'y': 190.0}, {'x': 80.0, 'y': 190.0}, {'x': 140.0, 'y': 190.0}, {'x': 200.0, 'y': 190.0}, {'x': 260.0, 'y': 190.0}, {'x': 320.0, 'y': 190.0},
        {'x': 20.0, 'y': 220.0}, {'x': 80.0, 'y': 220.0}, {'x': 140.0, 'y': 220.0}, {'x': 200.0, 'y': 220.0}, {'x': 260.0, 'y': 220.0}, {'x': 320.0, 'y': 220.0}
      ];    
      accumulatedTime = 0.0;
      score = 0;
      gameWon = false;
      gameLost = false;
      ballX = screenWidth / 2;
      ballY = 300.0;
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
          // Clamp: keep paddle on screen like a ball in a box
          paddleX = paddleX.clamp(0.0, screenWidth - 150.0);
          return Stack(
            children: [
              // Game background
              Container(color: Colors.black),

              // Game Element: Colorful Blocks 
              ...blocks.map((block) {
                final colors = [
                  const Color(0xFF4682B4), // steel blue
                  const Color(0xFF32CD32), // lime green  
                  const Color(0xFFFF4500), // orange red
                  const Color(0xFF9932CC), // dark orchid
                  const Color(0xFFFFD700), // gold
                  const Color(0xFF00CED1), // dark turquoise
                  const Color(0xFFDC143C), // crimson
                  const Color(0xFF20B2AA), // light sea green
                ];
                final color = colors[blocks.indexOf(block) % colors.length];
                return Positioned(
                  top: block['y']! + 50,
                  left: block['x']! - 15,
                  child: Container(
                    width: 55,
                    height: 25,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white, width: 1),
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
                    color: const Color(0xFFFF69B4), // pink color
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
                top: 40,
                left: 20,
                right: 10,
                child: Column(
                  children: [
                    Row(  // Title + pause + sound
                      children: [
                        Text('BOUNCER', style: GoogleFonts.cherryCreamSoda(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Spacer(),
                        IconButton(icon: Icon(Icons.pause, size: 30, color: Colors.white), onPressed: () => setState(() => paused = !paused)),
                        IconButton(icon: Icon(soundOn ? Icons.volume_up : Icons.volume_off, size: 30, color: Colors.white,), 
                          onPressed: () => setState(() => soundOn = !soundOn)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.sports_esports_outlined, size: 18, color: Colors.white),
                        SizedBox(width: 5),
                        Text('Score: $score | Blocks: ${blocks.length}', style: GoogleFonts.poppins(color: Colors.white)),
                        Spacer(),
                        Text('Tilt: ${lastTilt.toStringAsFixed(1)} P:${paddleX.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white)),

                      ],
                    ),
                  ],
                ),
              ),

              // Win/Lose messages + Restart button
              if (gameWon || gameLost)
                Positioned.fill(
                  child: Container(
                    color: Colors.black87,  // Semi-dark overlay
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                            child: Text('Restart', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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