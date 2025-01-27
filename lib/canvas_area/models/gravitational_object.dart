import 'package:flutter/material.dart';

abstract class GravitationalObject {
  Offset position;
  double gravitySpeed;
  double _gravity = 1.0;
  Offset additionalForce;
  final double rotation;

  GravitationalObject(
      {required this.position,
      required this.rotation,
      this.gravitySpeed = 0,
      this.additionalForce = const Offset(0, 0)});

  void applyGravity() {
    gravitySpeed += _gravity;
    position = Offset(position.dx + additionalForce.dx,
        position.dy + gravitySpeed + additionalForce.dy);
  }
}
