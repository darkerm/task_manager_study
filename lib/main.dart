import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:date_field/date_field.dart';
import 'package:timezone/data/latest.dart' as timezone;
import 'package:timezone/timezone.dart' as timezone;
import 'package:path/path.dart' as Path;
import 'User_Task.dart';

class Work_With_DB {
  static final Work_With_DB _databaseHelper = Work_With_DB._();

  Work_With_DB._();

  late Database db;

  factory Work_With_DB() {
    return _databaseHelper;
  }
  static const String _tableName = "Tasks";
  Future<void> initDB() async {
    String path = await getDatabasesPath();
    db = await openDatabase(
      Path.join(path, 'Tasks.db'),
      onCreate: (database, version) async {
        await database.execute(
          """
            CREATE TABLE $_tableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT, 
              name TEXT NOT NULL,
              isDone INT NOT NULL, 
              reminderDateTime INT
            )
          """,
        );
      },
      version: 1,
    );
  }

  Future<int> insertUserTask(User_Task userTask) async {
    int result = await db.insert(_tableName, userTask.toMap());
    userTask.id = result;
    return result;
  }

  Future<int> updateUserTask(User_Task userTask) async {
    int result = await db.update(
      _tableName,
      userTask.toMap(),
      where: "id = ?",
      whereArgs: [userTask.id],
    );
    return result;
  }

  Future<List<User_Task>> retrieveUserTasks() async {
    final List<Map<String, Object?>> queryResult = await db.query(_tableName);
    return queryResult.map((e) => User_Task.fromMap(e)).toList();
  }

  Future<void> deleteUserTask(int id) async {
    await db.delete(
      _tableName,
      where: "id = ?",
      whereArgs: [id],
    );
  }
}

class Notification_Service {
  static final Notification_Service _notificationService =
  Notification_Service._internal();
  factory Notification_Service() {
    return _notificationService;
  }
  Notification_Service._internal();

  //instance of FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  Future<void> init() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');

    final IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false);

    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: null);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);
  }

  Future<void> showNotifications() async {
    var androidDetails = AndroidNotificationDetails(
        "Channel ID", "Desi programmer",
        channelDescription: "This is my channel");
    var iOSDetails = new IOSNotificationDetails();
    var generalNotificationDetails =
    new NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Notification Title',
      'This is the Notification Body',
      generalNotificationDetails,
      payload: 'Notification Payload',
    );
  }

  Future selectNotification(String? payload) async {
    //Handle notification tapped logic here
  }
}

class Edit_UserTask_Screen extends StatelessWidget {
  static const String id = "edit_usertask";
  Edit_UserTask_Screen({this.initUserTask}) {
    if (initUserTask != null) {
      newUserTask = User_Task.fromMap(initUserTask!.toMap());
    }
  }

  User_Task? initUserTask;
  User_Task newUserTask = User_Task(name: "");
  bool isApplaied = false;

  void apply(BuildContext context) {
    isApplaied = true;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add task")),
      body: Column(
        children: [
          const Text("Description:"),
          TextFormField(
              initialValue: newUserTask.name,
              onChanged: (value) => {newUserTask.name = value}),
          DateTimeFormField(
            initialValue: newUserTask.reminderDateTime,
            decoration: const InputDecoration(
              hintStyle: TextStyle(color: Colors.black45),
              errorStyle: TextStyle(color: Colors.redAccent),
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.event_note),
              labelText: 'Remind time',
            ),
            dateFormat: DateFormat("dd-MM-yyyy HH:mm"),
            mode: DateTimeFieldPickerMode.dateAndTime,
            onDateSelected: (DateTime value) {
              newUserTask.reminderDateTime = value;
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text("Done"),
        onPressed: () {
          apply(context);
        },
      ),
    );
  }
}

class User_TaskList_Item extends StatelessWidget {
  User_TaskList_Item({
    required this.userTask,
    this.onClickDone,
    this.onClickEdit,
    this.onClickDelete,
  }) : super(key: ObjectKey(userTask));

  final User_Task userTask;
  final Function(User_Task userTask)? onClickDone;
  final Function(User_Task userTask)? onClickEdit;
  final Function(User_Task userTask)? onClickDelete;

  Color _getColor(BuildContext context) {

    return userTask.isDone //
        ? Colors.black
        : Theme.of(context).primaryColor;
  }

  TextStyle? _getTextStyle(BuildContext context) {
    if (!userTask.isDone) return null;

    return const TextStyle(
      color: Colors.black,
      decoration: TextDecoration.lineThrough,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        onTap: () {
          if (onClickDone != null) {
            onClickDone!(userTask);
          }
        },
        leading: CircleAvatar(
          backgroundColor: _getColor(context),
          child: Text(userTask.name[0]),
        ),
        title: Text(
          userTask.name,
          style: _getTextStyle(context),
        ),
        subtitle: userTask.reminderDateTime == null
            ? null
            : Text("Remind at " +
            DateFormat("dd-MM-yyyy HH:mm")
                .format(userTask.reminderDateTime as DateTime)),
        trailing: PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (onClickEdit != null && value == "Edit") {
                onClickEdit!(userTask);
              }
              if (onClickDelete != null && value == "Delete") {
                onClickDelete!(userTask);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text("Edit"), value: "Edit"),
              const PopupMenuItem(
                child: Text("Delete"),
                value: "Delete",
              ),
            ]));
  }
}

class UserTaskList_Screen extends StatefulWidget {
  UserTaskList_Screen({Key? key}) : super(key: key);
  static const String id = "UserTaskList_Screen";
  List<User_Task> userTaskList = List<User_Task>.empty();
  Work_With_DB dbHelper = Work_With_DB();
  Notification_Service notificationService = Notification_Service();

  void AddUserTask(User_Task newUserTask) {
    userTaskList.add(newUserTask);
    dbHelper.insertUserTask(newUserTask);
    AddNotification(newUserTask);
  }

  void UpdateUserTask(User_Task newUserTask) {
    userTaskList[userTaskList
        .indexWhere((element) => element.id == newUserTask.id)] = newUserTask;
    dbHelper.updateUserTask(newUserTask);
    RemoveNotification(newUserTask);
    AddNotification(newUserTask);
  }

  void RemoveUserTask(User_Task userTaskforRemove) {
    RemoveNotification(userTaskforRemove);
    userTaskList.removeWhere((userTask) => userTask.id == userTaskforRemove.id);
    dbHelper.deleteUserTask(userTaskforRemove.id!);
  }

  void RetrieveUserTaskList() async {
    userTaskList = await dbHelper.retrieveUserTasks();
    for (var i = 0; i < userTaskList.length; i++) {
      AddNotification(userTaskList[i]);
    }
  }

  void RemoveNotification(User_Task userTask) async {
    notificationService.flutterLocalNotificationsPlugin
        .cancel(userTask.id ?? 0);
  }

  void AddNotification(User_Task userTask) async {
    var androidDetails = AndroidNotificationDetails(
        "Channel ID", "Desi programmer",
        channelDescription: "This is my channel");
    var iOSDetails = new IOSNotificationDetails();
    var generalNotificationDetails =
    new NotificationDetails(android: androidDetails, iOS: iOSDetails);
    if (userTask.reminderDateTime != null &&
        userTask.reminderDateTime!.isAfter(DateTime.now())) {
      await notificationService.flutterLocalNotificationsPlugin.zonedSchedule(
          userTask.id ?? 0,
          "Reminder",
          userTask.name +
              " at " +
              DateFormat("dd-MM-yyyy HH:mm")
                  .format(userTask.reminderDateTime as DateTime),
          timezone.TZDateTime.from(userTask.reminderDateTime!, timezone.local),
          generalNotificationDetails,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime);
    }
  }

  // The framework calls createState the first time
  // a widget appears at a given location in the tree.
  // If the parent rebuilds and uses the same type of
  // widget (with the same key), the framework re-uses
  // the State object instead of creating a new State object.

  @override
  _UserTaskList_State createState() => _UserTaskList_State();
}

class _UserTaskList_State extends State<UserTaskList_Screen> {
  @override
  void initState() {
    super.initState();
    widget.notificationService.init();
    timezone.initializeTimeZones();
    this.widget.dbHelper.initDB().whenComplete(() async {
      setState(() {
        widget.RetrieveUserTaskList();
      });
    });
  }

  void _handleTaskOnClickDone(User_Task userTask) {
    setState(() {
      userTask.isDone = !userTask.isDone;
      widget.UpdateUserTask(userTask);
    });
  }

  void _handleTaskOnClickDelete(User_Task userTask) {
    setState(() {
      widget.RemoveUserTask(userTask);
    });
  }

  void _handleAddTask() async {
    var ats = Edit_UserTask_Screen();
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ats;
    }));
    setState(() {
      if (ats.newUserTask.name.isNotEmpty && ats.isApplaied) {
        widget.AddUserTask(ats.newUserTask);
      }
    });
  }

  void _handleEditTask(User_Task UserTask) async {
    var ats = Edit_UserTask_Screen(
      initUserTask: UserTask,
    );
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ats;
    }));
    setState(() {
      if (ats.newUserTask.name.isNotEmpty && ats.isApplaied) {
        widget.UpdateUserTask(ats.newUserTask);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Task List'),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: widget.userTaskList.map((User_Task userTask) {
            return User_TaskList_Item(
              userTask: userTask,
              onClickDone: _handleTaskOnClickDone,
              onClickDelete: _handleTaskOnClickDelete,
              onClickEdit: _handleEditTask,
            );
          }).toList(),
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: _handleAddTask,
            tooltip: 'Add new task',
            child: const Icon(Icons.add)));
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Task App',
    home: UserTaskList_Screen(),
  ));
}
