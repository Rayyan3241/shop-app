// lib/add_device_web.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:html' as html;
class AddDeviceWeb extends StatefulWidget {
  const AddDeviceWeb({super.key});

  @override
  State<AddDeviceWeb> createState() => _AddDeviceWebState();
}

class _AddDeviceWebState extends State<AddDeviceWeb> {
  final _formKey = GlobalKey<FormState>();
  final _customerName = TextEditingController();
  final _phone = TextEditingController();
  final _device = TextEditingController();
  final _problem = TextEditingController();
  final _expectedCost = TextEditingController();
  final _advance = TextEditingController();
  final _note = TextEditingController();

  bool loading = false;

  Future<void> _addDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      int nextNumber = 1;
      final snapshot = await FirebaseFirestore.instance.collection('repairs').get();
      if (snapshot.docs.isNotEmpty) {
        final ids = snapshot.docs
            .map((d) => int.tryParse((d['ticketId'] as String).substring(4)) ?? 0)
            .toList();
        nextNumber = ids.reduce((a, b) => a > b ? a : b) + 1;
      }

      String ticketId = 'RYN-${nextNumber.toString().padLeft(3, '0')}';

      await FirebaseFirestore.instance.collection('repairs').add({
        'ticketId': ticketId,
        'customerName': _customerName.text.trim(),
        'phone': '+968${_phone.text.trim()}', // <--- prepend +968 here
        'device': _device.text.trim(),
        'problem': _problem.text.trim(),
        'expectedCost': int.tryParse(_expectedCost.text) ?? 0,
        'advance': int.tryParse(_advance.text) ?? 0,
        'status': 'Received',
        'dateAdded': FieldValue.serverTimestamp(),
      });

      // SHOW RECEIPT
      _showReceiptDialog(ticketId, _phone.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device added successfully: $ticketId'), backgroundColor: Colors.green),
      );

      _formKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void _showReceiptDialog(String ticketId, String phone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(40),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RAYAN COMPUTERS', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 3)),
              const SizedBox(height: 20),
              Text('Device Received Successfully', style: TextStyle(fontSize: 22, color: Colors.grey[700])),
              const SizedBox(height: 50),

              Text('YOUR Tracking ID', style: TextStyle(fontSize: 20, color: Colors.grey[600], letterSpacing: 2)),
              const SizedBox(height: 20),
              Text(ticketId, style: GoogleFonts.poppins(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 50),

              Text('Phone Number', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              const SizedBox(height: 10),
              Text(phone, style: TextStyle(fontSize: 32)),
              const SizedBox(height: 50),

              Text('Please save this ticket ID to track your device',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]), textAlign: TextAlign.center),

              const SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _printReceipt(ticketId, phone),
                    icon: const Icon(Icons.print, size: 28, color: Colors.white,),
                    label: const Text('Print Receipt', style: TextStyle(fontSize: 18,color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _downloadPdf(ticketId, phone),
                    icon: const Icon(Icons.download, size: 28, color: Colors.white,),
                    label: const Text('Download PDF', style: TextStyle(fontSize: 18, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printReceipt(String ticketId, String phone) async {
    final pdfBytes = await _generatePdf(ticketId, phone);
    await Printing.layoutPdf(onLayout: (_) => pdfBytes); // Opens browser print dialog
  }

  Future<void> _downloadPdf(String ticketId, String phone) async {
    final pdfBytes = await _generatePdf(ticketId, phone);

    // DIRECT DOWNLOAD USING dart:html — WORKS PERFECTLY ON WEB
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "Rayan_Receipt_$ticketId.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<Uint8List> _generatePdf(String ticketId, String phone) async {
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
                pw.Text(
                  'RAYAN COMPUTERS',
                  style: pw.TextStyle(fontSize: 36),
                ),
                pw.SizedBox(height: 30),

                pw.Text('+968 99636476', style: pw.TextStyle(fontSize: 28)),
                pw.SizedBox(height: 5),
                pw.Text('+968 96008824', style: pw.TextStyle(fontSize: 28)),
                pw.SizedBox(height: 20),

                pw.Text(
                  'Device Received',
                  style: pw.TextStyle(fontSize: 28),
                ),
                pw.SizedBox(height: 60),
                pw.Text(
                  'Tracking ID',
                  style: pw.TextStyle(fontSize: 24),
                ),
                pw.SizedBox(height: 20),

                pw.Text(
                  ticketId,
                  style: pw.TextStyle(
                    fontSize: 72,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 60),

                pw.Text(
                  'Phone Number: $phone',
                  style: pw.TextStyle(fontSize: 32),
                ),

                pw.SizedBox(height: 60),

                pw.Text(
                  'Please keep this ticket ID safe',
                  style: pw.TextStyle(fontSize: 22),
                ),

              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add New Device', style: GoogleFonts.poppins(fontSize: 42, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),

          Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _inputField('Customer Name', _customerName)),
                    const SizedBox(width: 30),
                    Expanded(child: _inputField('Phone Number', _phone, keyboard: TextInputType.phone)),
                  ],
                ),
                const SizedBox(height: 20),

                _inputField('Device Name / Model', _device),
                const SizedBox(height: 20),

                _inputField('Problem Description', _problem, maxLines: 5),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: _inputField('Expected Cost (OMR)', _expectedCost, keyboard: TextInputType.number)),
                    const SizedBox(width: 20),
                    Expanded(child: _inputField('Advance Paid (OMR)', _advance, keyboard: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 20),


                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: loading ? null : _addDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Add Device', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          validator: (value) => value!.trim().isEmpty ? 'This field is required' : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _customerName.dispose();
    _phone.dispose();
    _device.dispose();
    _problem.dispose();
    _expectedCost.dispose();
    _advance.dispose();
    _note.dispose();
    super.dispose();
  }
}