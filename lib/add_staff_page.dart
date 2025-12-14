// lib/add_staff_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AddStaffPage extends StatefulWidget {
  const AddStaffPage({super.key});

  @override
  State<AddStaffPage> createState() => _AddStaffPageState();
}

class _AddStaffPageState extends State<AddStaffPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool loading = false;

  Future<void> _addStaff() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username and password'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Check if username already exists
      final check = await FirebaseFirestore.instance
          .collection('staff')
          .where('username', isEqualTo: username)
          .get();

      if (check.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already exists'), backgroundColor: Colors.red),
        );
        return;
      }

      // Add new staff
      await FirebaseFirestore.instance.collection('staff').add({
        'username': username,
        'password': password,
        'role': 'staff',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff added successfully!'), backgroundColor: Colors.green),
      );

      _usernameController.clear();
      _passwordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add New Staff', style: GoogleFonts.poppins(fontSize: 42, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),

          Text('Only admin can add staff members', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
          const SizedBox(height: 60),

          _inputField('Username (e.g., newstaff@rayan)', _usernameController),
          const SizedBox(height: 30),

          _inputField('Password', _passwordController, obscure: true),
          const SizedBox(height: 60),

          SizedBox(
            width: double.infinity,
            height: 70,
            child: ElevatedButton(
              onPressed: loading ? null : _addStaff,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add Staff Member', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 40),

          // List of current staff
          Text('Current Staff Members', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15)],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('staff').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator());
                }

                final staff = snapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: staff.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    var data = staff[index].data() as Map<String, dynamic>;
                    String username = data['username'] ?? 'Unknown';
                    String role = data['role'] ?? 'staff';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: role == 'admin' ? Colors.red : Colors.black,
                        child: Text(username[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Text('Role: $role'),
                      trailing: role == 'admin' ? const Icon(Icons.admin_panel_settings, color: Colors.red) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          obscureText: obscure,
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}