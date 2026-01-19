// lib/update_status_web.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateStatusWeb extends StatefulWidget {
  const UpdateStatusWeb({super.key});

  @override
  State<UpdateStatusWeb> createState() => _UpdateStatusWebState();
}

class _UpdateStatusWebState extends State<UpdateStatusWeb> {
  final _searchController = TextEditingController();
  DocumentSnapshot? repairDoc;
  bool loading = false;

  final List<String> statuses = [
    'Received',
    'In Diagnosis',
    'Repairing',
    'Ready for Pickup',
    'Delivered'
  ];

  String? selectedStatus;
  late TextEditingController _costController;
  late TextEditingController _advanceController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController();
    _advanceController = TextEditingController();
    _noteController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _selectRepair(DocumentSnapshot doc) {
    repairDoc = doc;
    var data = doc.data() as Map<String, dynamic>;
    selectedStatus = data['status'];
    _costController.text = data['expectedCost']?.toString() ?? '';
    _advanceController.text = data['advance']?.toString() ?? '';
    _noteController.text = data['note'] ?? '';
    setState(() {});
  }

  void _clearSelection() {
    repairDoc = null;
    _searchController.clear();
    _costController.clear();
    _advanceController.clear();
    _noteController.clear();
    selectedStatus = null;
    setState(() {});
  }

  Future<void> _saveChanges() async {
    if (repairDoc == null) return;

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection('repairs').doc(repairDoc!.id).update({
        'status': selectedStatus,
        'expectedCost': int.tryParse(_costController.text) ?? 0,
        'advance': int.tryParse(_advanceController.text) ?? 0,
        'note': _noteController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated successfully!'), backgroundColor: Colors.green),
      );
      _clearSelection(); // go back to search after save
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _costController.dispose();
    _advanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String searchQuery = _searchController.text.toLowerCase().trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (repairDoc != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 32),
                  onPressed: _clearSelection,
                  tooltip: 'Back to search',
                ),
              Text(
                repairDoc == null ? 'Update Status' : 'Editing ${repairDoc!['ticketId']}',
                style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // SEARCH BOX
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 20),

          // LIVE SEARCH RESULTS LIST
          if (searchQuery.isNotEmpty || repairDoc == null)
            Container(
              constraints: const BoxConstraints(maxHeight: 800),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15)],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('repairs').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator());
                  }

                  var allDocs = snapshot.data!.docs;

                  var filteredDocs = searchQuery.isEmpty
                      ? allDocs
                      : allDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String ticket = (data['ticketId'] ?? '').toString().toLowerCase();
                    String name = (data['customerName'] ?? '').toString().toLowerCase();
                    String phone = (data['phone'] ?? '').toString().toLowerCase();
                    String device = (data['device'] ?? '').toString().toLowerCase();

                    return ticket.contains(searchQuery) ||
                        name.contains(searchQuery) ||
                        phone.contains(searchQuery) ||
                        device.contains(searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No devices found', style: TextStyle(fontSize: 18, color: Colors.white)),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      var doc = filteredDocs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Text(data['ticketId'].toString().substring(4, 7), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text('${data['ticketId']} - ${data['customerName']}'),
                        subtitle: Text('${data['device']} • ${data['phone']}'),
                        trailing: Chip(
                          label: Text(data['status'] ?? 'Received', style: TextStyle(color: Colors.white),),
                          backgroundColor: Colors.blueGrey.shade900,
                        ),
                        onTap: () => _selectRepair(doc),
                      );
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 50),

          // UPDATE FORM — only when a device is selected
          if (repairDoc != null)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ticket:    ${repairDoc!['ticketId']}', style: GoogleFonts.poppins(fontSize: 28)),
                  Text('Customer:   ${repairDoc!['customerName']}', style: const TextStyle(fontSize: 20)),
                  Text('Device:        ${repairDoc!['device']}', style: const TextStyle(fontSize: 20)),
                  Text('Phone:           ${repairDoc!['phone']}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 30),

                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(labelText: 'Status', filled: true, fillColor: Colors.grey[100]),
                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => selectedStatus = v),
                    dropdownColor: Colors.white,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _costController,
                          decoration: InputDecoration(labelText: 'Expected Cost (OMR)', filled: true, fillColor: Colors.grey[100]),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextField(
                          controller: _advanceController,
                          decoration: InputDecoration(labelText: 'Advance Paid (OMR)', filled: true, fillColor: Colors.grey[100]),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _noteController,
                    maxLines: 5,
                    decoration: InputDecoration(labelText: 'Technician Note', filled: true, fillColor: Colors.grey[100]),
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: loading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),padding: const EdgeInsets.symmetric(vertical: 20)),
                          child: loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}