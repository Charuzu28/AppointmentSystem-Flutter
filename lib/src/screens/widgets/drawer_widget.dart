import 'package:flutter/material.dart';
import 'package:appointment_system/src/screens/auth/signin_screen.dart';
import '../../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final String? userEmail;
  final AuthService _authService = AuthService();

  AppDrawer({super.key, required this.userEmail});

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _authService.signOut();

      // Pop the loading dialog
      if (context.mounted) {
        Navigator.pop(context);

        // Navigate to sign in screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false, // This clears the navigation stack
        );
      }
    } catch (e) {
      // Pop the loading dialog if it's showing
      if (context.mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = userEmail?.split('@').first ?? 'User';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            accountEmail: Text(
              userEmail ?? 'No email available',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            accountName: Text(
              userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.blue),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: const Text('My Appointments'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    // Add navigation to appointments view if needed
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.blue),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    // Add navigation to settings screen if needed
                  },
                ),
              ],
            ),
          ),
          // Bottom section with logout
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _handleSignOut(context),
            ),
          ),
        ],
      ),
    );
  }
}
