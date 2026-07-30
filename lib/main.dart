import 'package:flutter/foundation.dart'; // Wajib untuk mendeteksi kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/auth/login_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/mobile/login_mobile_page.dart';
import 'pages/mobile/dashboard_mobile_page.dart';
import 'pages/mobile/dashboard_montir_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bengkel Mitsubishi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Tampilkan indikator loading saat Firebase sedang memverifikasi sesi login
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Jika pengguna sudah terautentikasi (sesi tersimpan)
        if (snapshot.hasData && snapshot.data != null) {
          return RoleCheckWidget(user: snapshot.data!);
        }

        // Jika belum login / sudah logout
        return kIsWeb 
            ? const LoginPage() 
            : const LoginMobilePage();
      },
    );
  }
}

class RoleCheckWidget extends StatefulWidget {
  final User user;
  const RoleCheckWidget({super.key, required this.user});

  @override
  State<RoleCheckWidget> createState() => _RoleCheckWidgetState();
}

class _RoleCheckWidgetState extends State<RoleCheckWidget> {
  bool _isLoading = true;
  Widget? _page;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      // 1. Cek di koleksi manajemen_akun (Admin & Montir)
      DocumentSnapshot akunDoc = await FirebaseFirestore.instance
          .collection('manajemen_akun')
          .doc(widget.user.uid)
          .get();
          
      if (akunDoc.exists) {
        final data = akunDoc.data() as Map?;
        final role = data?['role']?.toString().toLowerCase().trim() ?? '';
        
        if (kIsWeb) {
          if (role == 'admin') {
            if (mounted) setState(() { _isLoading = false; _page = const DashboardPage(); });
            return;
          } else if (role == 'montir') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Akses Ditolak: Akun Montir silakan gunakan aplikasi Mobile!"), backgroundColor: Colors.orange),
              );
            }
            await FirebaseAuth.instance.signOut();
            return;
          }
        } else {
          if (role == 'montir') {
            if (mounted) setState(() { _isLoading = false; _page = const DashboardMontirPage(); });
            return;
          } else if (role == 'admin') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Akses Ditolak: Akun Admin silakan gunakan sistem Web!"), backgroundColor: Colors.orange),
              );
            }
            await FirebaseAuth.instance.signOut();
            return;
          }
        }
      }

      // 2. Cek di koleksi pelanggan
      DocumentSnapshot pelangganDoc = await FirebaseFirestore.instance
          .collection('pelanggan')
          .doc(widget.user.uid)
          .get();
          
      if (pelangganDoc.exists) {
        final data = pelangganDoc.data() as Map?;
        final role = data?['role']?.toString().toLowerCase().trim() ?? '';
        
        if (kIsWeb) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Akses Ditolak: Akun Pelanggan silakan gunakan aplikasi Mobile!"), backgroundColor: Colors.orange),
            );
          }
          await FirebaseAuth.instance.signOut();
          return;
        } else {
          if (role == 'pelanggan') {
            if (mounted) setState(() { _isLoading = false; _page = const DashboardMobilePage(); });
            return;
          }
        }
      }

      // 3. Jika peran tidak terdaftar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Akses Ditolak: Peran akun tidak dikenali di sistem!"),
            backgroundColor: Colors.red,
          ),
        );
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error Sistem: $e"), backgroundColor: Colors.red),
        );
      }
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _page ?? const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}