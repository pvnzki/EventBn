import 'package:flutter/material.dart';

/// Test User Switcher - For development/testing only
/// This widget allows you to quickly switch between test users
/// to simulate User A vs User B scenarios
class TestUserSwitcher extends StatefulWidget {
  final Function(TestUser) onUserChanged;
  final TestUser currentUser;

  const TestUserSwitcher({
    Key? key,
    required this.onUserChanged,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<TestUserSwitcher> createState() => _TestUserSwitcherState();
}

class _TestUserSwitcherState extends State<TestUserSwitcher> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'TEST MODE - User Switcher',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildUserButton(TestUsers.userA),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUserButton(TestUsers.userB),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Current: ${widget.currentUser.name}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserButton(TestUser user) {
    final isSelected = widget.currentUser.id == user.id;
    
    return ElevatedButton(
      onPressed: () => widget.onUserChanged(user),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? user.color : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(user.icon, size: 16),
          const SizedBox(height: 2),
          Text(
            user.name,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Test User Model
class TestUser {
  final String id;
  final String name;
  final String token;
  final Color color;
  final IconData icon;

  const TestUser({
    required this.id,
    required this.name,
    required this.token,
    required this.color,
    required this.icon,
  });
}

/// Predefined Test Users
class TestUsers {
  static const userA = TestUser(
    id: 'user-a',
    name: 'Alice',
    token: 'test-token-user-a', // Replace with real JWT
    color: Colors.blue,
    icon: Icons.person,
  );

  static const userB = TestUser(
    id: 'user-b', 
    name: 'Bob',
    token: 'test-token-user-b', // Replace with real JWT
    color: Colors.green,
    icon: Icons.person_outline,
  );

  static List<TestUser> get all => [userA, userB];
}

/// Service to manage current test user
class TestUserService {
  static TestUser _currentUser = TestUsers.userA;
  
  static TestUser get currentUser => _currentUser;
  
  static void switchTo(TestUser user) {
    _currentUser = user;
    // Update your auth service with the new user token
    // AuthService.setToken(user.token);
  }
  
  static String get currentUserToken => _currentUser.token;
  static String get currentUserId => _currentUser.id;
  static String get currentUserName => _currentUser.name;
}