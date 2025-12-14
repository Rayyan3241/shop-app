// lib/all_devices_web.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AllDevicesWeb extends StatelessWidget {
  const AllDevicesWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('repairs').orderBy('dateAdded', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All Devices', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15)],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Ticket ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Device', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Problem', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      Timestamp? date = data['dateAdded'];
                      String dateStr = date != null ? date.toDate().toString().substring(0, 16) : 'N/A';

                      return DataRow(cells: [
                        DataCell(Text(data['ticketId'] ?? '-')),
                        DataCell(Text(data['customerName'] ?? '-')),
                        DataCell(Text(data['device'] ?? '-')),
                        DataCell(Text(data['problem'] ?? '-')),
                        DataCell(Chip(label: Text(data['status'] ?? 'Received'))),
                        DataCell(Text('OMR ${data['expectedCost'] ?? 0}')),
                        DataCell(Text(dateStr)),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}