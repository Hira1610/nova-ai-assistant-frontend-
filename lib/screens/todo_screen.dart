import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_task.dart';
import '../services/task_storage_service.dart';

enum TaskFilter { all, pending, completed }

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TaskStorageService _storageService = TaskStorageService();
  TaskFilter _currentFilter = TaskFilter.all;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  void _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId') ?? 'guest_user';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIC: Database mein Save ---
  void _addTask(String title) async {
    if (title.isNotEmpty) {
      // Yahan 'type' todo dena lazmi hai taaki sync logic sahi chale
      await _storageService.addTask(
        title: title,
        type: 'todo', // <--- Ye batana zaroori hai
        status: 'pending',
      );
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
        title: const Text('My Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        // TodoScreen ke AppBar mein title ke sath ye add karein:
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white70),
            onPressed: () {
              _storageService.syncTasks(); // Manual sync button
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Syncing with server...")),
              );
            },
          ),
        ],
        backgroundColor: const Color(0xFF2B145E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildFilterButtons(),
            const SizedBox(height: 16),

            // --- LOGIC: Hive Se Data Load Karna ---
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<LocalTask>('tasksBox').listenable(),
                builder: (context, Box<LocalTask> box, _) {

                  // UserId aur Type 'todo' ke mutabiq filter
                  List<LocalTask> tasks = box.values.where((t) =>
                  t.type == 'todo' && t.userId == _currentUserId
                  ).toList();

                  // Filter Logic (All/Pending/Completed)
                  if (_currentFilter == TaskFilter.pending) {
                    tasks = tasks.where((t) => !t.isCompleted).toList();
                  } else if (_currentFilter == TaskFilter.completed) {
                    tasks = tasks.where((t) => t.isCompleted).toList();
                  }

                  // Search Logic
                  final query = _searchController.text.toLowerCase();
                  if (query.isNotEmpty) {
                    tasks = tasks.where((t) => t.title.toLowerCase().contains(query)).toList();
                  }

                  if (tasks.isEmpty) {
                    return const Center(child: Text("No tasks found", style: TextStyle(color: Colors.white70)));
                  }

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: const Color(0xFF4A1B7B).withOpacity(0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          title: Text(
                            task.title,
                            style: TextStyle(
                              color: Colors.white,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                              decorationColor: Colors.white54,
                            ),
                          ),
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (value) {
                              _storageService.updateTaskStatus(task.id, value! ? 'completed' : 'pending');
                            },
                            activeColor: const Color(0xFF9C6BFF),
                            checkColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          // --- DELETE BUTTON ---
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _storageService.deleteTask(task.id),
                          ),
                        ),
                      );
                    },
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

  // --- UI Widgets wahi hain jo aapne diye thay ---
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF4A1B7B).withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
      child: ToggleButtons(
        isSelected: [_currentFilter == TaskFilter.all, _currentFilter == TaskFilter.pending, _currentFilter == TaskFilter.completed],
        onPressed: (index) => setState(() => _currentFilter = TaskFilter.values[index]),
        borderRadius: BorderRadius.circular(30),
        selectedColor: Colors.white,
        color: Colors.white70,
        fillColor: const Color(0xFF9C6BFF),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4A1B7B),
        title: const Text('New Task', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Enter task title', hintStyle: TextStyle(color: Colors.white70)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addTask(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFF9C6BFF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}