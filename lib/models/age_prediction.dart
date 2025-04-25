class GeneratedAge {
  final String id;
  final String imageUrl;
  final String originalImageUrl;
  final int targetAge;
  final DateTime createdAt;
  final bool usedFreeCredit;

  GeneratedAge({
    required this.id,
    required this.imageUrl,
    required this.originalImageUrl,
    required this.targetAge,
    required this.createdAt,
    this.usedFreeCredit = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'originalImageUrl': originalImageUrl,
        'targetAge': targetAge,
        'createdAt': createdAt.toIso8601String(),
        'usedFreeCredit': usedFreeCredit,
      };

  factory GeneratedAge.fromJson(Map<String, dynamic> json) => GeneratedAge(
        id: json['id'],
        imageUrl: json['imageUrl'],
        originalImageUrl: json['originalImageUrl'],
        targetAge: json['targetAge'],
        createdAt: DateTime.parse(json['createdAt']),
        usedFreeCredit: json['usedFreeCredit'] ?? false,
      );
}
