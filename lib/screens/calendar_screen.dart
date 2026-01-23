import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import '../services/localization_service.dart';
import '../services/ad_service.dart';
import '../widgets/task_item.dart';

// Calendar screen for daily tasks
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    // Cargar banner del Calendar al iniciar la pantalla
    Future.microtask(() => AdService.instance.loadCalendarBanner());
  }

  void _loadTasks() {
    final storage = context.read<StorageService>();
    setState(() {
      _tasks = storage.loadTasks(_selectedDate);
    });
  }

  void _saveTasks() {
    final storage = context.read<StorageService>();
    storage.saveTasks(_selectedDate, _tasks);
  }

  void _addTask(String description) {
    if (description.trim().isEmpty) return;

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description.trim(),
      date: _selectedDate,
    );

    setState(() {
      _tasks.add(newTask);
    });
    _saveTasks();
  }

  void _editTask(Task task, String newDescription) {
    if (newDescription.trim().isEmpty) return;

    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(description: newDescription.trim());
      }
    });
    _saveTasks();
  }

  void _toggleTask(Task task) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      }
    });
    _saveTasks();
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    _saveTasks();
  }

  void _showTaskDialog({Task? task}) {
    final controller = TextEditingController(text: task?.description ?? '');
    final localization = context.read<LocalizationService>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.t('calendar.form.title')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: localization.t('calendar.form.placeholder'),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.t('calendar.form.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (task == null) {
                _addTask(controller.text);
              } else {
                _editTask(task, controller.text);
              }
              Navigator.pop(context);
            },
            child: Text(localization.t('calendar.form.save')),
          ),
        ],
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDate, selectedDay)) {
      setState(() {
        _selectedDate = selectedDay;
        _focusedDate = focusedDay;
      });
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationService>();
    final storage = context.watch<StorageService>();
    final pomodorosCount = storage.getPomodorosCount(_selectedDate);

    // Escuchar cambios en AdService para actualizar cuando el banner esté listo
    context.watch<AdService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.t('calendar.title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Calendar - Más espacio para evitar que se corte la última fila
          Expanded(
            flex: 5,
            child: Card(
              margin: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: _focusedDate,
                  selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                  onDaySelected: _onDaySelected,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: Theme.of(context).textTheme.titleLarge!,
                  ),
                ),
              ),
            ),
          ),

          // Tasks section - Menos espacio, el calendario necesita más
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con info del día
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(_selectedDate),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (pomodorosCount > 0)
                              Text(
                                localization.t(
                                  'calendar.pomodorosToday',
                                  params: {'count': pomodorosCount.toString()},
                                ),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showTaskDialog(),
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Tasks list
                Expanded(
                  child: _tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_outlined,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                localization.t('calendar.empty'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return TaskItem(
                              task: task,
                              onToggle: () => _toggleTask(task),
                              onEdit: () => _showTaskDialog(task: task),
                              onDelete: () => _deleteTask(task),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // AdMob Banner en la parte inferior
          AdService.instance.getCalendarBannerWidget(),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
