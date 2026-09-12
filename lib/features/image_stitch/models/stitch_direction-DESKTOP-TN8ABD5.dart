enum StitchDirection {
  vertical('Vertical', 'Stack images top to bottom'),
  horizontal('Horizontal', 'Place images side by side');

  const StitchDirection(this.label, this.description);

  final String label;
  final String description;
}
