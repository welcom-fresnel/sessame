class HomeAd {
  final String id;
  final String title;
  final String message;
  final String ctaLabel;
  final String? ctaUrl;
  final String accentColorHex;
  final bool active;

  const HomeAd({
    required this.id,
    required this.title,
    required this.message,
    required this.ctaLabel,
    this.ctaUrl,
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
      accentColorHex: (json['accentColorHex'] ?? '#7C4DFF').toString(),
      active: json['active'] == true,
    );
  }

  bool get isDisplayable => active && title.trim().isNotEmpty && message.trim().isNotEmpty;
}
