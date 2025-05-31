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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['sort_order'] = this.sortOrder;
    data['keypad_id'] = this.keypadId;
    data['option'] = this.option;
    return data;
  }
}
