import 'dart:math';

import 'package:animated_painter/animated_painter.dart';
import 'package:flutter/material.dart';

class SpreadSimulator extends StatefulWidget {
  @override
  _SpreadSimulatorState createState() => _SpreadSimulatorState();
}

class _SpreadSimulatorState extends State<SpreadSimulator> {
  SpreadSimulatorPainter painter;
  @override
  void initState() {
    painter = SpreadSimulatorPainter();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPaint(painter: painter);
  }
}

class SpreadSimulatorPainter extends AnimatedPainter {
  final double diseaseTime;

  int lastTime = DateTime.now().millisecondsSinceEpoch;
  Field field = Field();

  SpreadSimulatorPainter({this.diseaseTime = 5});
  @override
  void init() {}

  @override
  void paint(Canvas canvas, Size size) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final deltaTime = (currentTime - lastTime) / 1000.0;
    lastTime = currentTime;

    field
      ..step(deltaTime)
      ..paint(canvas, size);
  }
}

class Field {
  final double diseaseTime;
  final int count;

  List<Particle> particles;

  Field({this.diseaseTime = 5, this.count = 250});

  void step(double deltaTime) {
    if (particles == null) {
      particles = List.generate(
          count, (idx) => Particle()..infected = idx == 0 ? diseaseTime : null);
    }
    particles.forEach((particle) {
      particles.where((p) => p != particle).forEach((other) {
        if (particle.collision(other)) {
          /// Calculate new XS/YS after a collision
          final particleXS = (particle.xs * (particle.mass - other.mass) +
                  (2 * other.mass * other.xs)) /
              (particle.mass + other.mass);

          final particleYS = (particle.ys * (particle.mass - other.mass) +
                  (2 * other.mass * other.ys)) /
              (particle.mass + other.mass);

          final otherXs = (other.xs * (other.mass - particle.mass) +
                  (2 * particle.mass * particle.xs)) /
              (other.mass + particle.mass);

          final otherYs = (other.ys * (other.mass - particle.mass) +
                  (2 * particle.mass * particle.ys)) /
              (other.mass + particle.mass);

          particle.xs = particleXS;
          particle.ys = particleYS;
          other.xs = otherXs;
          other.ys = otherYs;
          particle.step(particle._lastDelta);
          other.step(particle._lastDelta);

          if (particle.infected != null && particle.infected > 0 ||
              other.infected != null && other.infected > 0) {
            if (particle.infected == null) particle.infected = diseaseTime;
            if (other.infected == null) other.infected = diseaseTime;
          }
        }
      });
      particle.step(deltaTime);
    });
  }

  void paint(Canvas canvas, Size size) {
    double width = min(size.width, size.height);
    double height = width;
    double offsetHeight = (size.height - height) / 2;
    double offsetWidth = (size.width - width) / 2;
    canvas.drawRect(
        Rect.fromCenter(
            width: width,
            height: height,
            center: Offset(width / 2 + offsetWidth, height / 2 + offsetHeight)),
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke);

    particles.forEach((particle) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(width * particle.x + offsetWidth,
                  height * particle.y + offsetHeight),
              width: particle.radius * width * 2,
              height: particle.radius * height * 2),
          Paint()
            ..color = particle.isDead
                ? Colors.black
                : particle.infected != null
                    ? particle.infected > 0
                        ? Colors.red
                        : Colors.blue.withAlpha(50)
                    : Colors.green);
    });
  }
}

class Particle {
  double infected = null;
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double xs = (Random().nextDouble() - 0.5) * 0.1;
  double ys = (Random().nextDouble() - 0.5) * 0.1;
  double mass = ((Random().nextDouble()) + 0.1) * 0.0005;
  double get radius => sqrt(mass / pi);
  bool willDie = Random().nextDouble() < 0.03;
  bool get isDead => infected != null && infected < 0 && willDie;
  double get momentum => sqrt(xs * xs + ys * ys);

  bool collision(Particle other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final total_radius = radius + other.radius;
    return (sqrt(dx * dx + dy * dy) < total_radius);
  }

  double _lastDelta = 0;
  void step(double deltaTime) {
    if (isDead) return;
    _lastDelta = deltaTime;
    if (infected != null) {
      infected -= deltaTime;
    }
    x += xs * deltaTime;
    y += ys * deltaTime;
    if (x > 1) {
      x = 1;
      xs *= -1;
    }
    if (y > 1) {
      y = 1;
      ys *= -1;
    }
    if (x < 0) {
      x = 0;
      xs *= -1;
    }
    if (y < 0) {
      y = 0;
      ys *= -1;
    }
  }

  void reverse() {
    xs *= -1;
    ys *= -1;
    step(_lastDelta);
  }
}
