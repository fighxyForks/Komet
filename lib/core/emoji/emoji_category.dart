enum EmojiCategory {
  smileysPeople,
  animalsNature,
  foodDrink,
  activity,
  travelPlaces,
  objects,
  symbols,
  flags,
}

extension EmojiCategoryCodec on EmojiCategory {
  static const names = [
    'smileysPeople',
    'animalsNature',
    'foodDrink',
    'activity',
    'travelPlaces',
    'objects',
    'symbols',
    'flags',
  ];

  String get id => names[index];

  static EmojiCategory fromIndex(int index) =>
      EmojiCategory.values[index.clamp(0, EmojiCategory.values.length - 1)];
}
