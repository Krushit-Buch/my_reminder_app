import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder_app/HomePage/widgets/ReminderListWidget.dart';
import 'package:reminder_app/HomePage/widgets/addNewRemindersheet.dart';
import 'package:reminder_app/Provider/reminder_provider.dart';
import 'package:reminder_app/customGlobal.dart';
import 'package:reminder_app/models/Reminder.dart';

/// View Home Page - UI Components & Content
/// Contains all interactive UI elements and views
class ViewHomePage extends StatefulWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const ViewHomePage({
    Key? key,
    required this.selectedTab,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  State<ViewHomePage> createState() => _ViewHomePageState();
}

class _ViewHomePageState extends State<ViewHomePage> {
  final List<String> _tabs = ['All', 'Pending', 'Completed'];
  final List<String> _categories = [
    'All',
    'Work',
    'Personal',
    'Health',
    'Shopping',
  ];
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category Filter
        _buildCategoryFilter(),

        // Tab Bar
        _buildTabBar(),

        // Content Area
        Expanded(child: _buildContent()),

        // Add Button
        _buildAddButton(context),
      ],
    );
  }

  /// Build category filter chips
  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                backgroundColor: isSelected
                    ? Colors.blueAccent
                    : Colors.grey.shade200,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build tab bar for filtering reminders
  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[100],
      child: Row(
        children: List.generate(
          _tabs.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () {
                widget.onTabChanged(index);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: widget.selectedTab == index
                          ? Colors.blueAccent
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      fontWeight: widget.selectedTab == index
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: widget.selectedTab == index
                          ? Colors.blueAccent
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build content based on selected tab
  Widget _buildContent() {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        // Get reminders based on tab and category
        List<Reminder> reminders = _getFilteredReminders(provider);

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reminders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            return ReminderListWidget(
              reminder: reminders[index],
              onComplete: () async {
                await provider.completeReminder(reminders[index].id);
                if (mounted) {
                  CustomGlobal.showSnackBar(context, 'Reminder completed!');
                }
              },
              onDelete: () async {
                final confirmed = await CustomGlobal.showConfirmationDialog(
                  context,
                  title: 'Delete Reminder',
                  message: 'Are you sure you want to delete this reminder?',
                );
                if (confirmed && mounted) {
                  await provider.deleteReminder(reminders[index].id);
                  if (mounted) {
                    CustomGlobal.showSnackBar(context, 'Reminder deleted!');
                  }
                }
              },
              onEdit: () {
                _showEditBottomSheet(context, provider, reminders[index]);
              },
            );
          },
        );
      },
    );
  }

  /// Get filtered reminders based on selected tab and category
  List<Reminder> _getFilteredReminders(ReminderProvider provider) {
    List<Reminder> reminders = [];

    // Apply tab filter
    switch (widget.selectedTab) {
      case 1: // Pending
        reminders = provider.getPendingReminders();
        break;
      case 2: // Completed
        reminders = provider.getCompletedReminders();
        break;
      default: // All
        reminders = provider.reminders;
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      reminders = reminders
          .where((r) => r.category == _selectedCategory)
          .toList();
    }

    return reminders;
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No reminders yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create one to get started!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  /// Build add button
  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            _showAddReminderBottomSheet(context);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Reminder'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Show add reminder bottom sheet
  void _showAddReminderBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReminderBottomSheet(
        onReminderAdded: (title, description, time, category) async {
          final provider = context.read<ReminderProvider>();
          final success = await provider.addReminder(
            title: title,
            description: description,
            reminderTime: time,
            category: category,
          );

          if (mounted && success) {
            Navigator.pop(context);
            CustomGlobal.showSnackBar(context, 'Reminder added successfully!');
          } else if (mounted) {
            CustomGlobal.showErrorDialog(
              context,
              provider.errorMessage ?? 'Failed to add reminder',
            );
          }
        },
      ),
    );
  }

  /// Show edit reminder bottom sheet
  void _showEditBottomSheet(
    BuildContext context,
    ReminderProvider provider,
    Reminder reminder,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditReminderBottomSheet(
        reminder: reminder,
        onReminderUpdated: (title, description, time, category) async {
          final success = await provider.updateReminder(
            id: reminder.id,
            title: title,
            description: description,
            reminderTime: time,
            category: category,
          );

          if (mounted && success) {
            Navigator.pop(context);
            CustomGlobal.showSnackBar(
              context,
              'Reminder updated successfully!',
            );
          } else if (mounted) {
            CustomGlobal.showErrorDialog(
              context,
              provider.errorMessage ?? 'Failed to update reminder',
            );
          }
        },
      ),
    );
  }
}

/// Edit Reminder Bottom Sheet
class EditReminderBottomSheet extends StatefulWidget {
  final Reminder reminder;
  final Function(String, String, DateTime, String) onReminderUpdated;

  const EditReminderBottomSheet({
    Key? key,
    required this.reminder,
    required this.onReminderUpdated,
  }) : super(key: key);

  @override
  State<EditReminderBottomSheet> createState() =>
      _EditReminderBottomSheetState();
}

class _EditReminderBottomSheetState extends State<EditReminderBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDateTime;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    _descriptionController = TextEditingController(
      text: widget.reminder.description,
    );
    _selectedDateTime = widget.reminder.reminderTime;
    _selectedCategory = widget.reminder.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AddReminderBottomSheet(
      onReminderAdded: (title, description, time, category) {
        widget.onReminderUpdated(title, description, time, category);
      },
      initialTitle: _titleController.text,
      initialDescription: _descriptionController.text,
      initialDateTime: _selectedDateTime,
      initialCategory: _selectedCategory,
    );
  }
}
