import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailKeluhanPage extends StatefulWidget {
  final VoidCallback onBack;
  final DocumentSnapshot keluhanDoc;

  const DetailKeluhanPage({
    super.key,
    required this.onBack,
    required this.keluhanDoc,
  });

  @override
  State<DetailKeluhanPage> createState() =>
      _DetailKeluhanPageState();
}

class _DetailKeluhanPageState
    extends State<DetailKeluhanPage> {

  late TextEditingController tanggapanController;

  String selectedStatus = "Menunggu";

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    final data =
        widget.keluhanDoc.data() as Map<String, dynamic>;

    selectedStatus =
        data["status"] ?? "Menunggu";

    tanggapanController =
        TextEditingController(
      text: data["tanggapan"] ?? "",
    );
  }

  Future<void> simpanTanggapan() async {
    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseFirestore.instance
          .collection("keluhan")
          .doc(widget.keluhanDoc.id)
          .update({
        "status": selectedStatus,
        "tanggapan":
            tanggapanController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Tanggapan berhasil disimpan"),
          backgroundColor: Colors.green,
        ),
      );

      widget.onBack();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data =
        widget.keluhanDoc.data()
            as Map<String, dynamic>;

    return Material(
      color: const Color(0xfff5f7fb),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon:
                      const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Manajemen Keluhan Pelanggan",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ATAS (Pesan Pelanggan)
                    buildCard(
                      title: "PESAN PELANGGAN",
                      icon: Icons.message,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.all(
                                    12),
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .grey.shade100,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Colors
                                      .blue,
                                ),
                                const SizedBox(
                                    width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        data["nama"] ??
                                            "",
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                      Text(
                                        data["email"] ??
                                            "",
                                        style:
                                            const TextStyle(
                                          color: Colors
                                              .grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                              height: 20),
                          const Text(
                            "Judul Keluhan",
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                              height: 5),
                          Text(
                            data["judul"] ?? "",
                          ),
                          const SizedBox(
                              height: 20),
                          const Text(
                            "Isi Keluhan",
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                              height: 5),
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets
                                    .all(15),
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .grey.shade100,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          8),
                            ),
                            child: Text(
                              data["isi"] ?? "",
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // BAWAH (Update Status)
                    buildCard(
                      title:
                          "UPDATE STATUS KELUHAN",
                      icon:
                          Icons.support_agent,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedStatus,
                            items: const [
                              DropdownMenuItem(
                                value:
                                    "Menunggu",
                                child: Text(
                                    "Menunggu"),
                              ),
                              DropdownMenuItem(
                                value:
                                    "Sedang Proses",
                                child: Text(
                                    "Sedang Proses"),
                              ),
                              DropdownMenuItem(
                                value:
                                    "Selesai",
                                child: Text(
                                    "Selesai"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedStatus =
                                    value!;
                              });
                            },
                            decoration:
                                const InputDecoration(
                              border:
                                  OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(
                              height: 15),
                          TextField(
                            controller:
                                tanggapanController,
                            maxLines: 6,
                            decoration:
                                const InputDecoration(
                              hintText:
                                  "Tulis tanggapan untuk pelanggan...",
                              border:
                                  OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(
                              height: 15),
                          SizedBox(
                            width:
                                double.infinity,
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
                                  isLoading
                                      ? null
                                      : simpanTanggapan,
                              icon:
                                  const Icon(
                                Icons.save,
                              ),
                              label: Text(
                                isLoading
                                    ? "Menyimpan..."
                                    : "Simpan Tanggapan",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}