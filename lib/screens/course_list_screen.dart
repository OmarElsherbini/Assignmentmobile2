import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  // Map to track the loading state for each course ID
  // This ensures the button is disabled while processing
  final Map<String, bool> _enrollmentStatus = {};

  // New function to handle the enrollment logic with proper error handling
  Future<void> _enrollInCourse(String userId, String courseId) async {
    try {
      // CRITICAL STEP: Write the authenticated user's ID to the enrolledStudents array
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({
        'enrolledStudents': FieldValue.arrayUnion([userId])
      });

      // Success toast (will now only show if the Firestore write succeeds)
      Fluttertoast.showToast(
          msg: "Enrolled in course successfully!",
          backgroundColor: Colors.green,
          textColor: Colors.white);

    } on FirebaseException catch (e) {
      // FAILURE: Catch the specific Firebase error (e.g., PERMISSION_DENIED)
      // Print the full error code/message to the console for accurate debugging
      print('Firestore Enrollment Error: ${e.code} => ${e.message}'); 
      
      // Show the failure message to the user
      Fluttertoast.showToast(
          msg: "Enrollment Failed: ${e.message}",
          backgroundColor: Colors.red,
          textColor: Colors.white);
      
    } catch (e) {
      // General/Unexpected error
      print('Unexpected Enrollment Error: $e');
      Fluttertoast.showToast(msg: "An unexpected error occurred.", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the user is logged in before getting the UID
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      // Handle navigation to the Login screen if authentication fails
      return const Scaffold(
        body: Center(child: Text("Error: User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Available Courses")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading courses"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final courseId = course.id;
              final data = course.data() as Map<String, dynamic>;

              final bool isEnrolling = _enrollmentStatus[courseId] ?? false;

              // Extract the list of enrolled students
              final enrolledStudents = (data['enrolledStudents'] as List<dynamic>?) ?? [];
              final bool alreadyEnrolled = enrolledStudents.contains(userId);

              return Card(
                child: ListTile(
                  title: Text(data['title'] ?? 'No Title'),
                  subtitle: Text(data['description'] ?? ''),
                  trailing: ElevatedButton(
                    onPressed: alreadyEnrolled || isEnrolling
                        ? null // Disable if already enrolled or currently enrolling
                        : () async {
                            // Set loading state
                            setState(() {
                              _enrollmentStatus[courseId] = true;
                            });

                            // --- CALL FIXED ENROLLMENT FUNCTION ---
                            await _enrollInCourse(userId, courseId);

                            // Clear loading state
                            setState(() {
                              _enrollmentStatus.remove(courseId);
                            });
                          },
                    child: alreadyEnrolled
                        ? const Text("Enrolled")
                        : isEnrolling
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Enroll"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}