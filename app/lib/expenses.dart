import 'package:app/addEntry.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'homepage.dart';
import 'reports.dart';
import 'entry.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({Key? key, required List<Entry> entries})
      : super(key: key);

  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  late Database _database;
  List<dynamic> selectedEntryIds = [];
  List<Entry> entries = [];
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  bool isUserLoggedIn = false;
  String collectionName = 'entries';

  @override
  void initState() {
    super.initState();
    _checkAuthenticationState().then((value) {
      setState(() {
        isUserLoggedIn = value;
      });
    });
    _initialize();
  }

  // Initializing DB and grabbing existing entries
  Future<void> _initialize() async {
    await _initDatabase();
    await _fetchEntries();
  }

  // Checking if user is logged in
  Future<bool> _checkAuthenticationState() async {
    User? user = await FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not auth');
      return false;
    } else {
      return true;
    }
  }

  Future<void> _initDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'expense_database.db');

    _database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
          CREATE TABLE entries(
            id INTEGER PRIMARY KEY,
            description TEXT,
            date TEXT,
            category TEXT,
            amount REAL
          )
        ''');
    });
  }

  Future<void> _fetchEntries() async {
    if (isUserLoggedIn == true) {
      print('User is Logged In');
      await _fetchEntriesFromFirestore();
    } else {
      print('User is not Logged In');
      await _fetchEntriesFromDatabase();
    }
  }

  Future<void> _fetchEntriesFromFirestore() async {
    try {
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection("entries").get();
      List<Entry> result = [];

      for (DocumentSnapshot document in querySnapshot.docs) {
        result.add(Entry.fromFirestore(document));
      }

      setState(() {
        entries = result.cast<Entry>();
      });
    } catch (e) {
      // Handle errors appropriately
      print("Error fetching entries from Firestore: $e");
    }
  }

  Future<void> _fetchEntriesFromDatabase() async {
    final List<Map<String, dynamic>> maps = await _database.query('entries');

    setState(() {
      entries = List.generate(
        maps.length,
        (i) {
          return Entry.fromDatabase(maps[i]);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldKey,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                //_addEntry(newEntry)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEntryPage(onEntryAdded: _addEntry),
                  ),
                );
                //print('After navigating to ExpensesPage');
                // SnackBar notification for adding expense
                _scaffoldKey.currentState?.showSnackBar(
                    SnackBar(content: Text("Expense has been added")));
              },
            ),
            if (selectedEntryIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _deleteSelectedEntries();
                  // SnackBar notification for deleting expense
                  _scaffoldKey.currentState?.showSnackBar(
                      SnackBar(content: Text("Expense has been deleted")));
                },
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  bool isSelected =
                      selectedEntryIds.contains(entries[index].id);
                  return Container(
                    child: ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        activeColor: Colors.grey,
                        onChanged: (bool? value) {
                          setState(() {
                            value = isSelected;
                            _toggleSelection(entries[index].id!);
                          });
                        },
                        checkColor: Colors.red,
                      ),
                      title: Text(entries[index].description!),
                      subtitle: Text(
                        'Date: ${entries[index].date}\n'
                        'Category: ${entries[index].category}\n'
                        'Amount: \$${entries[index].amount.toString()}',
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: Text('Entry Details'),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      'Description: ${entries[index].description}'),
                                  Text('Date: ${entries[index].date}'),
                                  Text('Category: ${entries[index].category}'),
                                  Text(
                                      'Amount: \$${entries[index].amount.toString()}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.paid),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Reports',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyHomePage(),
                  ),
                );
                break;
              case 1:
                // Stay on Expenses Page
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportsPage(entries: entries),
                  ),
                );
                break;
            }
          },
        ),
      ),
    );
  }

  // Selects Entries
  void _toggleSelection(String entryId) {
    setState(() {
      if (selectedEntryIds.contains(entryId)) {
        selectedEntryIds.remove(entryId);
      } else {
        selectedEntryIds.add(entryId);
      }
    });
  }

  // Deletes Entries
  void _deleteSelectedEntries() async {
    if (isUserLoggedIn == true) {
      for (String entryId in selectedEntryIds) {
        await FirebaseFirestore.instance
            .collection("entries")
            .doc(entryId as String?)
            .delete();
      }
    } else {
      for (String entryId in selectedEntryIds) {
        await _database
            .delete('entries', where: 'id = ?', whereArgs: [entryId]);
      }
    }

    setState(() {
      selectedEntryIds.clear();
      _fetchEntries();
    });
  }

  // Adds Entries
  Future<void> _addEntry(Entry newEntry) async {
    if (isUserLoggedIn == true) {
      // Use Firestore
      await FirebaseFirestore.instance
          .collection(collectionName)
          .add(newEntry.toMap());
    } else {
      // Use local database
      await _database.insert('entries', newEntry.toMap());
    }
    _fetchEntries();
  }
}
