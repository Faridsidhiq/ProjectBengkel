import 'package:flutter/foundation.dart'; // Tambahan: Wajib untuk mendeteksi kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'pages/auth/login_page.dart'; // Ini halaman login Web
import 'pages/dashboard/dashboard_page.dart'; // Ini halaman dashboard Web
import 'pages/mobile/login_mobile_page.dart'; // Ini halaman login Mobile
import 'pages/mobile/dashboard_mobile_page.dart'; // Dashboard pelanggan Mobile
import 'pages/mobile/dashboard_montir_page.dart'; // Dashboard montir Mobile

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
        // Tampilkan loading saat mengecek status auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return kIsWeb ? const LoginPage() : const LoginMobilePage();
        }

        // Jika Web, langsung ke DashboardPage (Admin)
        if (kIsWeb) {
          return const DashboardPage();
        }

        // Jika Mobile, harus cek role di Firestore (pelanggan vs montir)
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('pelanggan').doc(user.uid).get(),
          builder: (context, pelangganSnapshot) {
            if (pelangganSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (pelangganSnapshot.hasData && pelangganSnapshot.data!.exists) {
              final role = pelangganSnapshot.data!.get('role')?.toString().toLowerCase() ?? '';
              if (role == 'pelanggan') {
                return const DashboardMobilePage();
              }
            }

            // Jika tidak ada di pelanggan, cek di manajemen_akun (montir/admin)
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('manajemen_akun').doc(user.uid).get(),
              builder: (context, montirSnapshot) {
                if (montirSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (montirSnapshot.hasData && montirSnapshot.data!.exists) {
                  final role = montirSnapshot.data!.get('role')?.toString().toLowerCase() ?? '';
                  if (role == 'montir') {
                    return const DashboardMontirPage();
                  } else if (role == 'admin') {
                    // Admin disuruh ke Web, jadi force logout di mobile
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      FirebaseAuth.instance.signOut();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Akun Admin silakan gunakan sistem Web!"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    });
                    return const LoginMobilePage();
                  }
                }

                // Jika data tidak ditemukan di mana pun, force logout
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FirebaseAuth.instance.signOut();
                });
                return const LoginMobilePage();
              },
            );
          },
        );
      },
    );
  }
}