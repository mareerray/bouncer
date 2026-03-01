// bouncer_blocks.dart
import 'dart:ui';

List<Map<String, dynamic>> createBouncerBlocks() {
  return [
    {'x': 20.0, 'y': 100.0, 'colorIndex': 0}, {'x': 80.0, 'y': 100.0, 'colorIndex': 1}, {'x': 140.0, 'y': 100.0, 'colorIndex': 2}, {'x': 200.0, 'y': 100.0, 'colorIndex': 3}, {'x': 260.0, 'y': 100.0, 'colorIndex': 4}, {'x': 320.0, 'y': 100.0, 'colorIndex': 5},
    {'x': 20.0, 'y': 130.0, 'colorIndex': 6}, {'x': 80.0, 'y': 130.0, 'colorIndex': 7}, {'x': 140.0, 'y': 130.0, 'colorIndex': 0}, {'x': 200.0, 'y': 130.0, 'colorIndex': 1}, {'x': 260.0, 'y': 130.0, 'colorIndex': 2}, {'x': 320.0, 'y': 130.0, 'colorIndex': 3},
    {'x': 20.0, 'y': 160.0, 'colorIndex': 4}, {'x': 80.0, 'y': 160.0, 'colorIndex': 5}, {'x': 140.0, 'y': 160.0, 'colorIndex': 6}, {'x': 200.0, 'y': 160.0, 'colorIndex': 7}, {'x': 260.0, 'y': 160.0, 'colorIndex': 0}, {'x': 320.0, 'y': 160.0, 'colorIndex': 1},
    {'x': 20.0, 'y': 190.0, 'colorIndex': 6}, {'x': 80.0, 'y': 190.0, 'colorIndex': 7}, {'x': 140.0, 'y': 190.0, 'colorIndex': 0}, {'x': 200.0, 'y': 190.0, 'colorIndex': 1}, {'x': 260.0, 'y': 190.0, 'colorIndex': 2}, {'x': 320.0, 'y': 190.0, 'colorIndex': 3},
    {'x': 20.0, 'y': 220.0, 'colorIndex': 4}, {'x': 80.0, 'y': 220.0, 'colorIndex': 5}, {'x': 140.0, 'y': 220.0, 'colorIndex': 6}, {'x': 200.0, 'y': 220.0, 'colorIndex': 7}, {'x': 260.0, 'y': 220.0, 'colorIndex': 0}, {'x': 320.0, 'y': 220.0, 'colorIndex': 1},
    {'x': 20.0, 'y': 250.0, 'colorIndex': 2}, {'x': 80.0, 'y': 250.0, 'colorIndex': 3}, {'x': 140.0, 'y': 250.0, 'colorIndex': 4}, {'x': 200.0, 'y': 250.0, 'colorIndex': 5}, {'x': 260.0, 'y': 250.0, 'colorIndex': 6}, {'x': 320.0, 'y': 250.0, 'colorIndex': 7},
    {'x': 20.0, 'y': 280.0, 'colorIndex': 1}, {'x': 80.0, 'y': 280.0, 'colorIndex': 2}, {'x': 140.0, 'y': 280.0, 'colorIndex': 3}, {'x': 200.0, 'y': 280.0, 'colorIndex': 4}, {'x': 260.0, 'y': 280.0, 'colorIndex': 5}, {'x': 320.0, 'y': 280.0, 'colorIndex': 6},
  ];
}

List<Color> createBouncerBlockColors() {
  return [
    const Color(0xFF4682B4), // 0 steel blue
    const Color(0xFF32CD32), // 1 lime green
    const Color(0xFFFF4500), // 2 orange red
    const Color(0xFF9932CC), // 3 dark orchid
    const Color(0xFFFFD700), // 4 gold
    const Color(0xFF00CED1), // 5 dark turquoise
    const Color(0xFFDC143C), // 6 crimson
    const Color(0xFF20B2AA), // 7 light sea green
  ];
}


  // List<Map<String, double>> blocks = [
  //   // {'x': 20.0, 'y': 100.0}, {'x': 80.0, 'y': 100.0}, {'x': 140.0, 'y': 100.0}, {'x': 200.0, 'y': 100.0}, {'x': 260.0, 'y': 100.0}, {'x': 320.0, 'y': 100.0},
  //   // {'x': 20.0, 'y': 130.0}, {'x': 80.0, 'y': 130.0}, {'x': 140.0, 'y': 130.0}, {'x': 200.0, 'y': 130.0}, {'x': 260.0, 'y': 130.0}, {'x': 320.0, 'y': 130.0},
  //   // {'x': 20.0, 'y': 160.0}, {'x': 80.0, 'y': 160.0}, {'x': 140.0, 'y': 160.0}, {'x': 200.0, 'y': 160.0}, {'x': 260.0, 'y': 160.0}, {'x': 320.0, 'y': 160.0},
  //   // {'x': 20.0, 'y': 190.0}, {'x': 80.0, 'y': 190.0}, {'x': 140.0, 'y': 190.0}, {'x': 200.0, 'y': 190.0}, {'x': 260.0, 'y': 190.0}, {'x': 320.0, 'y': 190.0},
  //   // {'x': 20.0, 'y': 220.0}, {'x': 80.0, 'y': 220.0}, {'x': 140.0, 'y': 220.0}, {'x': 200.0, 'y': 220.0}, {'x': 260.0, 'y': 220.0}, {'x': 320.0, 'y': 220.0}
  //   {'x': 20.0, 'y': 160.0, 'colorIndex': 0}, {'x': 80.0, 'y': 160.0, 'colorIndex': 1}, {'x': 140.0, 'y': 160.0, 'colorIndex': 2}, {'x': 200.0, 'y': 160.0, 'colorIndex': 3}, {'x': 260.0, 'y': 160.0, 'colorIndex': 4}, {'x': 320.0, 'y': 160.0, 'colorIndex': 5},
  //   {'x': 20.0, 'y': 190.0, 'colorIndex': 6}, {'x': 80.0, 'y': 190.0, 'colorIndex': 7}, {'x': 140.0, 'y': 190.0, 'colorIndex': 0}, {'x': 200.0, 'y': 190.0, 'colorIndex': 1}, {'x': 260.0, 'y': 190.0, 'colorIndex': 2}, {'x': 320.0, 'y': 190.0, 'colorIndex': 3},
  //   {'x': 20.0, 'y': 220.0, 'colorIndex': 4}, {'x': 80.0, 'y': 220.0, 'colorIndex': 5}, {'x': 140.0, 'y': 220.0, 'colorIndex': 6}, {'x': 200.0, 'y': 220.0, 'colorIndex': 7}, {'x': 260.0, 'y': 220.0, 'colorIndex': 0}, {'x': 320.0, 'y': 220.0, 'colorIndex': 1},
  //   {'x': 20.0, 'y': 250.0, 'colorIndex': 2}, {'x': 80.0, 'y': 250.0, 'colorIndex': 3}, {'x': 140.0, 'y': 250.0, 'colorIndex': 4}, {'x': 200.0, 'y': 250.0, 'colorIndex': 5}, {'x': 260.0, 'y': 250.0, 'colorIndex': 6}, {'x': 320.0, 'y': 250.0, 'colorIndex': 7},
  //   {'x': 20.0, 'y': 280.0, 'colorIndex': 1}, {'x': 80.0, 'y': 280.0, 'colorIndex': 2}, {'x': 140.0, 'y': 280.0, 'colorIndex': 3}, {'x': 200.0, 'y': 280.0, 'colorIndex': 4}, {'x': 260.0, 'y': 280.0, 'colorIndex': 5}, {'x': 320.0, 'y': 280.0, 'colorIndex': 6}

  // ];
