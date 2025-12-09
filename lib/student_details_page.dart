// lib/student_details_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'services/oncampus_service.dart';
import 'sidebar.dart';

class StudentDetailsPage extends StatefulWidget {
  final String driveId;
  const StudentDetailsPage({super.key, required this.driveId});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  Map<String, dynamic>? drive;
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];

  final TextEditingController _search = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDrive();
    _search.addListener(_doSearch);
  }

  void _doSearch() {
    final q = _search.text.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        filteredStudents = List.from(students);
      } else {
        filteredStudents = students.where((s) {
          return (s['name'] ?? '').toLowerCase().contains(q) ||
              (s['mobile'] ?? '').toLowerCase().contains(q) ||
              (s['email'] ?? '').toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _loadDrive() async {
    final d = await OnCampusService.fetchDrive(widget.driveId);

    setState(() {
      drive = d;
      students = d?['students'] ?? [];
      filteredStudents = List.from(students);
      loading = false;
    });
  }

  // ----------------------------
  // ADD / EDIT STUDENT
  // ----------------------------
  Future<void> _addOrEditStudent({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;

    final nameCtl = TextEditingController(text: existing?['name'] ?? '');
    final mobileCtl = TextEditingController(text: existing?['mobile'] ?? '');
    final emailCtl = TextEditingController(text: existing?['email'] ?? '');

    PlatformFile? pickedFile;
    String fileName = existing?['resumePath']?.split('/')?.last ?? '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialog) => AlertDialog(
          title: Text(isEdit ? "Edit Student" : "Add Student"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: mobileCtl, decoration: const InputDecoration(labelText: 'Mobile')),
                TextField(controller: emailCtl, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                      withData: true,
                    );
                    if (result != null) {
                      pickedFile = result.files.first;
                      setDialog(() => fileName = pickedFile!.name);
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(fileName.isEmpty ? "Upload Resume" : fileName),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final fields = {
                  'name': nameCtl.text,
                  'mobile': mobileCtl.text,
                  'email': emailCtl.text,
                };

                if (isEdit) {
                  await OnCampusService.updateStudent(
                    widget.driveId,
                    existing['_id'],
                    fields,
                    pickedFile,
                  );
                } else {
                  await OnCampusService.addStudent(
                    widget.driveId,
                    fields,
                    pickedFile,
                  );
                }

                Navigator.pop(ctx);
                await _loadDrive();
              },
              child: Text(isEdit ? "Save" : "Add"),
            )
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // ACTIONS
  // ----------------------------
  void _downloadResume(String resumePath) {
    final fileName = resumePath.split('/').last;
    final url = "${OnCampusService.baseUrl}/api/oncampus/resume/$fileName";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Resume Download"),
        content: SelectableText(url),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }

  void _viewResume(String resumePath) {
    final fileName = resumePath.split('/').last;
    final url = "${OnCampusService.baseUrl}/api/oncampus/resume/$fileName";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("View Resume"),
        content: SelectableText(url),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }

  Future<void> _deleteStudent(String sid) async {
    await OnCampusService.deleteStudent(widget.driveId, sid);
    await _loadDrive();
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: "Student Details",
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text("College: ${drive?['collegeName'] ?? ''}",
                          style: const TextStyle(color: Colors.white, fontSize: 18)),
                      const SizedBox(width: 20),
                      Text("Total Students: ${students.length}",
                          style: const TextStyle(color: Colors.white, fontSize: 18)),
                      const Spacer(),
                      SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            hintText: "Search by name / mobile / email",
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // TABLE
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Card(
                      elevation: 2,
                      clipBehavior: Clip.hardEdge,
                      child: Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                            columns: const [
                              DataColumn(label: Text("Name")),
                              DataColumn(label: Text("Mobile")),
                              DataColumn(label: Text("Email")),
                              DataColumn(label: Text("Resume File")),
                              DataColumn(label: Text("Actions")),
                            ],
                            rows: filteredStudents.map((s) {
                              final resume = s['resumePath'] ?? '';
                              final sid = s['_id'];
                              final fileName = resume.isEmpty ? "" : resume.split('/').last;

                              return DataRow(
                                cells: [
                                  DataCell(Text(s['name'] ?? "")),
                                  DataCell(Text(s['mobile'] ?? "")),
                                  DataCell(Text(s['email'] ?? "")),
                                  DataCell(Text(fileName)),
                                  DataCell(
                                    Row(children: [
                                      IconButton(
                                          icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                                          onPressed: resume.isEmpty ? null : () => _viewResume(resume)),
                                      IconButton(
                                          icon: const Icon(Icons.download, color: Colors.green),
                                          onPressed: resume.isEmpty ? null : () => _downloadResume(resume)),
                                      IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.orange),
                                          onPressed: () => _addOrEditStudent(existing: s)),
                                      IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteStudent(sid)),
                                    ]),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ADD BUTTON
                ElevatedButton.icon(
                  onPressed: () => _addOrEditStudent(),
                  icon: const Icon(Icons.add),
                  label: const Text("Add Student"),
                ),

                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
