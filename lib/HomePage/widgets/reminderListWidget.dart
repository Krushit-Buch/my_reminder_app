import 'package:flutter/material.dart';
import 'package:reminder_app/customGlobal.dart';
import 'package:reminder_app/models/Reminder.dart';

/// Widget for displaying a single reminder in list
class ReminderListWidget extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ReminderListWidget({
    Key? key,
    required this.reminder,
    required this.onComplete,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        reminder.reminderTime.isBefore(DateTime.now()) && !reminder.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: _buildLeading(isOverdue),
        title: _buildTitle(),
        subtitle: _buildSubtitle(),
        trailing: _buildTrailing(context),
        onTap: onEdit,
      ),
    );
  }

  /// Build leading checkbox
  Widget _buildLeading(bool isOverdue) {
    return GestureDetector(
      onTap: onComplete,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: reminder.isCompleted
                ? Colors.green
                : isOverdue
                ? Colors.red
                : Colors.grey,
            width: 2,
          ),
          color: reminder.isCompleted ? Colors.green : Colors.transparent,
        ),
        child: reminder.isCompleted
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }

  /// Build title with category badge
  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                reminder.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  decoration: reminder.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: reminder.isCompleted ? Colors.grey : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: CustomGlobal.getCategoryColor(reminder.category),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                reminder.category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CustomGlobal.getCategoryColor(reminder.category),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build subtitle with description and time
  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          reminder.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            decoration: reminder.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          reminder.reminderTime.isBefore(DateTime.now()) &&
                  !reminder.isCompleted
              ? '⚠️ Overdue'
              : CustomGlobal.getRelativeTime(reminder.reminderTime),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color:
                reminder.reminderTime.isBefore(DateTime.now()) &&
                    !reminder.isCompleted
                ? Colors.red
                : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  /// Build trailing action buttons
  Widget _buildTrailing(BuildContext context) {
    return PopupMenuButton(
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
