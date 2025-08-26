import 'dart:io';
import 'entry.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddEntryPage extends StatefulWidget {
  final Function(Entry) onEntryAdded;

  const AddEntryPage({Key? key, required this.onEntryAdded}) : super(key: key);

  @override
  _AddEntryPageState createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  File? _image;

  // Date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        dateController.text = pickedDate.toString(); // Set the selected date in the text field
      });
    }
  }

  // Allow user to take photo
  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
      appBar: AppBar(
        title: const Text('Add Entry'),
        actions: [
          IconButton(
            onPressed: () {
              _getImage(); // Call method to capture image
            },
            icon: const Icon(Icons.camera),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            InkWell(
              onTap: () => _selectDate(context),
              child: IgnorePointer(
                child: TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
              ),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Entry newEntry = Entry(
                  description: descriptionController.text,
                  date: selectedDate.toString(),
                  category: categoryController.text,
                  amount: double.parse(amountController.text),
                );
                widget.onEntryAdded(newEntry);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            if (_image != null)
              Image.file(
                _image!,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
          ],
        ),
      ),
      ),
    );
  }
}
