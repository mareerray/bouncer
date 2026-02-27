import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/scheduler.dart';
import 'package:audioplayers/audioplayers.dart';

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
  double vx = 3.0; // horizontal speed
  double vy = 4.0; // vertical speed, positive=down
  late AnimationController _controller;
  final double ballRadius = 10.0;
  final double paddleHeight = 20.0;

  late StreamSubscription<UserAccelerometerEvent> accelSubscription;
  final double speed = 20.0; // How fast paddle moves

  double accumulatedTime = 0.0;
  final double fixedDeltaTime = 1/60.0; // ~16ms per frame

  late AudioPlayer sfxPlayer;
  bool soundOn = true;
  bool paused = false;
  int score = 0;


  List<Map<String, double>> blocks = [
    {'x': 20.0, 'y': 80.0}, {'x': 80.0, 'y': 80.0}, {'x': 140.0, 'y': 80.0}, {'x': 200.0, 'y': 80.0}, {'x': 260.0, 'y': 80.0},
    {'x': 20.0, 'y': 110.0}, {'x': 80.0, 'y': 110.0}, {'x': 140.0, 'y': 110.0}, {'x': 200.0, 'y': 110.0}, {'x': 260.0, 'y': 110.0},
    {'x': 20.0, 'y': 140.0}, {'x': 80.0, 'y': 140.0}, {'x': 140.0, 'y': 140.0}, {'x': 200.0, 'y': 140.0}, {'x': 260.0, 'y': 140.0},
    {'x': 20.0, 'y': 170.0}, {'x': 80.0, 'y': 170.0}, {'x': 140.0, 'y': 170.0}, {'x': 200.0, 'y': 170.0}, {'x': 260.0, 'y': 170.0},
    {'x': 20.0, 'y': 200.0}, {'x': 80.0, 'y': 200.0}, {'x': 140.0, 'y': 200.0}, {'x': 200.0, 'y': 200.0}, {'x': 260.0, 'y': 200.0},
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
      if (!gameWon && !gameLost) {
        paddleX += event.x * speed; // tilt left/right to move
        paddleX = paddleX.clamp(0.0, screenWidth - 100.0); 

        SchedulerBinding.instance.scheduleFrameCallback((_) {
          setState(() {});  // Triggers UI update on next frame
        });
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

    ballX += vx * dt * 60; // Scale back to original speed (vx=3 moves ~3 pixels/frame)
    ballY += vy * dt * 60;

    // Walls
    if (ballX <= 0 || ballX >= screenWidth - ballRadius * 2) vx = -vx;
    if (ballY <= 0) vy = -vy;

    final paddleLeft = paddleX;  // left=paddleX, width=100
    final paddleRight = paddleX + 100;
    final paddleTop = screenHeight - 170;  // bottom:150 + height:20
    final paddleBottom = screenHeight - 150;

    // Paddle collision: check if ball hits the paddle rectangle
    if (ballY + ballRadius >= paddleTop && 
        ballY - ballRadius <= paddleBottom &&  
        ballX + ballRadius >= paddleLeft && 
        ballX - ballRadius <= paddleRight) {

          // Bounce up, treat paddle as horizontal surface + angle offset
          vy = -vy;

      // Horizontal angle from hit position (law of reflection)
      final paddleCenter = paddleX + 50;
      final relativeHit = (ballX - paddleCenter) / 50;  // -1 (left) to +1 (right)
      vx = 3.0 + relativeHit * 4.0;  // vx changes by hit spot (-1 to +7)

      // Push ball up a bit (prevent sticking)
      ballY = paddleTop - ballRadius - 1;

      // Bonus: angle based on hit position
      // final hitPos = (ballX - paddleLeft) / 100 - 0.5;  // -0.5 to 0.5
      // vx += hitPos * 2;  // Slight angle change
    }

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
      if (ballX + ballRadius > blockLeft &&
          ballX - ballRadius < blockRight &&
          ballY + ballRadius > blockTop &&
          ballY - ballRadius < blockBottom) {
        
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
      gameWon = true;
    } 
    if (ballY >= screenHeight - 170) {
      gameLost = true;
    }
  }
  

  // ======== ====== Game restart ======== ========

  void restart() {
    setState(() {  
      blocks = [
        {'x': 20.0, 'y': 80.0}, {'x': 80.0, 'y': 80.0}, {'x': 140.0, 'y': 80.0}, {'x': 200.0, 'y': 80.0}, {'x': 260.0, 'y': 80.0},
        {'x': 20.0, 'y': 110.0}, {'x': 80.0, 'y': 110.0}, {'x': 140.0, 'y': 110.0}, {'x': 200.0, 'y': 110.0}, {'x': 260.0, 'y': 110.0},
        {'x': 20.0, 'y': 140.0}, {'x': 80.0, 'y': 140.0}, {'x': 140.0, 'y': 140.0}, {'x': 200.0, 'y': 140.0}, {'x': 260.0, 'y': 140.0},
        {'x': 20.0, 'y': 170.0}, {'x': 80.0, 'y': 170.0}, {'x': 140.0, 'y': 170.0}, {'x': 200.0, 'y': 170.0}, {'x': 260.0, 'y': 170.0},
        {'x': 20.0, 'y': 200.0}, {'x': 80.0, 'y': 200.0}, {'x': 140.0, 'y': 200.0}, {'x': 200.0, 'y': 200.0}, {'x': 260.0, 'y': 200.0},


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
                  left: block['x']!+15,
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
                right: 20,
                child: Column(
                  children: [
                    Row(  // Title + pause + sound
                      children: [
                        Text('BOUNCER', style: TextStyle(color: Colors.white, fontSize: 24)),
                        Spacer(),
                        IconButton(icon: Icon(Icons.pause, size: 30, color: Colors.white), onPressed: () => setState(() => paused = !paused)),
                        IconButton(icon: Icon(soundOn ? Icons.volume_up : Icons.volume_off, size: 30, color: Colors.white,), 
                          onPressed: () => setState(() => soundOn = !soundOn)),
                      ],
                    ),
                    Text('Score: $score | Blocks: ${blocks.length}', style: TextStyle(color: Colors.white)),
                    Text('Tilt: ${paddleX.toStringAsFixed(0)}'),
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
                            style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: restart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Restart', style: TextStyle(fontSize: 18)),
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