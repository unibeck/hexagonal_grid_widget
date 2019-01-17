import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:hexagonal_grid/hexagonal_grid.dart';
import 'package:hexagonal_grid_widget/hex_grid_child.dart';
import 'package:hexagonal_grid_widget/hex_grid_context.dart';

class TestUtils {
  static List<HexGridChild> createHexGridChildren(int numOfChildren) {
    List<HexGridChild> children = [];

    for (int i = 0; i < numOfChildren; i++) {
      children.add(TestHexGridChild(i));
    }

    return children;
  }
}

class TestHexGridChild extends HexGridChild {
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

  TestHexGridChild(this.index);

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
