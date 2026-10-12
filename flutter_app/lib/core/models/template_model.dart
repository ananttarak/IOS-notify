import 'dart:math';

class TemplateModel {
  final String id;
  final String title;
  final String body;
  final int weight;
  final bool isEnabled;
  final bool isSimulated;
  final Map<String, String> defaultVariables;
  final DateTime createdAt;

  const TemplateModel({
    required this.id,
    required this.title,
    required this.body,
    this.weight = 10,
    this.isEnabled = true,
    this.isSimulated = true,
    this.defaultVariables = const {},
    required this.createdAt,
  });

  TemplateModel copyWith({
    String? id,
    String? title,
    String? body,
    int? weight,
    bool? isEnabled,
    bool? isSimulated,
    Map<String, String>? defaultVariables,
    DateTime? createdAt,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      weight: weight ?? this.weight,
      isEnabled: isEnabled ?? this.isEnabled,
      isSimulated: isSimulated ?? this.isSimulated,
      defaultVariables: defaultVariables ?? this.defaultVariables,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'weight': weight,
      'isEnabled': isEnabled,
      'isSimulated': isSimulated,
      'defaultVariables': defaultVariables,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TemplateModel.fromMap(Map<String, dynamic> map, String docId) {
    return TemplateModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      weight: (map['weight'] as num?)?.toInt() ?? 10,
      isEnabled: map['isEnabled'] ?? true,
      isSimulated: map['isSimulated'] ?? true,
      defaultVariables: Map<String, String>.from(map['defaultVariables'] ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Interpolate placeholders such as {{order_id}}, {{amount}}, {{items}}, {{store}}
  Map<String, String> render([Map<String, dynamic>? customVars]) {
    final vars = <String, String>{
      'order_id': '${1000 + Random().nextInt(8999)}',
      'amount': '\$${(15 + Random().nextInt(150)).toStringAsFixed(2)}',
      'items': '${1 + Random().nextInt(4)}',
      'store': 'StorePulse Demo',
      'currency': 'USD',
      ...defaultVariables,
      if (customVars != null)
        ...customVars.map((k, v) => MapEntry(k, v.toString())),
    };

    String renderedTitle = title;
    String renderedBody = body;

    vars.forEach((key, value) {
      renderedTitle = renderedTitle.replaceAll('{{$key}}', value);
      renderedBody = renderedBody.replaceAll('{{$key}}', value);
    });

    return {
      'title': renderedTitle,
      'body': renderedBody,
      'isSimulated': isSimulated ? 'true' : 'false',
    };
  }
}
