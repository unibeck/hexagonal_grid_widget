class HexGridContext {
  ///Minimum size of a individual hex widget
  final double minSize;

  ///Maximum size of a individual hex widget
  final double maxSize;

  ///Controls how significantly the hex child widgets shrink as the move further
  /// from the origin. The larger the number, the quicker the widgets will reduce
  /// in size as they get further from the origin
  final double scaleFactor;

  ///Controls how close the widgets sit next to each other. Note if the
  /// densityFactor is greater than two then the hex child widgets will overlap
  /// The larger the number the more dense the hex child widget will sit
  final double densityFactor;

  ///Controls the speed of the flingAnimation. The larger the number the faster
  /// the fling animation will play
  final double velocityFactor;

  ///Controls weather the geometry of the layout is pointy or flat. Defaults
  /// to flat
  final bool flatLayout;

  HexGridContext(this.minSize, this.maxSize, this.scaleFactor,
      this.densityFactor, this.velocityFactor, [this.flatLayout = true]);
}
