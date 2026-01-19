// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:html' as html;

import 'dashboard_page.dart';
import 'add_device_web.dart';
import 'update_status_web.dart';
import 'all_devices_web.dart';
import 'chat_list_web.dart';
import 'add_staff_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBJufGKXFSACbHnR1_5vruWq_psOXxYtNE",
      authDomain: "rayan-repair-shop.firebaseapp.com",
      projectId: "rayan-repair-shop",
      storageBucket: "rayan-repair-shop.firebasestorage.app",
      messagingSenderId: "52873583548",
      appId: "1:52873583548:web:378396017f1db2fbd829b9",
      measurementId: "G-QD32P8NZ8K",
    ),
  );
  runApp(const StaffWebPortal());
}

class StaffWebPortal extends StatelessWidget {
  const StaffWebPortal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rayan Computers - Staff Portal',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xffF5F5F5),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? loggedInUser;

  @override
  void initState() {
    super.initState();
    loggedInUser = html.window.localStorage['username'];
  }

  @override
  Widget build(BuildContext context) {
    if (loggedInUser != null) {
      return StaffDashboard(currentUser: loggedInUser!);
    }
    return const LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
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
      final snapshot = await FirebaseFirestore.instance
          .collection('staff')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty || snapshot.docs.first['password'] != password) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password'), backgroundColor: Colors.red),
        );
        setState(() => loading = false);
        return;
      }

      html.window.localStorage['username'] = username;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StaffDashboard(currentUser: username)),
        );
      }
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
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.computer, size: 80, color: Colors.black),
              const SizedBox(height: 20),
              Text('Get Started', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Text('Enter Your username and password', style: GoogleFonts.poppins(fontSize: 14)),
              const SizedBox(height: 10),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : _login,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class StaffDashboard extends StatefulWidget {
  final String currentUser;

  const StaffDashboard({super.key, required this.currentUser});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Add New Device',
    'Update Status',
    'All Devices',
    'Customer Chats',
    'Account',
  ];

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardPage(),
      const AddDeviceWeb(),
      const UpdateStatusWeb(),
      const AllDevicesWeb(),
      const ChatListWeb(),
      AccountPage(currentUser: widget.currentUser),
    ];

    if (widget.currentUser == 'Khalid@admin') {
      _titles.insert(5, 'Add Staff');
      _pages.insert(5, const AddStaffPage());
    }
  }

  // SMALLER UNREAD BADGE - positioned nicely on the right
  Widget _unreadBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('unreadForStaff', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final int count = snapshot.data!.docs.length;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration:  BoxDecoration(
            color: Colors.blueGrey.shade900,
            shape: BoxShape.circle,
          ),
          constraints: const BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ),
          child: Center(
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(backgroundColor: Colors.white, title: Text(_titles[_selectedIndex]), foregroundColor: Colors.white),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 280,
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.computer, color: Colors.blueGrey.shade900, size: 50),
                          ],
                        ),
                        Row(
                          children: [
                            Text('Rayan Computers', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)),
                          ],
                        ),
                        Row(
                          children: [
                            Text('Staff Portal', style: TextStyle(color: Colors.blueGrey.shade900, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.shade300),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _titles.length,
                      itemBuilder: (context, index) {
                        return _navItem(_titles[index], _getIcon(index), index);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ElevatedButton(
                      onPressed: () {
                        html.window.localStorage.remove('username');
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              color: const Color(0xffF5F5F5),
              child: Column(
                children: [
                  if (!isDesktop) Container(height: 4, color: Colors.black),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blueGrey.shade900,
        selectedItemColor: Colors.blueGrey.shade900,
        unselectedItemColor: Colors.blueGrey.shade900,
        items: _titles.map((title) => BottomNavigationBarItem(icon: Icon(_getIcon(_titles.indexOf(title))), label: title)).toList(),
      ),
    );
  }

  IconData _getIcon(int index) {
    final icons = [
      Icons.dashboard,
      Icons.add_box,
      Icons.edit_note,
      Icons.list_alt,
      Icons.chat,
      Icons.person_add,
      Icons.account_circle,
    ];
    return icons[index];
  }

  Widget _navItem(String title, IconData icon, int index) {
    bool selected = _selectedIndex == index;
    bool isChatItem = title == 'Customer Chats';

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Colors.blueGrey.shade900 : Colors.blueGrey.shade100,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: selected ? Colors.blueGrey.shade900 : Colors.blueGrey.shade900,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isChatItem)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _unreadBadge(),
            ),
        ],
      ),
      selected: selected,
      selectedTileColor: Colors.white10,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }
}

// Account Page remains exactly the same
class AccountPage extends StatefulWidget {
  final String currentUser;

  const AccountPage({super.key, required this.currentUser});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool loading = false;

  Future<void> _changePassword() async {
    if (_newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red));
      return;
    }

    setState(() => loading = true);

    try {
      final query = await FirebaseFirestore.instance.collection('staff').where('username', isEqualTo: widget.currentUser).limit(1).get();

      if (query.docs.isEmpty) throw 'User not found';

      var doc = query.docs.first;
      if (doc['password'] != _oldPassword.text) throw 'Old password incorrect';

      await doc.reference.update({'password': _newPassword.text});

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed!'), backgroundColor: Colors.green));
      _oldPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
          Text('Account Settings', style: GoogleFonts.poppins(fontSize: 42, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          Text('Logged in as: ${widget.currentUser}', style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 60),
          Text('Change Password', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w600)),
          const SizedBox(height: 40),
          _inputField('Current Password', _oldPassword, obscure: true),
          const SizedBox(height: 30),
          _inputField('New Password', _newPassword, obscure: true),
          const SizedBox(height: 30),
          _inputField('Confirm New Password', _confirmPassword, obscure: true),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            height: 70,
            child: ElevatedButton(
              onPressed: loading ? null : _changePassword,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Change Password', style: TextStyle(fontSize: 24, color: Colors.white)),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }
}