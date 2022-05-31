class User_Task {
  User_Task({
    required this.name,
    this.reminderDateTime,
    this.id,
    this.isDone = false,
  });

  int? id;
  String name;
  bool isDone;
  DateTime? reminderDateTime;

  User_Task.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        name = res["name"],
        isDone = res["isDone"] == 1 ? true : false,
        reminderDateTime = res["reminderDateTime"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(res["reminderDateTime"]);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'isDone': isDone ? 1 : 0,
      'reminderDateTime': reminderDateTime == null
          ? null
          : reminderDateTime!.millisecondsSinceEpoch
    };
  }
}
