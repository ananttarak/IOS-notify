class TemplateModel {
  final String id;
  final String title;
  final String body;
  final int weight;
  final bool isEnabled;
  final bool isSimulated;
  final String customAmount;
  final int startOrderNumber;
  final String storeName;
  final Map<String, String> defaultVariables;
  final DateTime createdAt;

  const TemplateModel({
    required this.id,
    required this.title,
    required this.body,
    this.weight = 10,
    this.isEnabled = true,
    this.isSimulated = true,
    this.customAmount = '₹6,555.00',
    this.startOrderNumber = 1794,
    this.storeName = 'Folkthreads',
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
    String? customAmount,
    int? startOrderNumber,
    String? storeName,
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
      customAmount: customAmount ?? this.customAmount,
      startOrderNumber: startOrderNumber ?? this.startOrderNumber,
      storeName: storeName ?? this.storeName,
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
      'customAmount': customAmount,
      'startOrderNumber': startOrderNumber,
      'storeName': storeName,
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
      customAmount: map['customAmount'] ?? '₹6,555.00',
      startOrderNumber: (map['startOrderNumber'] as num?)?.toInt() ?? 1794,
      storeName: map['storeName'] ?? 'Folkthreads',
      defaultVariables: Map<String, String>.from(map['defaultVariables'] ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static int _orderCounter = 1794;

  static void setNextOrderNumber(int num) {
    _orderCounter = num;
  }

  static int get currentOrderNumber => _orderCounter;

  /// Interpolate placeholders such as {{order_id}}, {{amount}}, {{items}}, {{store}}
  /// Follows strict sequential progression (1, 2, 3...)
  Map<String, String> render([Map<String, dynamic>? customVars]) {
    final currentOrderNum = _orderCounter++; // Follow sequence 1 by 1

    final amountVal = customVars?['amount']?.toString() ??
        (customAmount.isNotEmpty ? customAmount : '₹6,555.00');
    final storeVal = customVars?['store']?.toString() ??
        (storeName.isNotEmpty ? storeName : 'Folkthreads');

    final vars = <String, String>{
      'order_id': '$currentOrderNum',
      'amount': amountVal,
      'items': '1 item',
      'channel': 'Online Store',
      'store': storeVal,
      'currency': 'INR',
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
      'order_id': '$currentOrderNum',
      'isSimulated': isSimulated ? 'true' : 'false',
    };
  }
}
