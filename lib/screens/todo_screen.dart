import 'package:flutter/material.dart';

// --- Data Model for a Task ---
class Task {
  final String title;
  bool isDone;

  Task({required this.title, this.isDone = false});
}

enum TaskFilter { all, pending, completed }

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _searchController = TextEditingController();
  TaskFilter _currentFilter = TaskFilter.all;

  // Master list of tasks
  final List<Task> _tasks = [
    Task(title: 'Finalize project report', isDone: true),
    Task(title: 'Call the design team for a sync-up'),
    Task(title: 'Review Q4 marketing analytics'),
    Task(title: 'Submit expense report', isDone: true),
    Task(title: 'Draft the weekly newsletter'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addTask(String title) {
    if (title.isNotEmpty) {
      final newTask = Task(title: title);
      setState(() {
        _tasks.add(newTask);
      });
    }
  }

  List<Task> get _filteredTasks {
    final query = _searchController.text.toLowerCase();
    List<Task> filtered = [];

    switch (_currentFilter) {
      case TaskFilter.pending:
        filtered = _tasks.where((task) => !task.isDone).toList();
        break;
      case TaskFilter.completed:
        filtered = _tasks.where((task) => task.isDone).toList();
        break;
      case TaskFilter.all:
      default:
        filtered = List.from(_tasks);
        break;
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
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
        title: const Text('My Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2B145E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),
            const SizedBox(height: 16),
            // Filter Buttons
            _buildFilterButtons(),
            const SizedBox(height: 16),
            // Task List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFF4A1B7B).withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          color: Colors.white,
                          decoration: task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                          decorationColor: Colors.white54,
                        ),
                      ),
                      trailing: Checkbox(
                        value: task.isDone,
                        onChanged: (value) {
                          setState(() {
                            task.isDone = value!;
                          });
                        },
                        activeColor: const Color(0xFF9C6BFF),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: const Color(0xFF9C6BFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF4A1B7B).withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4A1B7B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(30)
      ),
      child: ToggleButtons(
        isSelected: [
          _currentFilter == TaskFilter.all,
          _currentFilter == TaskFilter.pending,
          _currentFilter == TaskFilter.completed,
        ],
        onPressed: (index) {
          setState(() {
            _currentFilter = TaskFilter.values[index];
          });
        },
        borderRadius: BorderRadius.circular(30),
        selectedColor: Colors.white,
        color: Colors.white70,
        fillColor: const Color(0xFF9C6BFF),
        splashColor: const Color(0xFF9C6BFF).withOpacity(0.4),
        borderColor: Colors.transparent,
        selectedBorderColor: Colors.transparent,
        children: const [
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('All')),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Pending')),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Completed')),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF4A1B7B),
              title: const Text('New Task', style: TextStyle(color: Colors.white)),
              content: TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter task title',
                  hintStyle: const TextStyle(color: Colors.white70),
                  errorText: errorText,
                  errorStyle: const TextStyle(color: Colors.redAccent),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.isEmpty) {
                      setStateInDialog(() {
                        errorText = 'Please enter a task title';
                      });
                    } else {
                      _addTask(controller.text);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add', style: TextStyle(color: Color(0xFF9C6BFF), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
