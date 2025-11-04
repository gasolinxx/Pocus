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

  final List<String> weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
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

  /// Handle day tap and fetch data for the selected day
  void _onDayTapped(int index) {
    setState(() {
      selectedDayIndex = index;
    });

    // Calculate the selected date based on the current week's start
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday as the start
    final selectedDate = startOfWeek.add(Duration(days: index));
    final formattedDate = selectedDate.toIso8601String().split('T')[0]; // Format as YYYY-MM-DD

    _fetchInsightForDate(formattedDate);
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
                            : const AssetImage('assets/images/jpg/profile.jpg')
                                as ImageProvider,
                        backgroundColor: Colors.white,
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
