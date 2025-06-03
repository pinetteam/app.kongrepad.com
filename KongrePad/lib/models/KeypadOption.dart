class KeypadOption {
  int? id;
  int? sortOrder;
  int? keypadId;
  String? option;

  KeypadOption({this.id, this.sortOrder, this.keypadId, this.option});

  factory KeypadOption.fromJson(Map<String, dynamic> json) {
    return KeypadOption(
      id: json['id'],
      sortOrder: json['sort_order'],
      keypadId: json['keypad_id'],
      option: json['option'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sort_order'] = sortOrder;
    data['keypad_id'] = keypadId;
    data['option'] = option;
    return data;
  }
}
