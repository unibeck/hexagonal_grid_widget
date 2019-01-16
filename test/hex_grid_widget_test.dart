import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexagonal_grid_widget/hex_grid_child.dart';
import 'package:hexagonal_grid_widget/hex_grid_context.dart';
import 'package:hexagonal_grid_widget/hex_grid_widget.dart';

import 'test_utils.dart';

void main() {
  testWidgets('finds 10 HexGridChild widgets', (WidgetTester tester) async {
    final double minHexWidgetSize = 24;
    final double maxHexWidgetSize = 128;
    final double scaleFactor = 0.2;
    final double densityFactor = 1.75;
    final double velocityFactor = 0.3;

    final int numOfChildren = 10;
    final List<HexGridChild> children =
        TestUtils.createHexGridChildren(numOfChildren);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: HexGridWidget(
              children: children,
              hexGridContext: HexGridContext(minHexWidgetSize, maxHexWidgetSize,
                  scaleFactor, densityFactor, velocityFactor))),
    ));

    expect(find.byType(HexGridChild), findsNWidgets(numOfChildren));
  });
}
