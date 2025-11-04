import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../database_service.dart';

class GoalsView extends StatefulWidget {
  static const String routeName = '/goals';

  const GoalsView({super.key});

  @override
  State<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<List<Map<String, dynamic>>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _goalsFuture = _databaseService.fetchGoals();
  }

  Future<void> _refreshGoals() async {
    setState(() {
      _goalsFuture = _databaseService.fetchGoals();
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Replace with your login route
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7C4DFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C4DFF),
        elevation: 0,
        title: const Text(
          "Plan your goals!",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
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
          return RefreshIndicator(
            onRefresh: _refreshGoals,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return _buildGoalCard(goal);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _AddGoalDialog(onGoalAdded: _refreshGoals),
          );
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Color(0xFF7C4DFF)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal['title'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          Text(
            goal['description'],
            style: const TextStyle(color: Color.fromARGB(255, 129, 127, 127)),
          ),
        ],
      ),
        
        subtitle: Text(
          "Measure: ${goal['measure']} - "
          "Repetition: ${goal['repetition']} - "
          "Duration: ${goal['duration']} min",
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await _databaseService.deleteGoal(goal['id']);
            _refreshGoals();
          },
        ),
      ),
    );
  }
}

class _AddGoalDialog extends StatefulWidget {
  final VoidCallback onGoalAdded;

  const _AddGoalDialog({required this.onGoalAdded});

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _goalDescriptionController = TextEditingController();
  int _selectedRepetition = 1;
  int _selectedDuration = 5; // Duration in minutes
  bool _isTapSelected = true;

  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: const Text("Add New Goal"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _goalNameController,
              decoration: const InputDecoration(
                labelText: "Goal Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _goalDescriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Measure:"),
                ToggleButtons(
                  isSelected: [_isTapSelected, !_isTapSelected],
                  onPressed: (index) {
                    setState(() {
                      _isTapSelected = index == 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  selectedBorderColor: const Color(0xFF7C4DFF),
                  selectedColor: Colors.white,
                  fillColor: const Color(0xFF7C4DFF),
                  color: Colors.black,
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text("Tap")),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text("Text")),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            if (_isTapSelected)
              DropdownButtonFormField<int>(
                value: _selectedRepetition,
                decoration: const InputDecoration(
                  labelText: "Repetition in a Day",
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  10,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text("${index + 1} times"),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedRepetition = value ?? 1;
                  });
                },
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedDuration,
                decoration: const InputDecoration(
                  labelText: "How many minutes?",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 5, child: Text("5 minutes")),
                  DropdownMenuItem(value: 15, child: Text("15 minutes")),
                  DropdownMenuItem(value: 30, child: Text("30 minutes")),
                  DropdownMenuItem(value: 60, child: Text("1 hour")),
                  DropdownMenuItem(value: 120, child: Text("2 hours")),
                  DropdownMenuItem(value: 180, child: Text("3 hours")),
                  DropdownMenuItem(value: 240, child: Text("4 hours")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value ?? 5;
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            String goalName = _goalNameController.text.trim();
            String goalDescription = _goalDescriptionController.text.trim();
            String measure = _isTapSelected ? "Tap" : "Text";

            if (goalName.isNotEmpty && goalDescription.isNotEmpty) {
              await _databaseService.addGoal(
                title: goalName,
                category: "Custom",
                description: goalDescription,
                repetition: _isTapSelected ? _selectedRepetition : 0,
                measureDuration: _isTapSelected ? 0 : _selectedDuration,
                measure: measure, // Pass the measure type
              );
              widget.onGoalAdded();
              Navigator.of(context).pop();
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _goalDescriptionController.dispose();
    super.dispose();
  }
}
