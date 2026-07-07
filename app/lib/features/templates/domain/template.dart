class TemplateSummary {
  const TemplateSummary({
    required this.key,
    required this.domain,
    required this.title,
    required this.description,
  });

  final String key;
  final String domain;
  final String title;
  final String description;

  factory TemplateSummary.fromJson(Map<String, dynamic> json) => TemplateSummary(
    key: json['key'] as String,
    domain: json['domain'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
  );
}

class TemplateDetail {
  const TemplateDetail({
    required this.key,
    required this.domain,
    required this.title,
    required this.description,
    this.sourceUrl,
  });

  final String key;
  final String domain;
  final String title;
  final String description;
  final String? sourceUrl;

  factory TemplateDetail.fromJson(Map<String, dynamic> json) => TemplateDetail(
    key: json['key'] as String,
    domain: json['domain'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    sourceUrl: json['sourceUrl'] as String?,
  );
}
