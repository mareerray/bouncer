// bouncer_blocks.dart
import 'dart:ui';

List<Map<String, dynamic>> createBouncerBlocks() {
  final int numCols = 6;
  final int numRows = 7;
  double screenWidth = 400.0;

  final double blockWidth = 56.0;
  final double rowSpacing = 30.0;

  final List<Map<String, dynamic>> blocks = [];

  for (int row = 0; row < numRows; row++) {
    for (int col = 0; col < numCols; col++) {
      // Center the grid so nothing sticks out
      final double totalGridWidth = numCols * blockWidth;
      final double gridLeft = (screenWidth - totalGridWidth) / 2;

      final double x = gridLeft + col * blockWidth;
      final double y = 100.0 + row * rowSpacing;

      // Map color index 0–7
      final int colorIndex = (row * numCols + col) % 8;

      blocks.add({'x': x, 'y': y, 'colorIndex': colorIndex});
    }
  }

  return blocks;
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

