import 'dart:math';

import 'package:flutter/material.dart';

import 'models/fruit.dart';
import 'models/fruit_part.dart';
import 'models/touch_slice.dart';
import 'slice_painter.dart';

class CanvasArea extends StatefulWidget {
  const CanvasArea({super.key});

  @override
  State<CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends State<CanvasArea> {
  int _score = 0;
  TouchSlice? _touchSlice;
  final List<Fruit> _fruits = [];
  final List<FruitPart> _fruitParts = [];

  @override
  void initState() {
    _spawnRandomFruit();
    _tick();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: _getStack());
  }

  List<Widget> _getStack() {
    List<Widget> widgetOnStack = <Widget>[];
    widgetOnStack.add(_getBackground());
    widgetOnStack.add(_getSlice());
    widgetOnStack.addAll(_getFruitParts());
    widgetOnStack.addAll(_getFruits());
    widgetOnStack.add(_getGestureDetector());
    widgetOnStack.add(Positioned(
        right: 16,
        top: 16,
        child: Text(
          'Score:$_score',
          style: TextStyle(fontSize: 24),
        )));

    return widgetOnStack;
  }

  Container _getBackground() {
    return Container(
      decoration: BoxDecoration(
          gradient: RadialGradient(stops: [
        0.2,
        1.0
      ], colors: [
        Color.fromARGB(255, 94, 199, 255),
        Color.fromARGB(255, 21, 130, 240)
      ])),
    );
  }

  _getSlice() {
    if (_touchSlice == null) {
      return Container();
    }

    return CustomPaint(
      size: Size.infinite,
      painter: SlicePainter(pointsList: _touchSlice!.pointsList),
    );
  }

  List<Widget> _getFruitParts() {
    List<Widget> list = <Widget>[];

    for (FruitPart fruitPart in _fruitParts) {
      list.add(Positioned(
        top: fruitPart.position.dy,
        left: fruitPart.position.dx,
        child: _getMelonCut(fruitPart),
      ));
    }
    return list;
  }

  _getMelonCut(FruitPart fruitPart) {
    return Transform.rotate(
      angle: fruitPart.rotation * pi * 2,
      child: Image.asset(
        fruitPart.isLeft
            ? 'assets/melon_cut.png'
            : 'assets/melon_cut_right.png',
        height: 80,
        fit: BoxFit.fitHeight,
      ),
    );
  }

  List<Widget> _getFruits() {
    List<Widget> list = <Widget>[];

    for (Fruit fruit in _fruits) {
      list.add(Positioned(
          top: fruit.position.dy,
          left: fruit.position.dx,
          child: Transform.rotate(
            angle: fruit.rotation * pi * 2,
            child: _getMelon(fruit),
          )));
    }
    return list;
  }

  _getMelon(Fruit fruit) {
    return Image.asset(
      'assets/melon_uncut.png',
      height: 80,
      fit: BoxFit.fitHeight,
    );
  }

  _getGestureDetector() {
    return GestureDetector(
      onScaleStart: (details) {
        setState(() {
          _setNewSlice(details);
        });
      },
      onScaleUpdate: (details) {
        setState(() {
          _addPointToSlice(details);
          _checkCollision();
        });
      },
      onScaleEnd: (details) {
        setState(() {
          _resetSlice();
        });
      },
    );
  }

  void _spawnRandomFruit() {
    _fruits.add(Fruit(
        width: 80,
        height: 80,
        position: Offset(0, 200),
        additionalForce:
            Offset(5 + Random().nextDouble() * 5, Random().nextDouble() * -10),
        rotation: Random().nextDouble() / 3 - .16));
  }

  void _tick() {
    setState(() {
      for (Fruit fruit in _fruits) {
        fruit.applyGravity();
      }
      for (FruitPart fruitPart in _fruitParts) {
        fruitPart.applyGravity();
      }

      if (Random().nextDouble() > 0.97) {
        _spawnRandomFruit();
      }
    });

    Future.delayed(Duration(milliseconds: 30), _tick);
  }

  void _resetSlice() {
    _touchSlice = null;
  }

  void _checkCollision() {
    if (_touchSlice == null) {
      return;
    }

    for (Fruit fruit in List<Fruit>.from((_fruits))) {
      bool firstPointOutside = false;
      bool secondPointInside = false;

      for (Offset point in _touchSlice!.pointsList) {
        if (!firstPointOutside && !fruit.IsPointInside(point)) {
          firstPointOutside = true;
          continue;
        }

        if (firstPointOutside && fruit.IsPointInside(point)) {
          secondPointInside = true;
          continue;
        }

        if (secondPointInside && !fruit.IsPointInside(point)) {
          _fruits.remove(fruit);
          _turnFruitIntoParts(fruit);
          _score += 10;
          break;
        }
      }
    }
  }

  void _turnFruitIntoParts(Fruit hit) {
    FruitPart leftFruitPart = FruitPart(
        width: hit.width / 2,
        height: hit.height,
        isLeft: true,
        position: Offset(hit.position.dx - hit.width, hit.position.dy),
        gravitySpeed: hit.gravitySpeed,
        additionalForce:
            Offset(hit.additionalForce.dx - 1, hit.additionalForce.dy - 5),
        rotation: hit.rotation);

    FruitPart rightFruitPart = FruitPart(
        width: hit.width / 2,
        height: hit.height,
        isLeft: false,
        position: Offset(
            hit.position.dx + hit.width / 4 + hit.width / 8, hit.position.dy),
        gravitySpeed: hit.gravitySpeed,
        additionalForce:
            Offset(hit.additionalForce.dx + 1, hit.additionalForce.dy - 5),
        rotation: hit.rotation);

    setState(() {
      _fruitParts.add(leftFruitPart);
      _fruitParts.add(rightFruitPart);
      _fruits.remove(hit);
    });
  }

  void _addPointToSlice(ScaleUpdateDetails details) {
    if (_touchSlice?.pointsList == null || _touchSlice!.pointsList.isEmpty) {
      return;
    }

    if (_touchSlice!.pointsList.length > 16) {
      _touchSlice!.pointsList.removeAt(0);
    }
    _touchSlice!.pointsList.add(details.localFocalPoint);
  }

  void _setNewSlice(ScaleStartDetails details) {
    _touchSlice = TouchSlice(pointsList: <Offset>[details.localFocalPoint]);
  }
}
