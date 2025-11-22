class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({
    required this.latitude,
    required this.longitude,
  });

  static Coordinates fromStudentIndex(String index) {
    // Remove any non-digit characters
    final cleanIndex = index.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanIndex.length < 4) {
      throw ArgumentError('Index must have at least 4 digits');
    }

    // Extract first two and next two digits
    final firstTwo = int.parse(cleanIndex.substring(0, 2));
    final nextTwo = int.parse(cleanIndex.substring(2, 4));

    // Calculate coordinates
    final lat = 5.0 + (firstTwo / 10.0);
    final lon = 79.0 + (nextTwo / 10.0);

    return Coordinates(
      latitude: lat,
      longitude: lon,
    );
  }

  String get latitudeFormatted => latitude.toStringAsFixed(2);
  String get longitudeFormatted => longitude.toStringAsFixed(2);
}
