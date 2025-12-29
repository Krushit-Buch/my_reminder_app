import 'package:flutter/material.dart';
import 'ViewHomePage.dart';

/// Master Home Page - Scaffold & Layout Structure
/// Handles overall layout, app bar, and navigation
class MasterHomePage extends StatefulWidget {
  const MasterHomePage({Key? key}) : super(key: key);

  @override
  State<MasterHomePage> createState() => _MasterHomePageState();
}

class _MasterHomePageState extends State<MasterHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade100,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Reminders',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ViewHomePage(
          selectedTab: _selectedIndex,
          onTabChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
