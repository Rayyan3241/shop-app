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
            continue;
          }

          if (status == 'Ready for Pickup') {
            ready++;
            if ((data['advance'] ?? 0) < (data['expectedCost'] ?? 0)) pending++;
          }

          if (status != 'Ready for Pickup') {
            inHand++;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade900,
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 30),
                      // RESPONSIVE CLEAN SUMMARY CARDS
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double maxWidth = constraints.maxWidth;
                          int columns = maxWidth > 1200 ? 4 : (maxWidth > 800 ? 2 : 1);

                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: 2.5,
                            children: [
                              _summaryCard('In Hand', inHand.toString(), Colors.blueGrey.shade100, Colors.blueGrey.shade900),
                              _summaryCard('Completed Today', completedToday.toString(), Colors.blueGrey.shade100, Colors.blueGrey.shade900),
                              _summaryCard('Ready for Pickup', ready.toString(), Colors.blueGrey.shade100, Colors.blueGrey.shade900),
                              _summaryCard('Pending Payment', pending.toString(), Colors.blueGrey.shade100, Colors.blueGrey.shade900),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Divider(color: Colors.blueGrey.shade900),
              const SizedBox(height: 50),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    children: [
                      Text(
                        'Recents',
                        style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade900),
                      ),
                      const SizedBox(height: 50),
                      // Your table with highlighted rows
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
                                String status = data['status'] ?? 'Received';
                                Color? rowColor = (status == 'Ready for Pickup') ? Colors.blueGrey.shade100 : null;

                                return DataRow(
                                  color: MaterialStateProperty.resolveWith<Color?>(
                                        (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.selected)) return Colors.blueGrey.shade200;
                                      return rowColor;
                                    },
                                  ),
                                  cells: [
                                    DataCell(Text(data['ticketId'] ?? '-')),
                                    DataCell(Text(data['customerName'] ?? '-')),
                                    DataCell(Text(data['device'] ?? '-')),
                                    DataCell(Text(data['problem'] ?? '-')),
                                    DataCell(Chip(
                                      label: Text(status, style: const TextStyle(color: Colors.white)),
                                      backgroundColor: Colors.blueGrey.shade900,
                                    )),
                                    DataCell(Text('OMR ${data['expectedCost'] ?? 0}')),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard(String title, String value, Color bgColor, Color valueColor) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}