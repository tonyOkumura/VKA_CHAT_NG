class AssigneeModel {
  final String id;
  final String username;

  AssigneeModel({required this.id, required this.username});

  factory AssigneeModel.fromJson(Map<String, dynamic> json) {
    return AssigneeModel(id: json['id'], username: json['username']);
  }
}
