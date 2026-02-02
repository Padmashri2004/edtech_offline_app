class ImageMatchService {
  static final Map<String, String> imageDatabase = {
    "photosynthesis": "assets/images/photosynthesis.png",
    "heart": "assets/images/heart.png",
    "plant": "assets/images/plant.png",
  };

  static String? getImageForText(String inputText) {
    final text = inputText.toLowerCase();

    for (final entry in imageDatabase.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
