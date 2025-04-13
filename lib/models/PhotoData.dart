class PhotoData {
  final String imagePath;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? locationName; // Nuevo campo opcional

  PhotoData({
    required this.imagePath,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.locationName,
  });
}
