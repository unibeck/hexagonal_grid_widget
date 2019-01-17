library hexagonal_grid_widget;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:after_layout/after_layout.dart';

import 'package:hexagonal_grid/hexagonal_grid.dart';
import 'package:hexagonal_grid_widget/hex_grid_child.dart';
import 'package:hexagonal_grid_widget/hex_grid_context.dart';

@immutable
class HexGridWidget<T extends HexGridChild> extends StatefulWidget {
  HexGridWidget(
      {@required this.hexGridContext,
      @required this.children,
      this.scrollListener});

  final HexGridContext hexGridContext;
  final List<T> children;

  final ValueChanged<Offset> scrollListener;
  final ValueNotifier<Offset> offsetNotifier = ValueNotifier(Offset(0, 0));

  @override
  State<StatefulWidget> createState() => _HexGridWidgetState(
      hexGridContext, children, scrollListener, offsetNotifier);

  //Set the x and y scroll offset
  set offset(Offset offset) {
    offsetNotifier.value = offset;
  }
}

// ignore: conflicting_generic_interfaces
class _HexGridWidgetState<T extends HexGridChild> extends State<HexGridWidget>
    with SingleTickerProviderStateMixin, AfterLayoutMixin<HexGridWidget> {
  final GlobalKey _containerKey = GlobalKey();
  bool _isAfterFirstLayout = false;

  HexGridContext _hexGridContext;
  List<T> _children;
  List<UIHex> _hexLayout;
  double _hexLayoutRadius = 0.0;

  double xPos = 0.0;
  double yPos = 0.0;
  double xViewPos = 0.0;
  double yViewPos = 0.0;
  Point origin = Point(0.0, 0.0);

  Animation<Offset> _flingAnimation;
  bool _enableFling = false;

  AnimationController _controller;
  ValueChanged<Offset> _scrollListener;
  ValueNotifier<Offset> _offsetNotifier;

  _HexGridWidgetState(
      HexGridContext hexGridContext,
      List<T> children,
      ValueChanged<Offset> scrollListener,
      ValueNotifier<Offset> offsetNotifier) {
    _hexGridContext = hexGridContext;
    _children = children;
    _hexLayout = UIHex.toSpiralHexLayout(children);

    if (scrollListener != null) {
      _scrollListener = scrollListener;
    }

    if (offsetNotifier != null) {
      _offsetNotifier = offsetNotifier;
      _offsetNotifier.addListener(updateOffsetFromNotifier);
    }
  }

  @override
  void initState() {
    super.initState();

    _isAfterFirstLayout = false;

    _controller = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
  }

  @override
  void dispose() {
    _controller?.dispose();

    //Don't dispose as other's might be using it. It would be up to the owner,
    // in this case HexGridWidget, to dispose of it. So only clean up after
    // ourselves (this class, _HexGridWidgetState)
    _offsetNotifier?.removeListener(updateOffsetFromNotifier);

    super.dispose();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _isAfterFirstLayout = true;

    final double containerWidth = this.containerWidth;
    final double containerHeight = this.containerHeight;

    //Determine the origin of the container. Since we'll be using origin w.r.t
    // to the bounding boxes of the hex children, which are positioned by
    // top and left values, we'll have to adjust by half of the widget size to
    // get the technical origin.
    origin = Point((containerWidth / 2) - (_hexGridContext.maxSize / 2),
        (containerHeight / 2) - (_hexGridContext.maxSize / 2));

    //Center the hex grid to origin
    offset = Offset(origin.x, origin.y);
  }

  void updateOffsetFromNotifier() => offset = _offsetNotifier.value;

  set offset(Offset offset) {
    setState(() {
      xViewPos = offset.dx;
      yViewPos = offset.dy;
    });
  }

  set children(List<T> children) {
    setState(() {
      _children = children;
      _hexLayout = UIHex.toSpiralHexLayout(children);
    });
  }

  double get containerHeight {
    RenderBox containerBox = _containerKey.currentContext.findRenderObject();
    return containerBox.size.height;
  }

  double get containerWidth {
    RenderBox containerBox = _containerKey.currentContext.findRenderObject();
    return containerBox.size.width;
  }

  ///Ensures we will always have hex widgets visible
  Tuple2<double, double> _confineHexGridWithinContainer(
      double newXPosition, double newYPosition) {
    //Don't allow the right of the hex grid widget to exceed pass the left half
    // of the container
    if (newXPosition < origin.x - _hexLayoutRadius) {
      newXPosition = origin.x - _hexLayoutRadius;
    }

    //Don't allow the left of the hex grid widget to exceed pass the right half
    // of the container
    if (newXPosition > origin.x + _hexLayoutRadius) {
      newXPosition = origin.x + _hexLayoutRadius;
    }

    //Don't allow the bottom of the hex grid widget to exceed pass the top half
    // of the container
    if (newYPosition < origin.y - _hexLayoutRadius) {
      newYPosition = origin.y - _hexLayoutRadius;
    }

    //Don't allow the top of the hex grid widget to exceed pass the bottom half
    // of the container
    if (newYPosition > origin.y + _hexLayoutRadius) {
      newYPosition = origin.y + _hexLayoutRadius;
    }

    return Tuple2<double, double>(newXPosition, newYPosition);
  }

  void _handleFlingAnimation() {
    if (!_enableFling ||
        _flingAnimation.value.dx.isNaN ||
        _flingAnimation.value.dy.isNaN) {
      return;
    }

    double newXPosition = xPos + _flingAnimation.value.dx;
    double newYPosition = yPos + _flingAnimation.value.dy;

    Tuple2<double, double> newPositions =
        _confineHexGridWithinContainer(newXPosition, newYPosition);

    newXPosition = newPositions.item1;
    newYPosition = newPositions.item2;

    setState(() {
      xViewPos = newXPosition;
      yViewPos = newYPosition;
    });

    _sendScrollValues();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final RenderBox referenceBox = context.findRenderObject();
    final Offset position = referenceBox.globalToLocal(details.globalPosition);

    double newXPosition = xViewPos + (position.dx - xPos);
    double newYPosition = yViewPos + (position.dy - yPos);

    Tuple2<double, double> newPositions =
        _confineHexGridWithinContainer(newXPosition, newYPosition);

    newXPosition = newPositions.item1;
    newYPosition = newPositions.item2;

    setState(() {
      xViewPos = newXPosition;
      yViewPos = newYPosition;
    });

    xPos = position.dx;
    yPos = position.dy;

    _sendScrollValues();
  }

  void _handlePanDown(DragDownDetails details) {
    _enableFling = false;
    final RenderBox referenceBox = context.findRenderObject();
    final Offset position = referenceBox.globalToLocal(details.globalPosition);

    xPos = position.dx;
    yPos = position.dy;
  }

  void _handlePanEnd(DragEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    final double velocity = magnitude / 1000;

    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    final double distance = (Offset.zero & context.size).shortestSide;

    xPos = xViewPos;
    yPos = yViewPos;

    _enableFling = true;
    _flingAnimation = Tween<Offset>(
            begin: Offset(0.0, 0.0),
            end: direction * distance * _hexGridContext.velocityFactor)
        .animate(_controller);
    _controller
      ..value = 0.0
      ..fling(velocity: velocity);
  }

  _sendScrollValues() {
    if (_scrollListener != null) {
      _scrollListener(Offset(xViewPos, yViewPos));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget childToShow;
    if (!_isAfterFirstLayout) {
      childToShow = Container();
    } else {
      childToShow = Stack(
          children: _buildHexWidgets(
              _hexGridContext.maxSize / _hexGridContext.densityFactor,
              xViewPos,
              yViewPos));
    }

    return GestureDetector(
      onPanDown: _handlePanDown,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).backgroundColor,
          ),
          key: _containerKey,
          child: childToShow),
    );
  }

  List<Widget> _buildHexWidgets(
      double hexSize, double layoutOriginX, double layoutOriginY) {
    HexLayout flatLayout = HexLayout.orientFlat(
        Point(hexSize, hexSize), Point(layoutOriginY, layoutOriginX));
    List<Widget> hexWidgetList = [];

    final double containerWidth = this.containerWidth;
    final double containerHeight = this.containerHeight;

    for (int i = 0; i < _hexLayout.length; i++) {
      Positioned hexWidget = _createPositionWidgetForHex(_children[i],
          _hexLayout[i], flatLayout, containerWidth, containerHeight);

      if (hexWidget != null) {
        hexWidgetList.add(hexWidget);
      }
    }

    if (_hexLayout.isNotEmpty) {
      final Point originHexToPixel = _hexLayout.first.hex.toPixel(flatLayout);

      _hexLayoutRadius =
          originHexToPixel.distanceTo(_hexLayout.last.hex.toPixel(flatLayout));

      if (originHexToPixel.y > origin.x + _hexGridContext.maxSize / 2 ||
          originHexToPixel.y < origin.x - _hexGridContext.maxSize / 2 ||
          originHexToPixel.x > origin.y + _hexGridContext.maxSize / 2 ||
          originHexToPixel.x < origin.y - _hexGridContext.maxSize / 2) {
        final ThemeData themeData = Theme.of(context);
        Color color;

        switch (themeData.brightness) {
          case Brightness.light:
            color = themeData.primaryColorLight;
            break;
          case Brightness.dark:
            color = themeData.primaryColorDark;
            break;
        }

        hexWidgetList.add(Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: RaisedButton(
                    child: Text("Center"),
                    elevation: 4,
                    color: color,
                    textTheme: ButtonTextTheme.normal,
                    onPressed: () => _centerHexLayout(),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0))))));
      }
    }

    return hexWidgetList;
  }

  ///Only return a [Positioned] if the widget will be visible, otherwise return
  /// null so we don't waste CPU cycles on rendering something that's not visible
  /// NOTE: As with the rest of a Hex grid, the x and y coordinates are reflected
  Positioned _createPositionWidgetForHex(T hexGridChild, UIHex uiHex,
      HexLayout hexLayout, double containerWidth, double containerHeight) {
    final Point hexToPixel = uiHex.hex.toPixel(hexLayout);

    //If the right of the hex exceeds pass the left border of the container
    if (hexToPixel.y + _hexGridContext.maxSize < 0) {
      return null;
    }

    //If the left of the hex exceeds pass the right border of the container
    if (hexToPixel.y - _hexGridContext.maxSize > containerWidth) {
      return null;
    }

    //If the bottom of the hex exceeds pass the top border of the container
    if (hexToPixel.x + _hexGridContext.maxSize < 0) {
      return null;
    }

    //If the top of the hex exceeds pass the bottom border of the container
    if (hexToPixel.x - _hexGridContext.maxSize > containerHeight) {
      return null;
    }

    final Point reflectedOrigin = Point(origin.y, origin.x);
    final double distance = hexToPixel.distanceTo(reflectedOrigin);
    final double size = hexGridChild.getScaledSize(_hexGridContext, distance);

    return Positioned(
        top: hexToPixel.x,
        left: hexToPixel.y,
        child: hexGridChild.toHexWidget(context, _hexGridContext, size, uiHex));
  }

  void _centerHexLayout() {
    xPos = xViewPos;
    yPos = yViewPos;

    _enableFling = true;
    _flingAnimation = Tween<Offset>(
            begin: Offset(0, 0), end: Offset(origin.x - xPos, origin.y - yPos))
        .animate(_controller);
    _controller
      ..value = 0.0
      ..fling(velocity: 1);
  }
}
