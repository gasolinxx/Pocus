import 'dart:async'; // For dynamic time updates

import 'package:flutter/material.dart';
import 'package:pocus_app/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeView extends StatefulWidget {
  static const String routeName = '/home';

  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final DatabaseService _databaseService = DatabaseService();

  late String _currentDate;
  late String _currentTime;
  late String _timeLeft;
  late double _progressValue;
  late Timer _timer;

  String _selectedDifficulty = "BEGINNER";
  String _grade = "";
  String _gradeMessage = "";
  int _points = 10; // Default points for BEGINNER

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _updateTimeLeft();
    _startTimer();
    _fetchUserGrade();
    _checkAndStoreDailyInsight();
  }

  Future<void> _checkAndStoreDailyInsight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSavedDate = prefs.getString('lastSavedDate');
      final currentDate = DateTime.now().toIso8601String().split('T')[0];

      if (lastSavedDate != currentDate) {
        // If the day has changed, store the daily insight
        await _databaseService.autoStoreDailyInsight();

        // Save the current date to SharedPreferences
        await prefs.setString('lastSavedDate', currentDate);
      }
    } catch (e) {
      print('Error checking and storing daily insight: $e');
    }
  }

  Future<void> _fetchUserGrade() async {
    try {
      final gradeData = await _databaseService.fetchGrade();
      if (gradeData != null) {
        setState(() {
          _grade = gradeData['grade'] ?? "Unknown";
          _gradeMessage = _getGradeMessage(_grade);
        });
        await _storeReport(); // Automatically store report after fetching grade
      }
    } catch (e) {
      setState(() {
        _grade = "Unknown";
        _gradeMessage = "No grade available";
      });
    }
  }

  String _getGradeMessage(String grade) {
    switch (grade) {
      case "A+":
        return "Very Good !";
      case "A":
        return "Good !";
      case "B":
        return "Keep Going !";
      case "C":
        return "You can do better !";
      default:
        return "";
    }
  }

  void _updateDateTime() {
    final now = DateTime.now();
    _currentDate = "${now.day} ${_getMonthName(now.month)} ${now.year}";
    _currentTime = "${_formatTime(now.hour)}:${_formatTime(now.minute)} ${now.hour >= 12 ? 'PM' : 'AM'}";
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1); // Next day at 12:00 AM
    final difference = midnight.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    _timeLeft = "$hours hours $minutes minutes left";

    final totalSecondsInDay = const Duration(hours: 24).inSeconds;
    final elapsedSeconds = now.hour * 3600 + now.minute * 60 + now.second;
    _progressValue = elapsedSeconds / totalSecondsInDay;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        _updateDateTime();
        _updateTimeLeft();
      });
    });
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }

  String _formatTime(int value) {
    return value < 10 ? "0$value" : value.toString();
  }

  Future<void> _storeReport() async {
    try {
      await _databaseService.storeReport(
        grade: _grade,
        difficulty: _selectedDifficulty,
        points: _points,
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _updateDifficulty(String difficulty) async {
    setState(() {
      _selectedDifficulty = difficulty;
      _points = _getPointsForDifficulty(difficulty);
    });
    await _storeReport();
  }

  int _getPointsForDifficulty(String difficulty) {
    switch (difficulty) {
      case "BEGINNER":
        return 10;
      case "INTERMEDIATE":
        return 5;
      case "HARD":
        return 0;
      default:
        return 10;
    }
  }

  Color _getCircleColor() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final difference = midnight.difference(now);

    final hoursLeft = difference.inHours;

    if (hoursLeft <= 5) {
      return Colors.red;
    } else if (hoursLeft <= 7) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  Color _getGradeColor() {
    switch (_grade) {
      case "A+":
      case "A":
        return Colors.green; // Green for A+ and A
      case "B":
        return Colors.yellow; // Yellow for B
      case "C":
      case "Fail":
      default:
        return Colors.red; // Red for C and Fail
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pocus App",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Stack(
        children: [
          // Background color
          Container(
            color: const Color(0xFF7C4DFF),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 24, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _currentDate,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Current Time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 24, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _currentTime,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Grade Widget at Top-Right
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Grade: ",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getGradeColor(),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _grade,
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _gradeMessage,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: const Color.fromARGB(201, 255, 255, 255),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clock Timer Widget
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background Circle
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 15,
                          color: const Color.fromARGB(255, 134, 130, 130).withOpacity(0.2),
                        ),
                      ),
                      // Foreground Circle
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: 1 - _progressValue,
                          strokeWidth: 15,
                          color: _getCircleColor(),
                        ),
                      ),
                      // Center Content (Time Display)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentTime,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Remaining Time
                  Text(
                    _timeLeft,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  // Difficulty Level Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(242, 255, 255, 255),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.black),
                      ),
                    ),
                    onPressed: () {
                      _showDifficultySelection(context);
                    },
                    child: Text(
                      _selectedDifficulty,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDifficultySelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            "Choose your level?",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Difficulty",
                  border: OutlineInputBorder(),
                ),
                value: _selectedDifficulty,
                items: const [
                  DropdownMenuItem(value: "BEGINNER", child: Text("BEGINNER")),
                  DropdownMenuItem(value: "INTERMEDIATE", child: Text("INTERMEDIATE")),
                  DropdownMenuItem(value: "HARD", child: Text("HARD")),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    await _updateDifficulty(value);
                  }
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              const SizedBox(height: 16),
              Text(
                "The level you set will change after this weekend.",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _difficultyCard("BEGINNER", "+10 points"),
                  _difficultyCard("INTERMEDIATE", "+5 points"),
                  _difficultyCard("HARD", "+0 points"),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("CANCEL"),
            ),
          ],
        );
      },
    );
  }

  Widget _difficultyCard(String level, String points) {
    return Column(
      children: [
        Text(
          level,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          points,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
