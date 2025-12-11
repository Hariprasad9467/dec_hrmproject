// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'package:zeai_project/main.dart'; // ✅ Import main.dart
// //import 'package:zeai_project/super_admin.dart';
// import 'package:zeai_project/app_routes.dart';
// import 'package:zeai_project/superadmin_dashboard.dart';
// import 'dart:convert';
// // import 'package:your_app/admin_notification.dart';

// import 'user_provider.dart';
// import 'employee_dashboard.dart';
// import 'admin_dashboard.dart';
// import 'leave_management.dart';
// import 'emp_payroll.dart';
// import 'employee_profile.dart';
// import 'employee_directory.dart';
// import 'reports.dart';
// import 'employeenotification.dart';
// //import 'notification.dart';
// import 'admin_notification.dart';
// import 'attendance_login.dart';
// import 'company_events.dart';

// class Sidebar extends StatefulWidget {
//   final Widget body;
//   final String title;

//   const Sidebar({super.key, required this.body, required this.title});

//   @override
//   State<Sidebar> createState() => _SidebarState();
// }

// class _SidebarState extends State<Sidebar> {
//   String employeeName = "Employee";
//   String position = "Position";

//   @override
//   void initState() {
//     super.initState();
//     fetchEmployeeDetails();
//   }

//   Future<void> fetchEmployeeDetails() async {
//     final userProvider = Provider.of<UserProvider>(context, listen: false);
//     final employeeId = userProvider.employeeId;

//     if (employeeId == null) return;

//     try {
//       final response = await http.get(
//         Uri.parse(
//           '$apiBaseUrl/api/get-employee-name/$employeeId',
//         ), // ✅ Use apiBaseUrl
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           employeeName = data['employeeName'] ?? 'Employee';
//           position = data['position'] ?? 'Position';
//         });
//         // ✅ Update provider safely after API call
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           userProvider.setPosition(position);
//           userProvider.setDomain(data['domain'] ?? '');
//         });
//       } else {
//         print('❌ Failed to fetch name: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error fetching employee name: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

//     return Scaffold(
//       key: scaffoldKey,
//       backgroundColor: const Color(0xFF0F1020),
//       drawer: _buildSidebar(context),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildHeader(context),
//           Padding(
//             padding: const EdgeInsets.only(left: 20, top: 10),
//             child: ElevatedButton.icon(
//               onPressed: () => scaffoldKey.currentState?.openDrawer(),
//               icon: const Icon(Icons.menu),
//               label: const Text('Menu'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.deepPurple,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Expanded(child: widget.body),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     final Map<String, Widget> pageMap = {
//       //  'Dashboard': const EmployeeDashboard(),
//       // 'TLDashboard': const AdminDashboard(),
//       // 'SuperAdminDashboard': const SuperAdminDashboard(),
//       'Leave Management': const LeaveManagement(),
//       'Payroll Management': const EmpPayroll(),
//       'Attendance System': AttendanceLoginPage(),
//       'Reports & Analytics': ReportsAnalyticsPage(),
//       'Employee Directory': EmployeeDirectoryPage(),
//       'Notifications': EmployeeNotificationsPage(
//         empId:
//             Provider.of<UserProvider>(context, listen: false).employeeId ?? '',
//       ),
//       // 'AdminNotification': AdminNotificationsPage(
//       //   empId:
//       //       Provider.of<UserProvider>(context, listen: false).employeeId ?? '',
//       // ),
//       'Employee Profile': EmployeeProfilePage(),
//       'Company Events': const CompanyEventsScreen(),
//     };

//     final List<String> options = pageMap.keys.toList();

//     return Container(
//       height: 80,
//       color: const Color(0xFF0F1020),
//       padding: const EdgeInsets.symmetric(horizontal: 30),
//       child: Row(
//         children: [
//           // Left logo
//           Expanded(
//             flex: 1,
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Image.asset('assets/logo_z.png', height: 40),
//             ),
//           ),
//           // Center logo
//           Expanded(
//             flex: 2,
//             child: Center(
//               child: Image.asset('assets/logo_zeai.png', height: 70),
//             ),
//           ),
//           // Right search bar
//           Expanded(
//             flex: 1,
//             child: Align(
//               alignment: Alignment.centerRight,
//               child: SizedBox(
//                 width: 250,
//                 child: Autocomplete<String>(
//                   optionsBuilder: (TextEditingValue textEditingValue) {
//                     if (textEditingValue.text.isEmpty) {
//                       return const Iterable<String>.empty();
//                     }
//                     return options.where(
//                       (String option) => option.toLowerCase().contains(
//                         textEditingValue.text.toLowerCase(),
//                       ),
//                     );
//                   },
//                   onSelected: (String selected) {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => pageMap[selected]!),
//                     );
//                   },
//                   fieldViewBuilder:
//                       (context, controller, focusNode, onEditingComplete) {
//                         return TextField(
//                           controller: controller,
//                           focusNode: focusNode,
//                           onEditingComplete: onEditingComplete,
//                           style: const TextStyle(color: Colors.white),
//                           decoration: InputDecoration(
//                             hintText: 'Search here...',
//                             hintStyle: const TextStyle(color: Colors.white70),
//                             prefixIcon: const Icon(
//                               Icons.search,
//                               color: Colors.white70,
//                             ),
//                             filled: true,
//                             fillColor: const Color(0xFF2D2F41),
//                             contentPadding: const EdgeInsets.symmetric(
//                               vertical: 0,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(30),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         );
//                       },
//                   optionsViewBuilder: (context, onSelected, options) {
//                     return Align(
//                       alignment: Alignment.topRight,
//                       child: Container(
//                         margin: const EdgeInsets.only(top: 10),
//                         child: Material(
//                           color: const Color(0xFF2D2F41),
//                           elevation: 8,
//                           borderRadius: BorderRadius.circular(10),
//                           child: ConstrainedBox(
//                             constraints: const BoxConstraints(maxHeight: 200),
//                             child: ListView.builder(
//                               padding: EdgeInsets.zero,
//                               shrinkWrap: true,
//                               itemCount: options.length,
//                               itemBuilder: (context, index) {
//                                 final option = options.elementAt(index);
//                                 return InkWell(
//                                   onTap: () => onSelected(option),
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 16,
//                                       vertical: 12,
//                                     ),
//                                     child: Text(
//                                       option,
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // inside _buildSidebar(...)
//   Widget _buildSidebar(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context);
//     final role = userProvider.position ?? position; // fallback

//     // Select Dashboard based on role
//     Widget getDashboard() {
//       if (role == "TL") return const AdminDashboard();
//       if (role == "Founder" || role == "HR") return const SuperAdminDashboard();
//       return const EmployeeDashboard();
//     }

//     String getDashboardRoute() {
//       if (role == "TL") return AppRoutes.adminDashboard;
//       if (role == "Founder" || role == "HR") return AppRoutes.superAdmin;
//       return AppRoutes.dashboard;
//     }

//     return Drawer(
//       child: Container(
//         width: 180,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topRight: Radius.circular(10),
//             bottomRight: Radius.circular(10),
//           ),
//         ),
//         child: ListView(
//           children: [
//             const SizedBox(height: 40),
//             ListTile(
//               leading: const CircleAvatar(
//                 backgroundImage: AssetImage('assets/profile.png'),
//               ),
//               title: Text(
//                 employeeName,
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Text(
//                 position,
//                 style: const TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//             ),
//             const Divider(),

//             // 👇 Role-based dashboard
//             _sidebarTile(Icons.dashboard, 'Dashboard', context, getDashboardRoute()),

//             // Common menu items for all
//             _sidebarTile(
//               Icons.calendar_month,
//               'Leave Management',
//               context,
//               AppRoutes.leaveList,
//             ),
//             _sidebarTile(
//               Icons.payments,
//               'Payroll Management',
//               context,
//               AppRoutes.empPayroll,
//             ),
//             _sidebarTile(
//               Icons.how_to_reg,
//               'Attendance System',
//               context,
//               AppRoutes.attendanceLogin,
//             ),
//             _sidebarTile(
//               Icons.analytics,
//               'Reports & Analytics',
//               context,
//               AppRoutes.reports,
//             ),
//             _sidebarTile(
//               Icons.people,
//               'Employee Directory',
//               context,
//               AppRoutes.employeeDirectory,
//             ),
//             // 🔔 Notifications: admin/superadmin get AdminNotifications
//             _sidebarTile(
//               Icons.notifications,
//               'Notifications',
//               context,
//               (role == "TL" || role == "Founder" || role == "HR")
//                   ? AppRoutes.adminNotification
//                   : AppRoutes.employeeNotification,
//             ),
//             _sidebarTile(
//               Icons.person,
//               'Employee Profile',
//               context,
//               AppRoutes.employeeProfile,
//             ),
//             _sidebarTile(
//               Icons.event,
//               'Company Events',
//               context,
//               AppRoutes.companyEvents,
//             ),
//           ],
//       ),
//     ));
//   }

//   Widget _sidebarTile(
//     IconData icon,
//     String title,
//     BuildContext context,
//     String routeName,
//   ) {
//     return ListTile(
//       leading: Icon(icon),
//       title: Text(title),
//       onTap: () {
//         Navigator.pop(context); // Close drawer
//         Navigator.pushReplacementNamed(context, routeName);
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'user_provider.dart';
import 'employee_dashboard.dart';
import 'admin_dashboard.dart';
import 'leave_management.dart';
import 'emp_payroll.dart';
import 'employee_profile.dart';
import 'employee_directory.dart';
import 'reports.dart';
import 'employeenotification.dart';
import 'admin_notification.dart';
import 'attendance_login.dart';
import 'company_events.dart';
import 'superadmin_dashboard.dart';

class Sidebar extends StatefulWidget {
  final Widget body;
  final String title;

  const Sidebar({super.key, required this.body, required this.title});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String employeeName = "Employee";
  String position = "Position";

  @override
  void initState() {
    super.initState();
    fetchEmployeeDetails();
  }

  Future<void> fetchEmployeeDetails() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final employeeId = userProvider.employeeId;

    if (employeeId == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://dec-hrmproject.onrender.com/apply/get-employee-name/$employeeId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          employeeName = data['employeeName'] ?? 'Employee';
          position = data['position'] ?? 'Position';
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          userProvider.setPosition(position);
          userProvider.setDomain(data['domain'] ?? '');
        });
      }
    } catch (e) {
      print('Error fetching employee name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFF0F1020),
      drawer: _buildSidebar(context),

      // FIXED: Replace Column with SafeArea + Stack so body gets full height
      body: SafeArea(
        child: Stack(
          children: [
            // BODY — now full height with no restriction
            Positioned.fill(
              top: 80, // header height
              child: widget.body,
            ),

            // FIXED HEADER — pinned
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 80,
              child: _buildHeader(context, scaffoldKey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GlobalKey<ScaffoldState> key) {
    return Container(
      height: 80,
      color: const Color(0xFF0F1020),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Menu Button
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => key.currentState?.openDrawer(),
          ),
          const SizedBox(width: 20),

          // App logos
          Image.asset('assets/logo_z.png', height: 40),
          const Spacer(),
          Image.asset('assets/logo_zeai.png', height: 60),
          const Spacer(),

          // Search bar
          SizedBox(
            width: 230,
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2D2F41),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final role = userProvider.position ?? position;

    Widget getDashboard() {
      if (role == "TL") return const AdminDashboard();
      if (role == "Founder" || role == "HR") return const SuperAdminDashboard();
      return const EmployeeDashboard();
    }

    return Drawer(
      width: 200,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 40),
          ListTile(
            leading: const CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
            ),
            title: Text(employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(position),
          ),
          const Divider(),

          _tile(Icons.dashboard, 'Dashboard', getDashboard()),
          _tile(Icons.calendar_month, 'Leave Management', const LeaveManagement()),
          _tile(Icons.payments, 'Payroll Management', const EmpPayroll()),
          _tile(Icons.how_to_reg, 'Attendance System', AttendanceLoginPage()),
          _tile(Icons.analytics, 'Reports & Analytics', ReportsAnalyticsPage()),
          _tile(Icons.people, 'Employee Directory', EmployeeDirectoryPage()),

          _tile(
            Icons.notifications,
            'Notifications',
            (role == "TL" || role == "Founder" || role == "HR")
                ? AdminNotificationsPage(empId: userProvider.employeeId ?? '')
                : EmployeeNotificationsPage(empId: userProvider.employeeId ?? ''),
          ),

          _tile(Icons.person, 'Employee Profile', EmployeeProfilePage()),
          _tile(Icons.event, 'Company Events', const CompanyEventsScreen()),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String text, Widget page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}
