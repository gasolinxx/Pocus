import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

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

  void _showAIGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => _AIGoalDialog(onGoalAdded: _refreshGoals),
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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showAIGoalDialog,
            backgroundColor: Colors.white,
            child: const Icon(Icons.help_outline, color: Color(0xFF7C4DFF)),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _AddGoalDialog(onGoalAdded: _refreshGoals),
              );
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.add, color: Color(0xFF7C4DFF)),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

class _AIGoalDialog extends StatefulWidget {
  final VoidCallback onGoalAdded;

  const _AIGoalDialog({required this.onGoalAdded});

  @override
  State<_AIGoalDialog> createState() => _AIGoalDialogState();
}

class _AIGoalDialogState extends State<_AIGoalDialog> {
  final List<String> _categories = [
    'Musicians',
    'Smarter',
    'Religious',
    'Muscle',
    'Healthy',
    'Financial',
    'Skill Development',
    'Social',
  ];
  String? _selectedCategory;
  bool _isLoading = false;
  List<Map<String, String>> _suggestedGoals = [];

  Future<void> _generateGoals() async {
  if (_selectedCategory == null) return;

  setState(() {
    _isLoading = true;
    _suggestedGoals.clear();
  });

  final gemini = Gemini.instance;

  try {
    final response = await gemini.text(
      "Suggest goals and their descriptions for the category: $_selectedCategory. "
      "Provide a list with goal names and descriptions in JSON format as: "
      "[{\"title\": \"Pray\", \"description\": \"Pray everyday to be blessed by god.\"}, "
      "{\"title\": \"Goal Name 2\", \"description\": \"Description 2\"}]",
    );

    print("Raw Response: ${response?.output}");

    if (response?.output != null) {
      // Clean the response to ensure it is valid JSON
      String cleanOutput = response!.output!
          .replaceAll('```JSON', '')
          .replaceAll('```', '')
          .trim();

      // Parse the cleaned output
      final List<dynamic> jsonResponse = jsonDecode(cleanOutput);

      setState(() {
        _suggestedGoals = List<Map<String, String>>.from(jsonResponse.map((goal) {
          return {
            'title': goal['title'] ?? 'No Title',
            'description': goal['description'] ?? 'No Description',
          };
        }));
      });
    } else {
      throw Exception("No output received from Gemini");
    }
  } catch (e) {
    print('Error generating goals: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to generate goals: $e")),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: const Text("AI Suggested Goals"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: _categories
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            decoration: const InputDecoration(
              labelText: "Select a category",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedCategory != null && !_isLoading
                ? _generateGoals
                : null,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text("Generate Goals"),
          ),
          const SizedBox(height: 16),
          if (_suggestedGoals.isNotEmpty)
            ..._suggestedGoals.map((goal) {
              return ListTile(
                title: Text(goal['title'] ?? ""),
                subtitle: Text(goal['description'] ?? ""),
                trailing: IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF7C4DFF)),
                  onPressed: () async {
                    await DatabaseService().addGoal(
                      title: goal['title']!,
                      description: goal['description']!,
                      category: _selectedCategory!,
                      repetition: 1,
                      measureDuration: 0,
                      measure: "AI Suggested",
                    );
                    widget.onGoalAdded();
                    Navigator.of(context).pop();
                  },
                ),
              );
            }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ],
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
  final DatabaseService _databaseService = DatabaseService();

  final List<String> _categories = [
    'Musicians',
    'Smarter',
    'Religious',
    'Muscle',
    'Healthy',
    'Financial',
    'Skill Development',
    'Social',
  ];

  String? _selectedCategory;
  int _selectedRepetition = 1;
  int _selectedDuration = 5; // Duration in minutes
  bool _isTapSelected = true;
  bool _isCategorySelected = false;

  void _proceedToGoalInput() {
    if (_selectedCategory != null) {
      setState(() {
        _isCategorySelected = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category first.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: Text(_isCategorySelected ? "Add Goal Details" : "Select a Category"),
      content: SingleChildScrollView(
        child: _isCategorySelected
            ? _buildGoalInputForm()
            : _buildCategorySelection(),
      ),
      actions: [
        if (_isCategorySelected)
          TextButton(
            onPressed: () {
              setState(() {
                _isCategorySelected = false;
              });
            },
            child: const Text("Back"),
          ),
        ElevatedButton(
          onPressed: _isCategorySelected ? _saveGoal : _proceedToGoalInput,
          child: Text(_isCategorySelected ? "Save" : "Next"),
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          items: _categories
              .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          decoration: const InputDecoration(
            labelText: "Select a category",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalInputForm() {
    return Column(
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Tap"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Text"),
                ),
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
    );
  }

  Future<void> _saveGoal() async {
    String goalName = _goalNameController.text.trim();
    String goalDescription = _goalDescriptionController.text.trim();
    String measure = _isTapSelected ? "Tap" : "Text";

    if (goalName.isNotEmpty && goalDescription.isNotEmpty && _selectedCategory != null) {
      await _databaseService.addGoal(
        title: goalName,
        category: _selectedCategory!,
        description: goalDescription,
        repetition: _isTapSelected ? _selectedRepetition : 0,
        measureDuration: _isTapSelected ? 0 : _selectedDuration,
        measure: measure,
      );
      widget.onGoalAdded();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
    }
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _goalDescriptionController.dispose();
    super.dispose();
  }
}
