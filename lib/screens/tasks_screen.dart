import 'package:flutter/material.dart';
import 'home_screen.dart'; // For navigation
import 'chat_with_nova_screen.dart'; // For navigation
import 'inbox_screen.dart'; // For navigation
import 'profile_screen.dart';

// --- Data Model for a Task ---
class Task {
  final String title;
  final String dueDate;
  final Color priorityColor;
  bool isCompleted;

  Task({
    required this.title,
    required this.dueDate,
    required this.priorityColor,
    this.isCompleted = false,
  });
}

enum TaskFilter { all, pending, completed }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskFilter _currentFilter = TaskFilter.all;

  final List<Task> _tasks = [
    Task(title: 'Complete project proposal', dueDate: 'Due today at 5:00 PM', priorityColor: Colors.red),
    Task(title: 'Review design mockups', dueDate: 'Due tomorrow', priorityColor: Colors.orange),
    Task(title: 'Update team documentation', dueDate: 'Due next week', priorityColor: Colors.green),
    Task(title: 'Send weekly report', dueDate: 'Completed yesterday', priorityColor: Colors.green, isCompleted: true),
    Task(title: 'Prepare presentation slides', dueDate: 'Due today at 3:00 PM', priorityColor: Colors.red),
  ];

  List<Task> get _filteredTasks {
    switch (_currentFilter) {
      case TaskFilter.pending:
        return _tasks.where((task) => !task.isCompleted).toList();
      case TaskFilter.completed:
        return _tasks.where((task) => task.isCompleted).toList();
      case TaskFilter.all:
      default:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B145E),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
              onPressed: () => _showAddTaskSheet(context),
            ),
          ),
        ],
        backgroundColor: const Color(0xFF2B145E),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterButtons(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    final taskNameController = TextEditingController();
    DateTime? selectedDate;
    Color selectedPriority = Colors.red; // Default priority

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF2B145E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text('Add Task', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 24),
                  const Text('Task Name', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taskNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF4A1B7B).withOpacity(0.6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      hintText: 'Enter task name',
                      hintStyle: const TextStyle(color: Colors.white54)
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Due Date', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setModalState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A1B7B).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedDate != null ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}' : 'Select a date', style: const TextStyle(color: Colors.white)),
                          const Icon(Icons.calendar_today, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Priority', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [Colors.red, Colors.orange, Colors.green].map((color) {
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedPriority = color;
                          });
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: color,
                          child: selectedPriority == color ? const Icon(Icons.check, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (taskNameController.text.isNotEmpty) {
                          final newTask = Task(
                            title: taskNameController.text,
                            dueDate: selectedDate != null ? 'Due ${selectedDate!.day}/${selectedDate!.month}' : 'No due date',
                            priorityColor: selectedPriority,
                          );
                          setState(() {
                            _tasks.add(newTask);
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C6BFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Add Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildFilterButtons() {
    return Container(
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: const Color(0xFF4A1B7B).withOpacity(0.6),
            borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: TaskFilter.values.map((filter) {
            final isSelected = _currentFilter == filter;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentFilter = filter;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF9C6BFF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    filter.name[0].toUpperCase() + filter.name.substring(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ));
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A1B7B).withOpacity(0.6),
            borderRadius: BorderRadius.circular(15),
            border: Border(
              left: BorderSide(color: task.priorityColor, width: 5),
            ),
             boxShadow: [
              BoxShadow(
                color: task.priorityColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(-2, 2)
              )
            ]
          ),
          child: ListTile(
            title: Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(task.dueDate, style: const TextStyle(color: Colors.white70)),
            trailing: CircleAvatar(radius: 5, backgroundColor: task.priorityColor),
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                setState(() {
                  task.isCompleted = value!;
                });
              },
              activeColor: const Color(0xFF9C6BFF),
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              side: const BorderSide(color: Colors.white70, width: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4A1B7B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.home_outlined, color: Colors.white54, size: 28),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatWithNovaScreen()));
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 28),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen()));
            },
            icon: const Icon(Icons.email_outlined, color: Colors.white54, size: 28),
          ),
          IconButton(
            onPressed: () { /* Already on this screen */ },
            icon: const Icon(Icons.check_box, color: Color(0xFF9C6BFF), size: 28),
          ),
          IconButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            icon: const Icon(Icons.person_outline, color: Colors.white54, size: 28),
          ),
        ],
      ),
    );
  }
}
