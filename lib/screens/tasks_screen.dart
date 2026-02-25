import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/nlp_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_bottom_nav.dart';
import '../models/local_task.dart';
import '../services/task_storage_service.dart';

enum TaskFilter { all, pending, completed }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}
Future<void> checkVoiceCommand(String userInput) async {
  final nlp = NLPService();

  // 1. Model Loading Check (Wait if not ready)
  if (!nlp.isReady) {
    print("⏳ NOVA Engine is starting...");
    await nlp.initModel();
  }

  // 2. Prediction (Pure Logic)
  // Note: userInput ko parameter se lena behtar hai bajaye "Light jala do" hardcode karne ke
  String result = nlp.predictIntent(userInput);

  print("🧠 JARVIS NLP Output: [$result] for Input: [$userInput]");

  // 3. Action Logic (Switch Case is better for many intents)
  switch (result) {
    case "TURN_ON":
      _handleFlashlight(true);
      break;

    case "TURN_OFF":
      _handleFlashlight(false);
      break;

    case "ADD_TASK":
      print("📝 Logic: Opening Task Creator...");
      // TaskStorageService().addTask(...);
      break;

    case "uncertain":
      print("🤔 NOVA: Sir, mujhe samajh nahi aaya. Dobara kahiye?");
      // TTSService.speak("Sorry sir, I didn't quite catch that.");
      break;

    case "loading":
    case "error":
      print("⚠️ NLP System is having trouble.");
      break;

    default:
      print("ℹ️ Intent recognized but no logic defined for: $result");
  }
}

// Helper function for clean code
void _handleFlashlight(bool turnOn) {
  if (turnOn) {
    print("🔦 Flashlight ON trigger!");
    // TorchController().toggle();
  } else {
    print("🌑 Flashlight OFF trigger!");
  }
}
class _TasksScreenState extends State<TasksScreen> {
  TaskFilter _currentFilter = TaskFilter.all;
  final TaskStorageService _storageService = TaskStorageService();
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2B145E), Color(0xFF4A1B7B), Color(0xFF6A1FB0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Reminders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.white70),
              onPressed: () {
                _storageService.syncTasks();
                _storageService.hydrateFromBackend();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Syncing with server..."), duration: Duration(seconds: 1)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
              onPressed: () => _showAddTaskSheet(context),
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        // 🔥 FIX: FutureBuilder ensures the box is open before UI tries to read it
        body: FutureBuilder(
          future: Hive.openBox<LocalTask>('tasksBox'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return _buildTaskContent();
            } else {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
          },
        ),
        bottomNavigationBar: const CustomBottomNav(currentItem: NavItem.tasks),
      ),
    );
  }

  // Separate function for the main body logic
  Widget _buildTaskContent() {
    return Column(
      children: [
        _buildFilterButtons(),
        const SizedBox(height: 16),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: Hive.box<LocalTask>('tasksBox').listenable(),
            builder: (context, Box<LocalTask> box, _) {
              List<LocalTask> tasks = box.values.where((t) =>
              t.userId == _currentUserId && t.type == 'reminder'
              ).toList();

              if (_currentFilter == TaskFilter.pending) {
                tasks = tasks.where((t) => !t.isCompleted).toList();
              } else if (_currentFilter == TaskFilter.completed) {
                tasks = tasks.where((t) => t.isCompleted).toList();
              }

              if (tasks.isEmpty) {
                return const Center(child: Text("No reminders found", style: TextStyle(color: Colors.white70)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  Color pColor = task.status == 'red' ? Colors.red : (task.status == 'orange' ? Colors.orange : Colors.green);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A1B7B).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(15),
                      border: Border(left: BorderSide(color: pColor, width: 5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          if (task.isSynced)
                            const Icon(Icons.cloud_done, color: Colors.greenAccent, size: 16),
                        ],
                      ),
                      subtitle: Text(
                          task.remindAt != null
                              ? 'Due: ${DateFormat('dd MMM, hh:mm a').format(task.remindAt!)}'
                              : 'No due date',
                          style: const TextStyle(color: Colors.white70)
                      ),
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (value) {
                          _storageService.updateTaskStatus(task.id, value! ? 'completed' : 'pending');
                        },
                        activeColor: const Color(0xFF9C6BFF),
                        checkColor: Colors.white,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
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
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    final taskNameController = TextEditingController();
    DateTime? selectedDate;
    Color selectedPriority = Colors.red;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 16, left: 16, right: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF2B145E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text('Add Reminder', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 24),
                  const Text('Reminder Detail', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taskNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF4A1B7B).withOpacity(0.6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        hintText: 'Enter Reminder Detail',
                        hintStyle: const TextStyle(color: Colors.white54)
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Reminder Date & Time', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setModalState(() {
                            selectedDate = DateTime(
                              pickedDate.year, pickedDate.month, pickedDate.day,
                              pickedTime.hour, pickedTime.minute,
                            );
                          });
                        }
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
                          Text(
                              selectedDate != null
                                  ? DateFormat('dd/MM/yyyy  at  hh:mm a').format(selectedDate!)
                                  : 'Select Date & Time',
                              style: const TextStyle(color: Colors.white)
                          ),
                          const Icon(Icons.calendar_month, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A1B7B).withOpacity(0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedDate = DateTime.now().add(const Duration(minutes: 10));
                          });
                        },
                        child: const Text('10 mins', style: TextStyle(color: Colors.white70)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A1B7B).withOpacity(0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedDate = DateTime.now().add(const Duration(minutes: 30));
                          });
                        },
                        child: const Text('30 mins', style: TextStyle(color: Colors.white70)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A1B7B).withOpacity(0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedDate = DateTime.now().add(const Duration(hours: 1));
                          });
                        },
                        child: const Text('1 hour', style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Priority', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [Colors.red, Colors.orange, Colors.green].map((color) {
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedPriority = color),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: color,
                          child: selectedPriority == color ? const Icon(Icons.check, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await  checkVoiceCommand("USman ko call kr");
                        FocusScope.of(context).unfocus();

                        if (taskNameController.text.isNotEmpty) {
                          String pString = selectedPriority == Colors.red ? 'red' : (selectedPriority == Colors.orange ? 'orange' : 'green');

                          // 🔥 TaskStorageService already handles all notification logic internally!
                          await _storageService.addTask(
                            title: taskNameController.text,
                            type: 'reminder',
                            status: pString,
                            remindTime: selectedDate,
                          );

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Reminder Saved!")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C6BFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Confirm Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
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
                onTap: () => setState(() => _currentFilter = filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF9C6BFF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    filter.name[0].toUpperCase() + filter.name.substring(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                ),
              ),
            );
          }).toList(),
        )
    );
  }
}