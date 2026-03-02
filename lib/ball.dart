class Ball {
  double x, y, vx, vy;
  final double radius;
  
  Ball({required this.x, 
    required this.y, 
    this.vx = 4.0, 
    this.vy = 5.0, 
    this.radius = 10.0,
  });

  void move(double dt, double speedScale) {
    x += vx * speedScale * dt;
    y += vy * speedScale * dt;
  }
}
