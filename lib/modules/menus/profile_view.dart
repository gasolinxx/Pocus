import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileView extends StatefulWidget {
  static const String routeName = '/profile';

  const ProfileView({super.key});

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int? selectedDayIndex;
  String? userName;
  int? userAge;
  String? profilePictureUrl;
  String? grade;
  int? points;
  List<Map<String, dynamic>> userGoals = [];

  final List<String> weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  void initState() {
    super.initState();

    // Set selected day index to today's weekday
    final now = DateTime.now();
    selectedDayIndex = now.weekday - 1; // Monday = 0 index

    _fetchUserProfile();
    _fetchUserGoals();

    // Fetch initial insights for the current day
    _fetchInsightForDate(_getFormattedDateFromIndex(selectedDayIndex!));
  }

  /// Helper function to format the date based on the day index
  String _getFormattedDateFromIndex(int index) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday as the start
    final selectedDate = startOfWeek.add(Duration(days: index));
    return selectedDate.toIso8601String().split('T')[0]; // Format as YYYY-MM-DD
  }

  /// Handle day tap and fetch data for the selected day
  void _onDayTapped(int index) {
    setState(() {
      selectedDayIndex = index;
    });

    final formattedDate = _getFormattedDateFromIndex(index);
    _fetchInsightForDate(formattedDate);
  }

  /// Fetch user profile data
  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final profileRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile');

      final snapshot = await profileRef.get();

      if (snapshot.exists) {
        final profileData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          userName = profileData['name'] as String?;
          userAge = profileData['age'] as int?;
          profilePictureUrl = profileData['profilePicture'] as String?;
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  /// Fetch user goals categories
  Future<void> _fetchUserGoals() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final goalsRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('goals');

      final snapshot = await goalsRef.get();

      if (snapshot.exists) {
        final goalsData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          userGoals = goalsData.entries
              .map((entry) => {
                    'category': entry.value['category'] as String,
                  })
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching goals: $e');
    }
  }

  /// Fetch grade and points for the selected date
  Future<void> _fetchInsightForDate(String selectedDate) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final insightRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('insight')
          .child(selectedDate);

      final snapshot = await insightRef.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          grade = data['grade'] as String?;
          points = data['points'] as int?;
        });
      } else {
        setState(() {
          grade = null; // No grade for the selected date
          points = null; // No points for the selected date
        });
      }
    } catch (e) {
      print('Error fetching insights: $e');
    }
  }

  /// Fetch last month's grades
  Future<Map<String, int>> _fetchLastMonthGrades() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1);
      final firstDayOfLastMonth = DateTime(lastMonth.year, lastMonth.month, 1);
      final lastDayOfLastMonth =
          DateTime(lastMonth.year, lastMonth.month + 1, 1).subtract(const Duration(days: 1));

      final insightRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('insight');

      final snapshot = await insightRef.get();
      if (snapshot.exists) {
        final insights = Map<String, dynamic>.from(snapshot.value as Map);
        final gradeCounts = <String, int>{};

        for (final entry in insights.entries) {
          final date = DateTime.parse(entry.key);
          if (date.isAfter(firstDayOfLastMonth.subtract(const Duration(seconds: 1))) &&
              date.isBefore(lastDayOfLastMonth.add(const Duration(seconds: 1)))) {
            final grade = entry.value['grade'] as String? ?? 'FAIL';
            gradeCounts[grade] = (gradeCounts[grade] ?? 0) + 1;
          }
        }
        return gradeCounts;
      }
      return {};
    } catch (e) {
      print('Error fetching last month grades: $e');
      return {};
    }
  }

  /// Show last month's grades overview
  void _showLastMonthOverview() async {
    final gradeCounts = await _fetchLastMonthGrades();
    final sortedGrades = ['A', 'B', 'C', 'FAIL'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Last Month Overview'),
        content: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: sortedGrades.map((grade) {
                  final count = gradeCounts[grade] ?? 0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: grade == 'A'
                            ? Colors.green
                            : grade == 'B'
                                ? Colors.yellow
                                : grade == 'C'
                                    ? Colors.red
                                    : Colors.black,
                        child: Text(
                          grade,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'x$count',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Pick and upload profile picture
  Future<void> _pickAndUploadProfilePicture() async {
    try {
      final picker = ImagePicker();

      if (kIsWeb) {
        // Web logic
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          final byteData = await pickedFile.readAsBytes();

          final user = FirebaseAuth.instance.currentUser;
          if (user == null) throw Exception("User not logged in");

          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_pictures')
              .child('${user.uid}.jpg');

          final uploadTask = storageRef.putData(byteData);

          await uploadTask.whenComplete(() async {
            if (uploadTask.snapshot.state == TaskState.success) {
              final downloadURL = await storageRef.getDownloadURL();

              final profileRef = FirebaseDatabase.instance
                  .ref()
                  .child('users')
                  .child(user.uid)
                  .child('profile');

              await profileRef.update({'profilePicture': downloadURL});

              setState(() {
                profilePictureUrl = downloadURL;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image has been changed!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        }
      } else {
        // Mobile logic
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          final file = File(pickedFile.path);

          final user = FirebaseAuth.instance.currentUser;
          if (user == null) throw Exception("User not logged in");

          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_pictures')
              .child('${user.uid}.jpg');

          final uploadTask = storageRef.putFile(file);

          await uploadTask.whenComplete(() async {
            if (uploadTask.snapshot.state == TaskState.success) {
              final downloadURL = await storageRef.getDownloadURL();

              final profileRef = FirebaseDatabase.instance
                  .ref()
                  .child('users')
                  .child(user.uid)
                  .child('profile');

              await profileRef.update({'profilePicture': downloadURL});

              setState(() {
                profilePictureUrl = downloadURL;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image has been changed!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF7C4DFF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
  radius: 90,
  backgroundImage: profilePictureUrl != null
      ? NetworkImage(profilePictureUrl!)
      : null, // No fallback to local assets
  backgroundColor: Colors.grey[200], // Default background color
  child: profilePictureUrl == null
      ? const Icon(
          Icons.person, // Placeholder icon
          size: 60,
          color: Colors.grey,
        )
      : null,
),

                      Positioned(
                        bottom: 10,
                        right: -10,
                        child: GestureDetector(
                          onTap: _pickAndUploadProfilePicture,
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName != null && userAge != null
                        ? '$userName, $userAge'
                        : 'Loading...',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GoalsCategoryCard(goals: userGoals),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      weekDays.length,
                      (index) => DayCircle(
                        day: weekDays[index],
                        isActive: selectedDayIndex == index,
                        onTap: () => _onDayTapped(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Grade',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            grade ?? '--',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              color: grade != null ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          ElevatedButton(
                              onPressed: _showLastMonthOverview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C44E7), // Button color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // Rounded corners
                                ),
                                foregroundColor: Colors.white, // Text color
                              ),
                              child: const Text('Last Month Overview')),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Points',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            points?.toString() ?? '--',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              color: points != null ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalsCategoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> goals;

  const GoalsCategoryCard({required this.goals, super.key});

  @override
  Widget build(BuildContext context) {
    final iconMapping = {
      'Musicians': Icons.music_note,
      'Smarter': Icons.lightbulb,
      'Religious': Icons.book,
      'Muscle': Icons.fitness_center,
    };

    // Filter out duplicate categories
    final uniqueGoals = goals
        .map((goal) => goal['category'] as String?)
        .toSet()
        .where((category) => category != null)
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Goals Category',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: uniqueGoals.map((category) {
              return Column(
                children: [
                  Icon(
                    iconMapping[category] ?? Icons.help_outline,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class DayCircle extends StatelessWidget {
  final String day;
  final bool isActive;
  final VoidCallback onTap;

  const DayCircle({
    required this.day,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: isActive ? Colors.blue : Colors.grey[300],
        child: Text(
          day,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
