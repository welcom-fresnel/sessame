class HomeAd {
  final String id;
  final String title;
  final String message;
  final String ctaLabel;
  final String? ctaUrl;
  final String type;
  final String? imageUrl;
  final String accentColorHex;
  final bool active;

  const HomeAd({
    required this.id,
    required this.title,
    required this.message,
    required this.ctaLabel,
    this.ctaUrl,
    required this.type,
    this.imageUrl,
    required this.accentColorHex,
    required this.active,
  });

  factory HomeAd.fromJson(Map<String, dynamic> json) {
    return HomeAd(
      id: (json['id'] ?? 'home-summary-default').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      ctaLabel: (json['ctaLabel'] ?? 'Découvrir').toString(),
      ctaUrl: json['ctaUrl']?.toString(),
      type: (json['type'] ?? 'text').toString(),
      imageUrl: json['imageUrl']?.toString(),
      accentColorHex: (json['accentColorHex'] ?? '#7C4DFF').toString(),
      active: json['active'] == true,
    );
  }

  bool get isImageAd => type == 'image' && imageUrl != null && imageUrl!.trim().isNotEmpty;

  bool get isDisplayable => active && title.trim().isNotEmpty && message.trim().isNotEmpty;
}
