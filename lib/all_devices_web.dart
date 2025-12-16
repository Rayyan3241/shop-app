// lib/all_devices_web.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:html' as html;

class AllDevicesWeb extends StatelessWidget {
  const AllDevicesWeb({super.key});

  Future<Uint8List> _generatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(60),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('RAYAN COMPUTERS', style: pw.TextStyle(fontSize: 36)),
                pw.SizedBox(height: 30),
                pw.Text('+968 99636476', style: pw.TextStyle(fontSize: 28)),
                pw.SizedBox(height: 5),
                pw.Text('+968 96008824', style: pw.TextStyle(fontSize: 28)),
                pw.SizedBox(height: 20),
                pw.Text('Device Received', style: pw.TextStyle(fontSize: 28)),
                pw.SizedBox(height: 20),
                pw.Text('${data['device']}', style: pw.TextStyle(fontSize: 32)),
                pw.SizedBox(height: 60),
                pw.Text('Tracking ID', style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 20),
                pw.Text(data['ticketId'], style: pw.TextStyle(fontSize: 72, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 60),
                pw.Text('Phone Number: ${data['phone']}', style: pw.TextStyle(fontSize: 32)),
                pw.SizedBox(height: 60),
                pw.Text('Please keep this ticket ID safe', style: pw.TextStyle(fontSize: 22)),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _printReceipt(Map<String, dynamic> data) async {
    final pdfBytes = await _generatePdf(data);
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  Future<void> _downloadPdf(Map<String, dynamic> data) async {
    final pdfBytes = await _generatePdf(data);
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "Rayan_Receipt_${data['ticketId']}.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _deleteDevice(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('repairs').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device deleted successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting device: $e'), backgroundColor: Colors.red),
      );
    }
  }

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
                      DataColumn(label: Text('Tracking ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Device', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Problem', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
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
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min, // <- important
                            children: [
                              IconButton(
                                icon: const Icon(Icons.print, color: Colors.black, size: 24), // make sure size is visible
                                tooltip: 'Print Receipt',
                                onPressed: () => _printReceipt(data),
                              ),
                              const SizedBox(width: 8), // spacing between buttons
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                                tooltip: 'Delete Device',
                                onPressed: () => _deleteDevice(context, doc.id),
                              ),
                            ],
                          ),
                        ),

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
