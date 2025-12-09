// lib/recruitment.dart
import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'on_campus_page.dart';

class RecruitmentPage extends StatefulWidget {
  const RecruitmentPage({super.key});

  @override
  State<RecruitmentPage> createState() => _RecruitmentPageState();
}

class _RecruitmentPageState extends State<RecruitmentPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _logs = []; // logs kept internally (not shown in UI)

  @override
  void initState() {
    super.initState();
    _addLog('Recruitment page opened');
  }

  void _addLog(String message) {
    final ts = DateTime.now();
    _logs.insert(0, '${_formatTime(ts)} — $message'); // stored but not displayed
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}:"
        "${dt.second.toString().padLeft(2, '0')}";
  }

  void _onSearchChanged(String value) {
    if (value.trim().isNotEmpty) {
      _addLog("Search: \"$value\"");
    }
  }

  void _onMenuPressed() {
    _addLog("New Vacancy menu opened");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Menu"),
        content: const Text("New Vacancy clicked."),
        actions: [
          TextButton(
            onPressed: () {
              _addLog("Menu closed");
              Navigator.pop(context);
            },
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  Widget _quickActionButton(String title, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 214, 226, 231),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<UserProvider>(context, listen: false);

    return Sidebar(
      title: 'Recruitment',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // --------------------------
              // Search + Menu Button
              // --------------------------
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Search here...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _onMenuPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text("Menu"),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --------------------------
              // Quick Actions (Recruitment)
              // --------------------------
              Center(
                child: Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _quickActionButton('On Campus', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OnCampusPage()),
                      );
                    }),
                    _quickActionButton('Off Campus', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OffCampusPage()),
                      );
                    }),
                    _quickActionButton('Invite Tracker', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InviteTrackerPage()),
                      );
                    }),
                    _quickActionButton('Offer Letter', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OfferLetterPage()),
                      );
                    }),
                    _quickActionButton('HR Policy', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HRPolicyPage()),
                      );
                    }),
                    _quickActionButton('Exit', () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Exit Recruitment'),
                          content: const Text('Are you sure you want to exit recruitment?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _addLog('Exited recruitment');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Exited recruitment.')),
                                );
                              },
                              child: const Text('Exit'),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------
              // (Other recruitment UI goes here)
              // --------------------------
            ],
          ),
        ),
      ),
    );
  }
}

class OffCampusPage extends StatelessWidget {
  const OffCampusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Off Campus Recruitment')),
      body: const Center(child: Text('Off Campus recruitment screen (todo)')),
    );
  }
}

class InviteTrackerPage extends StatelessWidget {
  const InviteTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Tracker')),
      body: const Center(child: Text('Invite tracker (todo)')),
    );
  }
}

class OfferLetterPage extends StatelessWidget {
  const OfferLetterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offer Letter')),
      body: const Center(child: Text('Offer letter generation/view (todo)')),
    );
  }
}

class HRPolicyPage extends StatelessWidget {
  const HRPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HR Policy')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('HR Policy document / viewer (todo)'),
      ),
    );
  }
}
