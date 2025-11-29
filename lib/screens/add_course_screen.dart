import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  Future<void> _addCourse() async {
    if (_titleController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Enter title");
      return;
    }

    await FirebaseFirestore.instance.collection('courses').add({
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'enrolledStudents': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    Fluttertoast.showToast(msg: "Course added!");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Course")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Course Title"),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _addCourse, child: const Text("Add Course")),
          ],
        ),
      ),
    );
  }
}