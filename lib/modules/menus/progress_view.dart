import 'package:flutter/material.dart';

import '../../database_service.dart';

class ProgressView extends StatefulWidget {
  static const String routeName = '/progress';

  const ProgressView({super.key});

  @override
  _ProgressViewState createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<List<Map<String, dynamic>>> _goalsFuture;

  /// States for progress tracking
  final Map<String, List<bool>> _circleStates = {};
  final Map<String, String> _textInputs = {};

  double _totalCompleted = 0.0;
  double _totalPoints = 0.0;

  /// Grade information to display
  GradeInfo? _currentGrade;

  @override
  void initState() {
    super.initState();
    _goalsFuture = _fetchGoalsAndInitializeStates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshGoals();
  }

  Future<void> _refreshGoals() async {
    setState(() {
      _goalsFuture = _fetchGoalsAndInitializeStates();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchGoalsAndInitializeStates() async {
    final goals = await _databaseService.fetchGoals();
    final progressData = await _databaseService.fetchProgress();

    for (var goal in goals) {
      if (goal['measure'] == 'Tap') {
        // Initialize circle states
        final completed = progressData[goal['id']]?['completed'] ?? 0;
        _circleStates[goal['id']] =
            List.generate(goal['repetition'], (index) => index < completed);
      } else if (goal['measure'] == 'Text') {
        // Initialize text input
        final completed = progressData[goal['id']]?['completed'] ?? 0;
        _textInputs[goal['id']] = completed.toString();
      }
    }

    // Fetch and set the grade
    final gradeData = await _databaseService.fetchGrade();
    if (gradeData != null) {
      setState(() {
        _currentGrade = GradeInfo(
          grade: gradeData['grade'],
          color: _getGradeColor(gradeData['grade']),
        );
      });
    }

    return goals;
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.yellow;
      case 'C':
      case 'Fail':
        return Colors.red;
      default:
        return Colors.grey; // Fallback color
    }
  }

  Future<void> _updateGrade() async {
    final percentage = (_totalCompleted / _totalPoints) * 100;
    String grade;
    Color gradeColor;

    if (percentage >= 90) {
      grade = "A+";
      gradeColor = Colors.green;
    } else if (percentage >= 75) {
      grade = "A";
      gradeColor = Colors.green;
    } else if (percentage >= 56) {
      grade = "B";
      gradeColor = Colors.yellow;
    } else if (percentage >= 31) {
      grade = "C";
      gradeColor = Colors.red;
    } else {
      grade = "Fail";
      gradeColor = Colors.red;
    }

    await _databaseService.updateGrade(grade);

    setState(() {
      _currentGrade = GradeInfo(grade: grade, color: gradeColor);
    });
  }

  Future<void> _updateTextInput(String goalId, String value) async {
    setState(() {
      _textInputs[goalId] = value;
    });

    final goal = (await _goalsFuture).firstWhere((g) => g['id'] == goalId);
    final measureDuration = goal['duration'].toDouble();
    final inputMinutes = (int.tryParse(value) ?? 0).toDouble();

    final progress = (inputMinutes / measureDuration).clamp(0, 1.0);

    await _databaseService.updateProgress(
      goalId: goalId,
      completed: progress.toDouble(),
      total: 1.0,
    );
  }

  Future<void> _recalculateProgress() async {
    final goals = await _goalsFuture;

    _totalCompleted = 0.0;
    _totalPoints = 0.0;

    for (var goal in goals) {
      if (goal['measure'] == 'Tap') {
        final completedCircles = _circleStates[goal['id']]!.where((state) => state).length;
        _totalCompleted += completedCircles;
        _totalPoints += goal['repetition'];
      } else if (goal['measure'] == 'Text') {
        final duration = goal['duration'];
        final userInput = double.tryParse(_textInputs[goal['id']] ?? "0") ?? 0.0;
        _totalCompleted += (userInput / duration).clamp(0, 1.0);
        _totalPoints += 1.0;
      }
    }

    await _updateGrade();
  }

void _toggleCircle(String goalId, int index) async {
  setState(() {
    _circleStates[goalId]![index] = !_circleStates[goalId]![index];
  });

  await _recalculateProgress();

  // Convert to double explicitly
  final completed = _circleStates[goalId]!.where((state) => state).length.toDouble();
  final total = _circleStates[goalId]!.length.toDouble();

  await _databaseService.updateProgress(
    goalId: goalId,
    completed: completed,
    total: total,
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7C4DFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C4DFF),
        elevation: 0,
        title: const Text(
          "Daily Progress",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (_currentGrade != null)
            Row(
              children: [
                const Text(
                  "Grade",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _currentGrade!.color,
                  child: Text(
                    _currentGrade!.grade,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _goalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No goals found!"));
          }

          final goals = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _buildTaskCard(goal);
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal['title'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 12),
          goal['measure'] == 'Tap'
              ? _buildCircles(goal['id'], goal['repetition'])
              : _buildTextInput(goal['id']),
        ],
      ),
    );
  }

  Widget _buildCircles(String goalId, int repetition) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(repetition, (index) {
        return GestureDetector(
          onTap: () => _toggleCircle(goalId, index),
          child: CircleAvatar(
            radius: 12,
            backgroundColor: _circleStates[goalId]![index] ? Colors.green : Colors.grey,
          ),
        );
      }),
    );
  }

  Widget _buildTextInput(String goalId) {
    final isEditing = ValueNotifier<bool>(false);
    final TextEditingController controller = TextEditingController();

    return ValueListenableBuilder<bool>(
      valueListenable: isEditing,
      builder: (context, editing, child) {
        if (!editing) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _textInputs[goalId] ?? "Enter hours",
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  controller.text = _textInputs[goalId] ?? '';
                  isEditing.value = true;
                },
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter hours",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                final value = controller.text;
                await _updateTextInput(goalId, value);
                isEditing.value = false;
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                controller.clear();
                isEditing.value = false;
              },
            ),
          ],
        );
      },
    );
  }
}

class GradeInfo {
  final String grade;
  final Color color;

  GradeInfo({required this.grade, required this.color});
}
