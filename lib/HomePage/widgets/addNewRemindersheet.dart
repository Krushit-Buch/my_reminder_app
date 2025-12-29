import 'package:flutter/material.dart';
import 'package:reminder_app/customGlobal.dart';

/// Bottom sheet for adding a new reminder
class AddReminderBottomSheet extends StatefulWidget {
  final Function(String, String, DateTime, String) onReminderAdded;
  final String? initialTitle;
  final String? initialDescription;
  final DateTime? initialDateTime;
  final String? initialCategory;

  const AddReminderBottomSheet({
    Key? key,
    required this.onReminderAdded,
    this.initialTitle,
    this.initialDescription,
    this.initialDateTime,
    this.initialCategory,
  }) : super(key: key);

  @override
  State<AddReminderBottomSheet> createState() => _AddReminderBottomSheetState();
}

class _AddReminderBottomSheetState extends State<AddReminderBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDateTime;
  late String _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = ['Work', 'Personal', 'Health', 'Shopping'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _selectedDateTime =
        widget.initialDateTime ?? DateTime.now().add(const Duration(hours: 1));
    _selectedCategory = widget.initialCategory ?? 'Work';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 24),

            // Title Field
            _buildTitleField(),
            const SizedBox(height: 16),

            // Description Field
            _buildDescriptionField(),
            const SizedBox(height: 16),

            // Date & Time Picker
            _buildDateTimeSection(),
            const SizedBox(height: 16),

            // Category Selector
            _buildCategorySection(),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Build header
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.initialTitle != null ? 'Edit Reminder' : 'Add Reminder',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close),
        ),
      ],
    );
  }

  /// Build title input field
  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Title',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Enter reminder title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.title),
          ),
        ),
      ],
    );
  }

  /// Build description input field
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Enter reminder description',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 3,
          minLines: 2,
        ),
      ],
    );
  }

  /// Build date and time picker section
  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Time',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDatePicker()),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePicker()),
          ],
        ),
      ],
    );
  }

  /// Build date picker
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDateTime,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() {
            _selectedDateTime = DateTime(
              picked.year,
              picked.month,
              picked.day,
              _selectedDateTime.hour,
              _selectedDateTime.minute,
            );
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                CustomGlobal.formatDate(_selectedDateTime),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build time picker
  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        );
        if (picked != null) {
          setState(() {
            _selectedDateTime = DateTime(
              _selectedDateTime.year,
              _selectedDateTime.month,
              _selectedDateTime.day,
              picked.hour,
              picked.minute,
            );
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                CustomGlobal.formatTime(_selectedDateTime),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build category selector
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 5,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: CustomGlobal.getCategoryColor(category),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleAddReminder,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
        ),
      ],
    );
  }

  /// Handle add reminder action
  Future<void> _handleAddReminder() async {
    // Validation
    if (CustomGlobal.isEmpty(_titleController.text)) {
      CustomGlobal.showSnackBar(context, 'Please enter a title', isError: true);
      return;
    }

    if (!CustomGlobal.isFutureDateTime(_selectedDateTime)) {
      CustomGlobal.showSnackBar(
        context,
        'Please select a future time',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      widget.onReminderAdded(
        _titleController.text,
        _descriptionController.text,
        _selectedDateTime,
        _selectedCategory,
      );
    } catch (e) {
      if (mounted) {
        CustomGlobal.showSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
