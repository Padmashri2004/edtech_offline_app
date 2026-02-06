import 'package:flutter/material.dart';
import 'notes_tab.dart';
import 'assignments_tab.dart';
import 'results_tab.dart';

class SharingResourcesScreen extends StatefulWidget {
  const SharingResourcesScreen({super.key});

  @override
  State<SharingResourcesScreen> createState() => _SharingResourcesScreenState();
}

class _SharingResourcesScreenState extends State<SharingResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Sharing Resources"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // ACTIVE tab
          unselectedLabelColor: Colors.white70, // INACTIVE tabs
          indicatorColor: Colors.white, // underline
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: "Notes"),
            Tab(text: "Assignments"),
            Tab(text: "Results"),
          ],
        ),
      ), // ✅ AppBar CLOSED PROPERLY
      body: TabBarView(
        controller: _tabController,
        children: const [
          NotesTab(),
          AssignmentsTab(),
          ResultsTab(),
        ],
      ),
    );
  }
}
