import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hexagonal_grid/hexagonal_grid.dart';
import 'package:hexagonal_grid_widget/hex_grid_child.dart';
import 'package:hexagonal_grid_widget/hex_grid_context.dart';
import 'package:hexagonal_grid_widget/hex_grid_widget.dart';

void main() => runApp(HexGridWidgetExample());

class HexGridWidgetExample extends StatelessWidget {
  final double _minHexWidgetSize = 24;
  final double _maxHexWidgetSize = 128;
  final double _scaleFactor = 0.2;
  final double _densityFactor = 1.75;
  final double _velocityFactor = 0.3;
  final bool _flatLayout = true;
  final int _numOfHexGridChildWidgets = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Example"),
          centerTitle: true,
        ),
        body: HexGridWidget(
            children: createHexGridChildren(_numOfHexGridChildWidgets),
            hexGridContext: HexGridContext(_minHexWidgetSize, _maxHexWidgetSize,
                _scaleFactor, _densityFactor, _velocityFactor, _flatLayout)));
  }

  //This would likely be a service (RESTful or DB) that retrieves some data and
  // marshals them into HexGridChild objects
  List<HexGridChild> createHexGridChildren(int numOfChildren) {
    List<HexGridChild> children = [];

    for (int i = 0; i < numOfChildren; i++) {
      children.add(ExampleHexGridChild(i));
    }

    return children;
  }
}

//This class can contain all the properties you'd like, but it must extends
// HexGridChild and thus implement the toHexWidget and getScaledSized methods.
// The methods provide most fields the HexGridWidget is aware of to allow for
// as much flexibility when building and sizing your HexGridChild widget.
class ExampleHexGridChild extends HexGridChild {
  final int index;
  final List<Color> orbitalColors = [
    Color(0xFF2D365C),
    Color(0xFF083663),
    Color(0xFF07489C),
    Color(0xFF165DC0),
    Color(0xFF0E90E1),
    Color(0xFF89D3FB),
    Color(0xFFAFDBDE)
  ];

  ExampleHexGridChild(this.index);

  //This is only one example of the customization you can expect from these
  // framework hooks
  @override
  Widget toHexWidget(BuildContext context, HexGridContext hexGridContext,
      double size, UIHex hex) {
    return Container(
        padding: EdgeInsets.all((hexGridContext.maxSize - size) / 2),
        child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: orbitalColors[hex.orbital % orbitalColors.length],
              shape: BoxShape.circle,
            )));
  }

  @override
  double getScaledSize(
      HexGridContext hexGridContext, double distanceFromOrigin) {
    double scaledSize = hexGridContext.maxSize -
        (distanceFromOrigin * hexGridContext.scaleFactor);
    return max(scaledSize, hexGridContext.minSize);
  }
}
