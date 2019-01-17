import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexagonal_grid_widget/hex_grid_child.dart';
import 'package:hexagonal_grid_widget/hex_grid_context.dart';
import 'package:hexagonal_grid_widget/hex_grid_widget.dart';

import 'test_utils.dart';

void main() {
  final double _minHexWidgetSize = 24;
  final double _maxHexWidgetSize = 128;
  final double _scaleFactor = 0.2;
  final double _densityFactor = 1.75;
  final double _velocityFactor = 0.3;

  testWidgets('10 HexGridChild widgets are visible and are in the render tree',
      (WidgetTester tester) async {
    final int numOfChildren = 10;
    final List<HexGridChild> children =
        TestUtils.createHexGridChildren(numOfChildren);

    final HexGridWidget hexGridWidget = HexGridWidget(
        children: children,
        hexGridContext: HexGridContext(_minHexWidgetSize, _maxHexWidgetSize,
            _scaleFactor, _densityFactor, _velocityFactor));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: hexGridWidget),
    ));

    //The HexGridWidget needs to find the origin of its container, thus it must
    // wait at least one frame after rendering to determine the width and height
    // to determine its center. Because of this we must wait to the layout
    // renderer to "settle" or fully complete its lifecycle changes.
    await tester.pumpAndSettle();

    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.byType(Positioned)),
        findsNWidgets(numOfChildren));
    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.widgetWithText(RaisedButton, 'Center')),
        findsNothing);
  });

  testWidgets(
      '10 HexGridChild and a Center widget are rendered when the '
      'omniscroll is off center', (WidgetTester tester) async {
    final int numOfChildren = 10;
    final List<HexGridChild> children =
        TestUtils.createHexGridChildren(numOfChildren);

    final HexGridWidget hexGridWidget = HexGridWidget(
        children: children,
        hexGridContext: HexGridContext(_minHexWidgetSize, _maxHexWidgetSize,
            _scaleFactor, _densityFactor, _velocityFactor));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: hexGridWidget),
    ));

    //Wait for the state to catch up
    await tester.pumpAndSettle();

    //Find the 10 HexGridChild widgets, but no Center text widget
    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.byType(Positioned)),
        findsNWidgets(numOfChildren));
    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.widgetWithText(RaisedButton, 'Center')),
        findsNothing);

    //Artificially scroll (Set offset) to the top-left by maxHexWidgetSize
    Offset center = tester.getCenter(find.descendant(
        of: find.byWidget(hexGridWidget),
        matching: find.byType(GestureDetector)));
    hexGridWidget.offset =
        center + Offset(_maxHexWidgetSize, _maxHexWidgetSize);

    //Wait for the state to catch up
    await tester.pumpAndSettle();

    //Now all 10 HexGridChild widgets should still show as well as a Center
    // text widget
    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.byType(Positioned)),
        findsNWidgets(numOfChildren));
    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.widgetWithText(RaisedButton, 'Center')),
        findsOneWidget);
  });

  testWidgets('Only HexGridChild widgets that are visiable are rendered',
      (WidgetTester tester) async {
    final int numOfChildren = 10;
    final List<HexGridChild> children =
        TestUtils.createHexGridChildren(numOfChildren);

    final HexGridWidget hexGridWidget = HexGridWidget(
        children: children,
        hexGridContext: HexGridContext(_minHexWidgetSize, _maxHexWidgetSize,
            _scaleFactor, _densityFactor, _velocityFactor));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: hexGridWidget),
    ));

    //Wait for the state to catch up
    await tester.pumpAndSettle();

    //All 10 HexGridChild widgets should show, but no Center text widget
    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.byType(Positioned)),
        findsNWidgets(numOfChildren));
    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.widgetWithText(RaisedButton, 'Center')),
        findsNothing);

    //Artificially scroll (Set offset) to the top-left by doubling center
    Offset center = tester.getCenter(find.descendant(
        of: find.byWidget(hexGridWidget),
        matching: find.byType(GestureDetector)));
    hexGridWidget.offset = center + center;

    //Wait for the state to catch up
    await tester.pumpAndSettle();

    //Now only 7 HexGridChild widgets are in view, thus only 7 should be in
    // the render tree. The Center text widget should also show
    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.byType(Positioned)),
        findsNWidgets(7));
    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.widgetWithText(RaisedButton, 'Center')),
        findsOneWidget);

    //Artificially scroll (Set offset) back to the center
    hexGridWidget.offset = center;

    //Wait for the state to catch up
    await tester.pumpAndSettle();

    //All 10 HexGridChild widgets are in view and thus all 10 should be in
    // the render tree. The Center text widget should no longer show
    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.byType(Positioned)),
        findsNWidgets(numOfChildren));
    expect(
        find.descendant(
            of: find.byWidget(hexGridWidget),
            matching: find.widgetWithText(RaisedButton, 'Center')),
        findsNothing);
  });
}
