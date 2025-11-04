import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;


  DatabaseReference get _userGoalsRef {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return FirebaseDatabase.instance.ref().child('users').child(user.uid).child('goals');
  }

    DatabaseReference get _userRef {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return FirebaseDatabase.instance.ref().child('users').child(user.uid);
  }

  DatabaseReference get _insightRef {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return _userRef.child('insight');
  }

/// Store daily insight with grade and points
  Future<void> storeDailyInsight({
    required String grade,
    required int points,
  }) async {
    try {
      final currentDate = DateTime.now().toIso8601String().split('T')[0]; // Get only the date part (YYYY-MM-DD)
      final dailyRef = _insightRef.child(currentDate);

      await dailyRef.set({
        'grade': grade,
        'points': points,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to store daily insight: $e');
    }
  }

  /// Automatically store insight at the end of the day
  Future<void> autoStoreDailyInsight() async {
    try {
      final gradeSnapshot = await fetchGrade();
      final reportSnapshot = await fetchReport();

      if (gradeSnapshot != null && reportSnapshot != null) {
        final grade = gradeSnapshot['grade'] as String? ?? 'N/A';
        final points = reportSnapshot['points'] as int? ?? 0;

        await storeDailyInsight(grade: grade, points: points);
      }
    } catch (e) {
      throw Exception('Failed to auto-store daily insight: $e');
    }
  }


  /// Add a new goal to the database
  Future<void> addGoal({
    required String title,
    required String category,
    required String description,
    required int repetition, // For "Tap"
    required int measureDuration, // For "Text" (duration in minutes)
    required String measure, // Either "Tap" or "Text"
  }) async {
    try {
      final newGoal = {
        'title': title,
        'category': category,
        'description': description,
        'repetition': repetition, // 0 if "Text" is selected
        'duration': measureDuration, // 0 if "Tap" is selected
        'measure': measure, // Storing measure (Tap or Text)
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _userGoalsRef.push().set(newGoal);
    } catch (e) {
      throw Exception('Failed to add goal: $e');
    }
  }

  /// Fetch all goals for the current user
  Future<List<Map<String, dynamic>>> fetchGoals() async {
    try {
      final snapshot = await _userGoalsRef.get();
      if (snapshot.exists) {
        final goalsMap = Map<String, dynamic>.from(snapshot.value as Map);
        return goalsMap.entries.map((entry) {
          final goal = Map<String, dynamic>.from(entry.value as Map);
          return {
            'id': entry.key,
            ...goal,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch goals: $e');
    }
  }

  /// Delete a goal for the current user
  Future<void> deleteGoal(String id) async {
    try {
      await _userGoalsRef.child(id).remove();
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }


  Future<void> updateProgress({
  required String goalId,
  required double completed,
  required double total,
}) async {
  try {
    final progressRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(_auth.currentUser!.uid)
        .child('progress');

    await progressRef.child(goalId).set({
      'completed': completed,
      'total': total,
      'timestamp': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    throw Exception('Failed to update progress: $e');
  }
}


/// Update grade for the current user
Future<void> updateGrade(String grade) async {
  try {
    final gradeRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(_auth.currentUser!.uid)
        .child('grade');

    await gradeRef.set({
      'grade': grade,
      'timestamp': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    throw Exception('Failed to update grade: $e');
  }
}


 /// Fetch report for the current user
  Future<Map<String, dynamic>?> fetchReport() async {
    try {
      final reportRef = _userRef.child('report');
      final snapshot = await reportRef.get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }


/// Fetch progress for all tasks
Future<Map<String, Map<String, dynamic>>> fetchProgress() async {
  try {
    final progressRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(_auth.currentUser!.uid)
        .child('progress');
    final snapshot = await progressRef.get();

    if (snapshot.exists) {
      // Explicitly cast the fetched data
      final rawData = snapshot.value as Map<dynamic, dynamic>;
      return rawData.map((key, value) => MapEntry(
            key as String,
            Map<String, dynamic>.from(value as Map),
          ));
    }
    return {};
  } catch (e) {
    throw Exception('Failed to fetch progress: $e');
  }
}


/// Fetch user profile data
Future<Map<String, dynamic>?> fetchUserProfile() async {
  try {
    final userProfileRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(_auth.currentUser!.uid)
        .child('profile');

    final snapshot = await userProfileRef.get();

    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  } catch (e) {
    throw Exception('Failed to fetch user profile: $e');
  }
}

/// Fetch insights for the last month
Future<Map<String, int>> fetchLastMonthInsights() async {
  try {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1); // Start of last month
    final nextMonth = DateTime(now.year, now.month, 1); // Start of current month

    final snapshot = await _insightRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final gradeCounts = <String, int>{};

      for (final entry in data.entries) {
        final date = DateTime.parse(entry.key);
        if (date.isAfter(lastMonth) && date.isBefore(nextMonth)) {
          final insight = Map<String, dynamic>.from(entry.value as Map);
          final grade = insight['grade'] as String? ?? 'Unknown';
          gradeCounts[grade] = (gradeCounts[grade] ?? 0) + 1;
        }
      }

      return gradeCounts;
    }

    return {};
  } catch (e) {
    throw Exception('Failed to fetch last month insights: $e');
  }
}



/// Fetch grade for the current user
Future<Map<String, dynamic>?> fetchGrade() async {
  try {
    final gradeRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(_auth.currentUser!.uid)
        .child('grade');
    final snapshot = await gradeRef.get();

    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  } catch (e) {
    throw Exception('Failed to fetch grade: $e');
  }
}

/// Add or update a report in the database
Future<void> storeReport({
  required String grade,
  required String difficulty,
  required int points,
}) async {
  try {
    final reportRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(_auth.currentUser!.uid)
        .child('report');

    // Check if a report already exists
    final snapshot = await reportRef.get();

    if (snapshot.exists) {
      // Update the existing report
      await reportRef.update({
        'grade': grade,
        'difficulty': difficulty,
        'points': points,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else {
      // Create a new report entry if it doesn't exist
      await reportRef.set({
        'grade': grade,
        'difficulty': difficulty,
        'points': points,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  } catch (e) {
    throw Exception('Failed to store or update report: $e');
  }
}


 /// Uploads a profile picture to Firebase Storage and updates the database reference
  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      // Upload the file to Firebase Storage
      await storageRef.putFile(imageFile);

      // Get the download URL
      final downloadURL = await storageRef.getDownloadURL();

      // Update the user's profile picture URL in the database
      final profileRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile');

      await profileRef.update({'profilePicture': downloadURL});
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Fetches the profile picture URL for the current user
  Future<String?> fetchProfilePicture() async {
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
        return profileData['profilePicture'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch profile picture: $e');
    }
  }


}
