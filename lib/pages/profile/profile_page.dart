import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {

  final TextEditingController
      namaController =
      TextEditingController();

  final TextEditingController
      passwordLamaController =
      TextEditingController();

  final TextEditingController
      passwordBaruController =
      TextEditingController();

  final TextEditingController
      konfirmasiPasswordController =
      TextEditingController();

  bool isLoading = true;

  bool obscurePasswordLama = true;
  bool obscurePasswordBaru = true;
  bool obscureKonfirmasiPassword = true;

  String docId = "";
  String oldPassword = "";

  @override
  void initState() {
    super.initState();

    getProfile();
  }

  // ================= GET DATA =================

  Future<void> getProfile() async {

    try {

      // UID USER YANG LOGIN
      String uid =
          FirebaseAuth.instance.currentUser!.uid;

      // AMBIL DATA SESUAI UID
      final doc =
          await FirebaseFirestore.instance
              .collection('manajemen_akun')
              .doc(uid)
              .get();

      if (doc.exists) {

        final data = doc.data()!;

        docId = doc.id;

        namaController.text =
            data['nama'] ?? "";

        oldPassword =
            data['password'] ?? "";
      }

      setState(() {
        isLoading = false;
      });

    } catch (e) {

      setState(() {
        isLoading = false;
      });

      debugPrint(
        "Error profile: $e",
      );
    }
  }

  // ================= UPDATE PROFILE =================

  Future<void> updateProfile() async {

    // VALIDASI PASSWORD

    if (passwordBaruController.text !=
        konfirmasiPasswordController
            .text) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Konfirmasi password tidak sama",
          ),
        ),
      );

      return;
    }

    try {

      User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) return;

      // ================= UPDATE PASSWORD AUTH =================

      if (passwordBaruController
          .text.isNotEmpty) {

        await user.updatePassword(
          passwordBaruController.text,
        );
      }

      // ================= UPDATE FIRESTORE =================

      await FirebaseFirestore.instance
          .collection('manajemen_akun')
          .doc(user.uid)
          .update({

        'nama':
            namaController.text,

        if (passwordBaruController
            .text.isNotEmpty)

          'password':
              passwordBaruController
                  .text,
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Profile berhasil diupdate",
          ),
        ),
      );

    } catch (e) {

      debugPrint(
        "ERROR UPDATE PROFILE: $e",
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            "Error: $e",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(

      backgroundColor:
          Colors.transparent,

      child: Center(

        child: Container(
          width: 500,

          padding:
              const EdgeInsets.all(25),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(10),

            boxShadow: [

              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: 0.1,
                ),

                blurRadius: 10,
              ),
            ],
          ),

          child: isLoading

              ? const SizedBox(
                  height: 200,

                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )

              : SingleChildScrollView(

                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      // ================= HEADER =================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [

                          const Text(
                            "Profile Admin",

                            style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          GestureDetector(

                            onTap: () {
                              Navigator.pop(
                                  context);
                            },

                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 25),

                      // ================= FOTO =================

                      Center(
                        child: Stack(
                          children: [

                            Container(
                              width: 120,
                              height: 120,

                              decoration:
                                  const BoxDecoration(
                                color:
                                    Colors.blue,
                                shape:
                                    BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color:
                                    Colors.white,
                              ),
                            ),

                            Positioned(
                              bottom: 0,
                              right: 0,

                              child: Container(
                                padding:
                                    const EdgeInsets
                                        .all(8),

                                decoration:
                                    const BoxDecoration(
                                  color:
                                      Colors.blue,
                                  shape:
                                      BoxShape.circle,
                                ),

                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 30),

                      // ================= NAMA =================

                      const Text(
                        "Nama Lengkap",

                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                          height: 8),

                      TextField(
                        controller:
                            namaController,

                        decoration:
                            InputDecoration(
                          hintText:
                              "Masukkan nama",

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 20),

                      // ================= PASSWORD LAMA =================

                      const Text(
                        "Password Lama",

                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                          height: 8),

                      TextField(
                        controller:
                            passwordLamaController,

                        obscureText: obscurePasswordLama,

                        decoration:
                            InputDecoration(
                          hintText:
                              "Masukkan password lama",

                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePasswordLama
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePasswordLama =
                                    !obscurePasswordLama;
                              });
                            },
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 20),

                      // ================= PASSWORD BARU =================

                      const Text(
                        "Password Baru",

                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                          height: 8),

                      TextField(
                        controller:
                            passwordBaruController,

                        obscureText: obscurePasswordBaru,

                        decoration:
                            InputDecoration(
                          hintText:
                              "Masukkan password baru",

                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePasswordBaru
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePasswordBaru =
                                    !obscurePasswordBaru;
                              });
                            },
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 20),

                      // ================= KONFIRMASI PASSWORD =================

                      const Text(
                        "Konfirmasi Password",

                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                          height: 8),

                      TextField(
                        controller:
                            konfirmasiPasswordController,

                        obscureText: obscureKonfirmasiPassword,

                        decoration:
                            InputDecoration(
                          hintText:
                              "Masukkan konfirmasi password",

                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureKonfirmasiPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureKonfirmasiPassword =
                                    !obscureKonfirmasiPassword;
                              });
                            },
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 30),

                      // ================= BUTTON =================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .end,

                        children: [

                          SizedBox(
                            height: 40,

                            child:
                                ElevatedButton(

                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    Colors.red,

                                foregroundColor:
                                    Colors.white,
                              ),

                              onPressed: () {
                                Navigator.pop(
                                    context);
                              },

                              child:
                                  const Text(
                                "Batal",
                              ),
                            ),
                          ),

                          const SizedBox(
                              width: 10),

                          SizedBox(
                            height: 40,

                            child:
                                ElevatedButton
                                    .icon(

                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    Colors.blue,

                                foregroundColor:
                                    Colors.white,
                              ),

                              onPressed:
                                  updateProfile,

                              icon: const Icon(
                                Icons.save,
                                size: 18,
                              ),

                              label:
                                  const Text(
                                "Simpan",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}