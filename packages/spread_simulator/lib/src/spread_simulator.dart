import 'dart:math';

import 'package:animated_painter/animated_painter.dart';
import 'package:flutter/material.dart';

const kHistorySampleSizeS = 0.5;

const kColorHealth = Colors.greenAccent;
const kColorSick = Colors.red;
const kColorDead = Colors.black;
const kColorRecovered = Colors.blue;

class SpreadSimulator extends StatefulWidget {
  @override
  _SpreadSimulatorState createState() => _SpreadSimulatorState();
}

class _SpreadSimulatorState extends State<SpreadSimulator> {
  SpreadSimulatorPainter painter;
  int particles = 300;
  double diseaseTime = 5;
  double scale = 50;
  double speed = 100;

  @override
  void initState() {
    painter = SpreadSimulatorPainter(
        diseaseTime: diseaseTime, count: particles, scale: scale, speed: speed);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text("Infection Simulator"),
        ),
        drawer: buildOptions(),
        body: SafeArea(
          child: Column(children: [
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedPaint(painter: painter),
            )),
          ]),
        ),
      );

  Widget buildOptions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
          child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 300),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Column(
                children: [
                  Text("Disease Time ${diseaseTime.round()}s"),
                  Slider(
                      onChanged: setDiseaseTime,
                      value: diseaseTime,
                      min: 1,
                      max: 30),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text("Count ${particles}"),
                  Slider(
                      onChanged: setParticleCount,
                      value: particles.toDouble(),
                      min: 50,
                      max: 1000),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text("Scale ${scale.toInt()}"),
                  Slider(onChanged: setScale, value: scale, min: 10, max: 100),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text("Speed ${speed.round()}%"),
                  Slider(onChanged: setSpeed, value: speed, min: 10, max: 100),
                ],
              ),
            ),
            FlatButton(
              onPressed: reset,
              child: Text("Reset"),
            ),
          ],
        ),
      )),
    );
  }

  void setScale(double scale) {
    setState(() {
      this.scale = scale;
    });
  }

  void setSpeed(double speed) {
    setState(() {
      this.speed = speed;
    });
  }

  void setParticleCount(double count) {
    setState(() {
      particles = count.toInt();
    });
  }

  void setDiseaseTime(double count) {
    setState(() {
      diseaseTime = count;
    });
  }

  void reset() {
    Navigator.of(context).pop();
    setState(() {
      painter = SpreadSimulatorPainter(
          diseaseTime: diseaseTime,
          count: particles,
          scale: scale,
          speed: speed);
    });
  }
}

class SpreadSimulatorPainter extends AnimatedPainter {
  final double diseaseTime;
  final int count;
  final double speed;
  final double scale;
  double statisticSampleTime = 0;

  int lastTime = DateTime.now().millisecondsSinceEpoch;
  Field field;
  final history = <Statistics>[];

  SpreadSimulatorPainter(
      {this.diseaseTime = 5, this.count = 100, this.scale = 1, this.speed = 1});

  @override
  void init() {}

  @override
  void paint(Canvas canvas, Size size) {
    if (field == null) {
      field = Field(
          diseaseTime: diseaseTime, count: count, speed: speed, scale: scale);
      field.step(2);
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final deltaTime = (currentTime - lastTime) / 1000.0;

    double width = min(size.width, size.height);
    double height = width;
    double offsetHeight = (size.height - height) / 2;
    double offsetWidth = (size.width - width) / 2;
    final bounds = Rect.fromCenter(
        width: width,
        height: height,
        center: Offset(width / 2 + offsetWidth, height / 2 + offsetHeight));
    canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, Radius.circular(32)),
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);

    canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, Radius.circular(32)),
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill
          ..strokeWidth = 4);

    canvas.clipRRect(RRect.fromRectAndRadius(bounds, Radius.circular(32)));

    lastTime = currentTime;
    drawGraph(canvas, size);
    canvas.drawRect(
        bounds,
        Paint()
          ..color = Colors.white.withOpacity(0.75)
          ..style = PaintingStyle.fill);

    field
      ..step(deltaTime)
      ..paint(canvas, size);

    final stats = Statistics(field.particles);
    if (stats.infected > 0) {
      statisticSampleTime -= deltaTime;
      if (statisticSampleTime < 0) {
        statisticSampleTime += kHistorySampleSizeS;
        history.add(stats);
      }
    }

    final tp = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text:
              "[Uninfected ${stats.uninfected}]      [Infected ${stats.infected}]      [Dead ${stats.dead}]      [Recovered ${stats.clear}]     [InfectionTime: ${(history.length * kHistorySampleSizeS).toInt()}s]",
          style: TextStyle(
              color: Colors.white,
              shadows: [
                BoxShadow(blurRadius: 4),
                BoxShadow(blurRadius: 8),
              ],
              fontSize: width / 60,
              fontWeight: FontWeight.bold),
        ))
      ..layout();

    tp.paint(canvas, Offset(offsetWidth + width / 2 - tp.size.width / 2, 12));
  }

  void drawGraph(Canvas canvas, Size size) {
    if (history.length < 4) return;

    double width = min(size.width, size.height);
    double height = width;
    double offsetHeight = (size.height - height) / 2;
    double offsetWidth = (size.width - width) / 2;
    final infectedPath = Path();
    final deadPath = Path();
    final clearPath = Path();
    int i = 0;

    final infectedPoints = <Offset>[];
    final deadPoints = <Offset>[];
    final clearPoints = <Offset>[];

    infectedPoints.add(Offset(offsetWidth, height + offsetHeight));
    deadPoints.add(Offset(offsetWidth, height + offsetHeight));
    clearPoints.add(Offset(offsetWidth, height + offsetHeight));

    history.forEach((element) {
      double p =
          i / (history.length - 1 - statisticSampleTime / kHistorySampleSizeS);
      double infectedPercent = element.infected / count;
      double deadPercent = element.dead / count;
      double clearPercent = element.clear / count;

      infectedPoints.add(Offset(width * p + offsetWidth,
          height - (height * (infectedPercent)) + offsetHeight));
      deadPoints.add(Offset(width * p + offsetWidth,
          height - (height * (infectedPercent + deadPercent)) + offsetHeight));
      clearPoints.add(Offset(
          width * p + offsetWidth,
          height -
              (height * (infectedPercent + deadPercent + clearPercent)) +
              offsetHeight));

      i++;
    });

    infectedPoints.add(Offset(width + offsetWidth, height + offsetHeight));
    deadPoints.add(Offset(width + offsetWidth, height + offsetHeight));
    clearPoints.add(Offset(width + offsetWidth, height + offsetHeight));
    infectedPath.addPolygon(infectedPoints, true);
    deadPath.addPolygon(deadPoints, true);
    clearPath.addPolygon(clearPoints, true);

    canvas.drawPath(
        clearPath,
        Paint()
          ..style = PaintingStyle.fill
          ..color = kColorRecovered);
    canvas.drawPath(
        deadPath,
        Paint()
          ..style = PaintingStyle.fill
          ..color = kColorDead);
    canvas.drawPath(
        infectedPath,
        Paint()
          ..style = PaintingStyle.fill
          ..color = kColorSick);
  }
}

class Field {
  final double diseaseTime;
  final int count;
  final double distancing;
  final double speed;
  final double scale;

  List<Particle> particles;

  Field(
      {this.diseaseTime = 5,
      this.count = 300,
      this.distancing = 0,
      this.speed = 100,
      this.scale = 50});

  void step(double deltaTime) {
    if (particles == null) {
      particles = List.generate(
          count,
          (idx) => Particle()
            ..infected = idx == 0 ? diseaseTime : null
            ..mass *= (scale / 100.0));
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
          particle.step(particle._lastDelta * (speed / 100.0));
          other.step(particle._lastDelta * (speed / 100.0));

          if (particle.infected != null && particle.infected > 0 ||
              other.infected != null && other.infected > 0) {
            if (particle.infected == null) particle.infected = diseaseTime;
            if (other.infected == null) other.infected = diseaseTime;
          }
        }
      });
      particle.step(deltaTime * (speed / 100.0));
    });
  }

  void paint(Canvas canvas, Size size) {
    double width = min(size.width, size.height);
    double height = width;
    double offsetHeight = (size.height - height) / 2;
    double offsetWidth = (size.width - width) / 2;

    particles.forEach((particle) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(width * particle.x + offsetWidth,
                  height * particle.y + offsetHeight),
              width: particle.radius * width * 2,
              height: particle.radius * height * 2),
          Paint()
            ..color = particle.isDead
                ? kColorDead
                : particle.infected != null
                    ? particle.infected > 0
                        ? kColorSick.withOpacity(
                            sin(particle.infected * 2 * pi).abs() / 3 + 0.66)
                        : kColorRecovered
                    : Color.fromARGB(255, 0, 128, 0));
    });
  }
}

class Particle {
  double infected;
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double xs = (Random().nextDouble() - 0.5) * 0.1;
  double ys = (Random().nextDouble() - 0.5) * 0.1;
  double mass = ((Random().nextDouble()) + 0.1) * 0.0005;
  double get radius => sqrt(mass / pi);
  bool willDie = Random().nextDouble() < 0.03;
  bool get isDead => infected != null && infected < 0 && willDie;
  double get momentum => sqrt(xs * xs + ys * ys);
  bool get isInfected => infected != null && infected > 0;
  bool get isUninfected => infected == null;
  bool get isClear => infected != null && infected < 0 && !willDie;
  bool collision(Particle other) {
    final dx = x - other.x;
    final dy = y - other.y;

    final mindistance = radius + other.radius;
    if (dx.abs() < mindistance && dy.abs() < mindistance) {
      return (sqrt(dx * dx + dy * dy) < mindistance);
    }
    return false;
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

class Statistics {
  final int infected;
  final int uninfected;
  final int clear;
  final int dead;

  Statistics._internal({this.infected, this.uninfected, this.clear, this.dead});

  /// Create a statistic snapshot from a list of particles
  factory Statistics(List<Particle> particles) {
    return Statistics._internal(
      infected: particles.where((element) => element.isInfected).length,
      uninfected: particles.where((element) => element.isUninfected).length,
      clear: particles.where((element) => element.isClear).length,
      dead: particles.where((element) => element.isDead).length,
    );
  }
}
