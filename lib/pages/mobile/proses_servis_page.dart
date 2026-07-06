import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProsesServisPage extends StatefulWidget {
  final String spkId; // Menerima ID SPK yang dipilih dari Dashboard

  const ProsesServisPage({super.key, required this.spkId});

  @override
  State<ProsesServisPage> createState() => _ProsesServisPageState();
}

class _ProsesServisPageState extends State<ProsesServisPage> {
  
  // Fungsi bantuan untuk mengubah "90" menjadi "1 Jam 30 Menit"
  String _formatEstimasi(String estimasiMentah) {
    int totalMenit = int.tryParse(estimasiMentah) ?? 0;
    if (totalMenit <= 0) return "Waktu Fleksibel";
    
    final jam = totalMenit ~/ 60;
    final menit = totalMenit % 60;

    final parts = <String>[];
    if (jam > 0) parts.add("$jam Jam");
    if (menit > 0) parts.add("$menit Menit");
    
    return parts.join(" ");
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // Mengambil data SPK secara real-time dari Firestore berdasarkan ID yang dipilih
      stream: FirebaseFirestore.instance.collection('spk').doc(widget.spkId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Data SPK tidak ditemukan.")),
          );
        }

        // Membaca data dokumen SPK dari Firebase
        final docData = snapshot.data!.data() as Map<String, dynamic>;

        // Ambil data kendaraan dan pelanggan langsung dari inputan Admin
        String namaKendaraan = docData['kendaraan'] ?? '-';
        String nomorPlat = docData['plat'] ?? '-';
        String namaPelangan = docData['nama_pelanggan'] ?? docData['pelanggan'] ?? 'Umum';
        String estimasiGlobal = (docData['estimasi_waktu'] ?? '30').toString();
        
        // Ambil status utama SPK saat ini untuk validasi kontrol
        String statusUtamaSekarang = docData['status'] ?? 'Menunggu';

        // LOGIKA DINAMIS: Mengambil inputan 'jenis_servis' dari Admin
        List<Map<String, dynamic>> listPekerjaanDariAdmin = [];

        if (docData['items'] != null) {
          // Jika di database sudah tersimpan dalam bentuk array (Format Baru Admin)
          listPekerjaanDariAdmin = List<Map<String, dynamic>>.from(docData['items']);
        } else if (docData['jenis_servis'] != null) {
          // Fallback jika membaca format data lama
          String teksServis = docData['jenis_servis'].toString();
          List<String> potonganTeks = teksServis.split(',');

          for (var itemTeks in potonganTeks) {
            if (itemTeks.trim().isNotEmpty) {
              listPekerjaanDariAdmin.add({
                'nama': itemTeks.trim(),
                'estimasi': estimasiGlobal,
                'status': 'Belum Mulai'
              });
            }
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              "Proses Pengecekan Mekanik",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Banner Informasi Kendaraan sesuai inputan Admin
              Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.blue.shade900.withOpacity(0.1),
                      child: Icon(Icons.directions_car, color: Colors.blue.shade900),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namaKendaraan,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900),
                          ),
                          Text(
                            nomorPlat,
                            style: TextStyle(color: Colors.blue.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Pelanggan: $namaPelangan | Status: $statusUtamaSekarang",
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Item Penanganan Dari SPK Admin:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),

              // Daftar Item Pekerjaan Dinamis yang menyesuaikan inputan Admin
              Expanded(
                child: listPekerjaanDariAdmin.isEmpty
                    ? const Center(
                        child: Text(
                          "Tidak ada item penanganan dari Admin.",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        itemCount: listPekerjaanDariAdmin.length,
                        padding: const EdgeInsets.all(14),
                        itemBuilder: (context, index) {
                          final item = listPekerjaanDariAdmin[index];
                          String namaTugas = item['nama'] ?? 'Item Servis';
                          
                          // Mengambil estimasi mentah (misal: "90") dan mengubahnya jadi "1 Jam 30 Menit"
                          String estimasiMentah = (item['estimasi'] ?? '0').toString();
                          String estimasiFormat = _formatEstimasi(estimasiMentah);
                          
                          String statusTugas = item['status'] ?? 'Belum Mulai';

                          bool isSelesai = statusTugas == 'Selesai';
                          bool isDikerjakan = statusTugas == 'Dikerjakan';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelesai ? Colors.green.shade50 : (isDikerjakan ? Colors.blue.shade50 : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelesai ? Colors.green.shade200 : (isDikerjakan ? Colors.blue.shade200 : Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelesai ? Icons.check_circle : (isDikerjakan ? Icons.pending : Icons.radio_button_unchecked),
                                  color: isSelesai ? Colors.green : (isDikerjakan ? Colors.blue : Colors.grey),
                                  size: 24,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        namaTugas,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 14, 
                                          color: isSelesai ? Colors.green.shade900 : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      
                                      // Label Target Waktu yang lebih rapi
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isSelesai ? Colors.green.shade100 : Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: isSelesai ? Colors.green.shade300 : Colors.orange.shade200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.timer_outlined, 
                                              size: 12, 
                                              color: isSelesai ? Colors.green.shade700 : Colors.orange.shade700
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Target: $estimasiFormat",
                                              style: TextStyle(
                                                fontSize: 11, 
                                                color: isSelesai ? Colors.green.shade700 : Colors.orange.shade800, 
                                                fontWeight: FontWeight.bold
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Dropdown Aksi Montir untuk Mengupdate Status Pekerjaan ke Firebase
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white, 
                                    borderRadius: BorderRadius.circular(8), 
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButton<String>(
                                    value: statusTugas,
                                    underline: const SizedBox(),
                                    style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                                    items: const [
                                      DropdownMenuItem(value: "Belum Mulai", child: Text("Belum Mulai")),
                                      DropdownMenuItem(value: "Dikerjakan", child: Text("Dikerjakan")),
                                      DropdownMenuItem(value: "Selesai", child: Text("Selesai")),
                                    ],
                                    onChanged: (val) async {
                                      if (val != null) {
                                        listPekerjaanDariAdmin[index]['status'] = val;

                                        String penentuStatusUtama = statusUtamaSekarang;
                                        if (val == 'Dikerjakan') {
                                          penentuStatusUtama = 'Dikerjakan';
                                        }

                                        bool apakahSemuaItemSelesai = listPekerjaanDariAdmin.every((tugas) => tugas['status'] == 'Selesai');
                                        if (apakahSemuaItemSelesai) {
                                          penentuStatusUtama = 'Selesai';
                                        }

                                        await FirebaseFirestore.instance.collection('spk').doc(widget.spkId).update({
                                          'items': listPekerjaanDariAdmin,
                                          'status': penentuStatusUtama,
                                          'waktu_update': FieldValue.serverTimestamp(),
                                        });
                                      }
                                    },
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Tombol Final Selesai Semuanya
              Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      for (var tugas in listPekerjaanDariAdmin) {
                        tugas['status'] = 'Selesai';
                      }

                      await FirebaseFirestore.instance.collection('spk').doc(widget.spkId).update({
                        'items': listPekerjaanDariAdmin,
                        'status': 'Selesai',
                        'waktu_selesai': Timestamp.now()
                      });
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Berhasil menyerahkan laporan pengerjaan SPK! Status: Selesai")),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("SELESAI & SERAHKAN KUNCI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}