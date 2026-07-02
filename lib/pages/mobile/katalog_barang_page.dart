import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class KatalogBarangPage extends StatefulWidget {
  const KatalogBarangPage({super.key});

  @override
  State<KatalogBarangPage> createState() => _KatalogBarangPageState();
}

class _KatalogBarangPageState extends State<KatalogBarangPage> {
  String _searchQuery = "";
  String _selectedKategori = "Semua";

  // ✅ SINKRONKAN DENGAN ADMIN (SAMAKAN PERSIS)
  final List<String> kategoriList = [
    "Semua",
    "Oli",
    "Grease",
    "Filter Oli",
    "Filter Udara",
    "Filter AC",
    "Filter Bahan Bakar",
    "Kampas Rem",
    "Pompa",
    "Additive",
    "Spare Part",
  ];

  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // ✅ PERBAIKI LOGIKA GAMBAR AGAR SESUAI DENGAN KATEGORI BARU
  String _getGambarKategori(String kategori) {
    switch (kategori) {
      case "Oli":
      case "Additive":
        return "assets/shell_yellow.png"; // Ganti sesuai aset Anda
      case "Filter Oli":
      case "Filter Udara":
      case "Filter AC":
      case "Filter Bahan Bakar":
        return "assets/shell_yellow.png"; 
      case "Kampas Rem":
      case "Grease":
        return "assets/shell_yellow.png";
      default:
        return "assets/shell_yellow.png"; // Gambar default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Katalog Barang",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Produk Sparepart",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // ================= SEARCH & FILTER BAR =================
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 10),
                    // Input Pencarian Multi-Kriteria (Nama & Kategori)
                    Expanded(
                      flex: 3,
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: "Cari nama atau kategori...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ),
                    // Dropdown Filter Kategori
                    Expanded(
                      flex: 2,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedKategori,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          items: kategoriList.map((String kat) {
                            return DropdownMenuItem<String>(
                              value: kat,
                              child: Text(kat),
                            );
                          }).toList(),
                          onChanged: (String? newVal) {
                            if (newVal != null) {
                              setState(() {
                                _selectedKategori = newVal;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ================= NETWORKING REAL-TIME DARI ADMIN =================
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('sparepart').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("Belum ada data barang dari admin", style: TextStyle(color: Colors.grey)),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    // Mengubah logika penyaringan di memori lokal HP
                    final listProdukTerfilter = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      
                      final String nama = (data['nama'] ?? "").toString().toLowerCase();
                      final String kategori = (data['kategori'] ?? "").toString().toLowerCase();

                      // Logika Dropdown Filter Atas
                      final cocokDropdownKategori = _selectedKategori == "Semua" || 
                          kategori == _selectedKategori.toLowerCase();
                          
                      // Logika Kolom ketik
                      final cocokKetikSearch = nama.contains(_searchQuery) || 
                          kategori.contains(_searchQuery);

                      return cocokDropdownKategori && cocokKetikSearch;
                    }).toList();

                    if (listProdukTerfilter.isEmpty) {
                      return const Center(
                        child: Text("Produk tidak ditemukan", style: TextStyle(color: Colors.grey)),
                      );
                    }

                    // ================= GRID TAMPILAN 2 KOLOM BORDER BIRU =================
                    return GridView.builder(
                      itemCount: listProdukTerfilter.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.76,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemBuilder: (context, index) {
                        final data = listProdukTerfilter[index].data() as Map<String, dynamic>;
                        
                        String kategoriBarang = data['kategori'] ?? "Oli & Cairan";
                        String namaBarang = data['nama'] ?? "-";
                        
                        // Proteksi Multi-Type untuk Harga Jual dari Admin
                        int hargaJual = 0;
                        if (data['harga_jual'] != null) {
                          hargaJual = (data['harga_jual'] is String) 
                              ? int.tryParse(data['harga_jual']) ?? 0 
                              : (data['harga_jual'] as num).toInt();
                        }

                        // ✅ DISINKRONKAN: Mengambil field 'foto_url' sesuai dengan penyimpanan database di halaman admin
                        String? urlGambar = data['foto_url'];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade700, width: 1.5),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Menampilkan Gambar Network atau Fallback Asset Lokal jika kosong
                              Expanded(
                                child: urlGambar != null && urlGambar.isNotEmpty && urlGambar.startsWith('http')
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          urlGambar,
                                          fit: BoxFit.cover, // Diubah ke cover agar visual gambar di grid memenuhi ruang card dengan rapi
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            // Jika link URL gambar rusak/error, tampilkan icon warning yang informatif
                                            return Icon(Icons.broken_image, size: 45, color: Colors.red.shade300);
                                          },
                                        ),
                                      )
                                    : Image.asset(
                                        _getGambarKategori(kategoriBarang),
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.build_circle, size: 45, color: Colors.blue.shade300);
                                        },
                                      ),
                              ),
                              const SizedBox(height: 8),
                              // Nama Barang asli inputan admin
                              Text(
                                namaBarang,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Harga Jual asli inputan admin (sudah diformat Rp)
                              Text(
                                formatRupiah.format(hargaJual),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}