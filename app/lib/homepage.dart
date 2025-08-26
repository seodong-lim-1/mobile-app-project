import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'entry.dart';
import 'expenses.dart';
import 'reports.dart';
import 'authService.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoggedIn = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    tz.initializeTimeZones();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    //_requestNotificationPermissions();
  }

  //create notifications
  Future<void> _initializeNotifications() async {
    // Request notification permissions
    await _requestNotificationPermissions();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('logo');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: _onSelectNotification,
    );
  }

  Future<void> _requestNotificationPermissions() async {
    // Request notification permissions
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _onSelectNotification(String? payload) async {
    // Handle notification tap
    print('Notification tapped with payload: $payload');
  }

  Future<void> _scheduleNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      'Login Successful', // Notification title
      'You have successfully logged in!', // Notification body
      tz.TZDateTime.now(tz.local)
          .add(const Duration(seconds: 1)), // Scheduled time
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage'),
        actions: [
          isLoggedIn
              ? IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    _signOut();
                    // if the user is not logged in show a snack bar asking to login
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User not Logged In, Please Login'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await _signOut();
                    setState(() {
                      isLoggedIn = false;
                    });
                  },
                ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 50,
            left: 30,
            child: Card(
              child: Container(
                width: 120,
                height: 120,
                padding: EdgeInsets.all(5.0),
                child: Image.asset('lib/images/logo.png'),
              ),
            ),
          ),
          const Positioned(
            top: 50,
            right: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget',
                  style: TextStyle(fontSize: 50.0),
                ),
                Text(
                  'Buddy',
                  style: TextStyle(fontSize: 50.0),
                ),
              ],
            ),
          ),
          _showLoginDialog(context),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.paid),
            label: 'Expenses',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
        onTap: (index) {
          _handleNavigation(index);
        },
      ),
    );
  }

  Future<void> _signIn() async {
    // Perform Firebase sign-in or local sign-in
    User? user = await _authService.signInWithFirebase(
        usernameController.text, passwordController.text);

    if (user != null) {
      setState(() {
        isLoggedIn = true;
      });
      // notification
      await _scheduleNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign In successfully!'),
          duration: Duration(seconds: 1),
        ),
      );
      // Navigate to ExpensesPage and pass the authenticated user
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ExpensesPage(
            entries: [],
          ),
        ),
      );
    } else {
      // Handle sign-in failure
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Login Failed'),
            content:
                const Text('Invalid username or password. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // sign out
  Future<void> _signOut() async {
    // Show a confirmation dialog
    bool cancel = false;
    bool? confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: isLoggedIn
              ? Text('Are you sure you want to log out?')
              : Text('You are not logged in. Do you want to proceed?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                if (!isLoggedIn) {
                  // Handle the case where user is not logged in and didn't click cancel
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Log Out successful'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
    // Check the result from the dialog
    // checking if the user is logged in
    if (confirmLogout == true) {
      // User confirmed logout
      await _auth.signOut();
      FirebaseFirestore.instance.terminate;

      setState(() {
        isLoggedIn = false;
      });
    }
  }

  Widget _showLoginDialog(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _signIn();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 32.0),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Handle navigation for other cases if needed
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpensesPage(entries: []),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportsPage(entries: []),
          ),
        );
        break;
    }
  }
}
