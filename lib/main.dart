import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

void main() => runApp(HabitTrackerApp());

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: HabitTrackerHome(),
    );
  }
}

class Habit {
  String name;
  Set<String> completedDates; // store as 'yyyy-MM-dd'

  Habit({required this.name, required this.completedDates});

  Map<String, dynamic> toJson() => {
    'name': name,
    'completedDates': completedDates.toList(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      name: json['name'],
      completedDates: Set<String>.from(json['completedDates']),
    );
  }
}

class HabitTrackerHome extends StatefulWidget {
  const HabitTrackerHome({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HabitTrackerHomeState createState() => _HabitTrackerHomeState();
}

class _HabitTrackerHomeState extends State<HabitTrackerHome> {
  List<Habit> habits = [];
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _habitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  void _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('habits');
    if (data != null) {
      final decoded = json.decode(data) as List;
      setState(() {
        habits = decoded.map((e) => Habit.fromJson(e)).toList();
      });
    }
  }

  void _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(habits.map((h) => h.toJson()).toList());
    prefs.setString('habits', encoded);
  }

  void _addHabit(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      habits.add(Habit(name: name, completedDates: {}));
      _habitController.clear();
      _saveHabits();
    });
  }

  void _toggleCompletion(Habit habit) {
    String dateKey = _selectedDate.toIso8601String().split('T')[0];
    setState(() {
      if (habit.completedDates.contains(dateKey)) {
        habit.completedDates.remove(dateKey);
      } else {
        habit.completedDates.add(dateKey);
      }
      _saveHabits();
    });
  }

  void _resetHabit(Habit habit) {
    setState(() {
      habit.completedDates.clear();
      _saveHabits();
    });
  }

  bool _isCompleted(Habit habit) {
    String dateKey = _selectedDate.toIso8601String().split('T')[0];
    return habit.completedDates.contains(dateKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Habit Tracker"), centerTitle: true),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2022),
            lastDay: DateTime.utc(2030),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() => _selectedDate = selectedDay);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.teal.shade200,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _habitController,
                    decoration: InputDecoration(
                      hintText: 'Add new habit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  child: Icon(Icons.add),
                  onPressed: () => _addHabit(_habitController.text),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                habits.isEmpty
                    ? Center(child: Text("No habits yet."))
                    : ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        final completed = _isCompleted(habit);
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(habit.name),
                            subtitle: Text(
                              completed
                                  ? "Done for ${_selectedDate.toLocal().toString().split(' ')[0]}"
                                  : "Not done today",
                            ),
                            leading: IconButton(
                              icon: Icon(
                                completed
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: completed ? Colors.green : Colors.grey,
                              ),
                              onPressed: () => _toggleCompletion(habit),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.refresh, color: Colors.red),
                              onPressed: () => _resetHabit(habit),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
