// lib/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('repairs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        DateTime today = DateTime.now();
        DateTime startOfDay = DateTime(today.year, today.month, today.day);

        int inHand = 0, completedToday = 0, ready = 0, pending = 0;

        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'Received';
          Timestamp? dateAdded = data['dateAdded'];
          bool isToday = dateAdded != null && dateAdded.toDate().isAfter(startOfDay);

          if (status == 'Delivered') {
            if (isToday) completedToday++;
            // Delivered devices are NOT counted in "In Hand"
            continue; // skip the rest
          }

          if (status == 'Ready for Pickup') {
            ready++;
            if ((data['advance'] ?? 0) < (data['expectedCost'] ?? 0)) pending++;
          }

          // Only non-delivered, non-ready devices count as "In Hand"
          if (status != 'Ready for Pickup') {
            inHand++;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Dashboard', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              // FULLY RESPONSIVE SUMMARY CARDS — NO OVERFLOW EVER
              LayoutBuilder(
                builder: (context, constraints) {
                  double maxWidth = constraints.maxWidth;
                  int columns = maxWidth > 1200 ? 4 : (maxWidth > 800 ? 2 : 1);

                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.start,
                    children: [
                      _summaryCard('In Hand', inHand.toString(), Colors.blue),
                      _summaryCard('Completed Today', completedToday.toString(), Colors.green),
                      _summaryCard('Ready for Pickup', ready.toString(), Colors.orange),
                      _summaryCard('Pending Payment', pending.toString(), Colors.red),
                    ],
                  );
                },
              ),

              const SizedBox(height: 50),

              Text('Recent Repairs', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),

              // RESPONSIVE TABLE WITH HORIZONTAL SCROLL
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15)],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 60,
                      dataRowHeight: 70,
                      columns: const [
                        DataColumn(label: Text('Ticket ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Device', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Problem', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: docs.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(Text(data['ticketId'] ?? '-')),
                          DataCell(Text(data['customerName'] ?? '-')),
                          DataCell(Text(data['device'] ?? '-')),
                          DataCell(Text(data['problem'] ?? '-')),
                          DataCell(Chip(
                            label: Text(data['status'] ?? 'Received'),
                            backgroundColor: Colors.blue[100],
                          )),
                          DataCell(Text('OMR ${data['expectedCost'] ?? 0}')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, color: color, size: 50),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}