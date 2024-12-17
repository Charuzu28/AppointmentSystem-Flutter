import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../widgets/drawer_widget.dart';

class AppointmentScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  final List<String> categories = [
    'Tuition Payment',
    'Request Form-137',
    'Counseling',
    'Enrollment Assistance',
    'Others',
  ];

  AppointmentScreen({super.key});

  void _createAppointment(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (selectedDate == null) return;

    TimeOfDay? selectedTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null) return;

    // Combine date and time
    final DateTime appointmentDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    String? selectedCategory = await showDialog<String>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Choose a Category'),
          children: categories
              .map((category) => SimpleDialogOption(
                    child: Text(category),
                    onPressed: () => Navigator.pop(context, category),
                  ))
              .toList(),
        );
      },
    );

    if (selectedCategory != null) {
      try {
        await _firestoreService.addAppointment({
          'category': selectedCategory,
          'date': Timestamp.fromDate(appointmentDateTime),
          'createdAt': Timestamp.now(),
          'userId': _authService.getCurrentUser()?.uid,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment added successfully!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding appointment: $e')),
          );
        }
      }
    }
  }

  void _editAppointment(BuildContext context, String docId,
      Map<String, dynamic> currentData) async {
    // Get current appointment date
    DateTime currentDate = (currentData['date'] as Timestamp).toDate();

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (selectedDate == null) return;

    TimeOfDay? selectedTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentDate),
    );

    if (selectedTime == null) return;

    // Combine date and time
    final DateTime appointmentDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    String? updatedCategory = await showDialog<String>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Choose a New Category'),
          children: categories
              .map((category) => SimpleDialogOption(
                    child: Text(category),
                    onPressed: () => Navigator.pop(context, category),
                  ))
              .toList(),
        );
      },
    );

    if (updatedCategory != null) {
      try {
        await _firestoreService.updateAppointment(docId, {
          'category': updatedCategory,
          'date': Timestamp.fromDate(appointmentDateTime),
          'updatedAt': Timestamp.now(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment updated successfully!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating appointment: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Appointment System'),
      ),
      drawer: user == null ? null : AppDrawer(userEmail: user.email ?? ''),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getAllAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No appointments found.'));
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final data = appointment.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(
                      _getCategoryIcon(data['category']),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    data['category'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${_formatDateTime(data['date'].toDate())}',
                      ),
                      if (data['updatedAt'] != null)
                        Text(
                          'Last updated: ${_formatDateTime(data['updatedAt'].toDate())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () =>
                            _editAppointment(context, appointment.id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _showDeleteConfirmation(context, appointment.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createAppointment(context),
        label: const Text('New Appointment'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.toLocal().toString().split('.')[0];
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tuition Payment':
        return Icons.payment;
      case 'Request Form-137':
        return Icons.description;
      case 'Counseling':
        return Icons.person;
      case 'Enrollment Assistance':
        return Icons.school;
      default:
        return Icons.event;
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, String docId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content:
            const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await _firestoreService.deleteAppointment(docId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment deleted successfully!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting appointment: $e')),
          );
        }
      }
    }
  }
}
