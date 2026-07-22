import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TambahSpkPage extends StatefulWidget {
  final VoidCallback onBack;

  const TambahSpkPage({
    super.key,
    required this.onBack,
  });

  @override
  State<TambahSpkPage> createState() => _TambahSpkPageState();
}

class _TambahSpkPageState extends State<TambahSpkPage> {
  Map<String, dynamic>? selectedPelanggan;
  Map<String, dynamic>? selectedMontir;
  List<Map<String, dynamic>> selectedSpareparts = [];

  final TextEditingController keluhanController = TextEditingController();
  final TextEditingController biayaJasaController = TextEditingController();
  final TextEditingController sparepartSearchController = TextEditingController();

  // ===== ESTIMASI WAKTU (PENGGANTI DROPDOWN selectedDurasi) =====
  // Disimpan dalam MENIT, auto-terisi saat pilih jenis servis,
  // tapi tetap bisa diedit manual sama seperti biayaJasaController.
  final TextEditingController estimasiController = TextEditingController(text: "30");

  List<String> selectedJenisServis = [];

  // ===== STATE MONTIR =====
  List<Map<String, dynamic>> _daftarMontir = [];
  bool _isLoadingMontir = false;

  // ===== STATE SPAREPART =====
  List<Map<String, dynamic>> _sparepartResults = [];
  bool _isSearchingSparepart = false;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isLoading = false;

  final Map<String, int> jenisServisDanHarga = {
    "Tune Up & Scanning System": 200000,
    "Ganti Oli & Filter Oli": 60000,
    "Service Rem / Brake 4 Roda": 200000,
    "Service Kaki-Kaki": 0,
    "Electrical System": 0,
    "Service Kopling / Clutch System": 450000,
    "Ganti Timing Belt": 300000,
    "Overhaul Mesin": 2500000,
    "Overhaul Manual Transmisi": 1500000,
    "Overhaul Gardan": 750000,
    "Overhaul Automatic Transmisi": 2500000,
  };

  // ===== ESTIMASI WAKTU PER JENIS SERVIS (DALAM MENIT) =====
  // Silakan sesuaikan angkanya dengan hasil bimbingan/diskusi tim bengkel.
  final Map<String, int> jenisServisDanEstimasi = {
    "Tune Up & Scanning System": 90,       // 1 jam 30 menit
    "Ganti Oli & Filter Oli": 30,          // 30 menit
    "Service Rem / Brake 4 Roda": 60,      // 1 jam
    "Service Kaki-Kaki": 120,              // 2 jam
    "Electrical System": 120,              // 2 jam
    "Service Kopling / Clutch System": 240,// 4 jam
    "Ganti Timing Belt": 180,              // 3 jam
    "Overhaul Mesin": 1440,                // 1 hari
    "Overhaul Manual Transmisi": 480,      // 8 jam
    "Overhaul Gardan": 300,                // 5 jam
    "Overhaul Automatic Transmisi": 1440,  // 1 hari
  };

  int get totalHarga {
    int total = 0;
    for (var item in selectedSpareparts) {
      total += (int.parse(item['harga'].toString())) * (item['jumlah'] as int);
    }
    return total;
  }

  // Dipanggil setiap kali centang/uncentang jenis servis
  void _updateBiayaJasa() {
    int total = 0;
    for (var servis in selectedJenisServis) {
      total += jenisServisDanHarga[servis] ?? 0;
    }
    biayaJasaController.text = total.toString();
  }

  // Auto-isi total estimasi waktu (menit) dari jenis servis yang dipilih.
  // Tetap bisa diedit manual oleh user lewat estimasiController.
  void _updateEstimasi() {
    int totalMenit = 0;
    for (var servis in selectedJenisServis) {
      totalMenit += jenisServisDanEstimasi[servis] ?? 0;
    }
    // Kalau belum ada servis dipilih, default 30 menit
    estimasiController.text = (totalMenit == 0 ? 30 : totalMenit).toString();
  }

  // Dipanggil bareng tiap kali user centang/uncentang FilterChip jenis servis
  void _onJenisServisChanged() {
    _updateBiayaJasa();
    _updateEstimasi();
  }

  @override
  void initState() {
    super.initState();
    _loadMontir();
  }

  // ===== LOAD SEMUA MONTIR LANGSUNG =====
  Future<void> _loadMontir() async {
    setState(() => _isLoadingMontir = true);
    try {
      final result = await FirebaseFirestore.instance.collection('montir').get();
      setState(() {
        _daftarMontir = result.docs.map((e) {
          final data = e.data();
          return {
            'id': e.id,
            'nama': data['nama'] ?? '',
            'uid_akun': data['uid_akun'] ?? '',
            'spesialisasi': data['spesialisasi'] ?? '',
            'foto': data['foto'] ?? '',
          };
        }).toList();
      });
    } catch (_) {}
    setState(() => _isLoadingMontir = false);
  }

  // ===== SEARCH SPAREPART =====
  Future<void> _searchSparepart(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _sparepartResults = []);
      return;
    }
    setState(() => _isSearchingSparepart = true);
    try {
      final result = await FirebaseFirestore.instance.collection('sparepart').get();
      final filtered = result.docs
          .map((e) => {
                'id': e.id,
                'nama': e['nama'],
                'kode': e['kode'],
                'harga': e['harga_jual'],
                'stok': e['stok'] ?? 0,
              })
          .where((item) =>
              item['nama'].toString().toLowerCase().contains(query.toLowerCase()) ||
              item['kode'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
      setState(() => _sparepartResults = filtered);
    } catch (_) {}
    setState(() => _isSearchingSparepart = false);
  }

  void _tambahSparepart(Map<String, dynamic> option) {
    if ((option['stok'] as int) <= 0) {
      _showSnackbar("Stok ${option['nama']} sudah habis!", isError: true);
      return;
    }
    bool sudahAda = selectedSpareparts.any((item) => item['id'] == option['id']);
    if (sudahAda) {
      _showSnackbar("Sparepart sudah ditambahkan", isError: true);
      return;
    }
    setState(() {
      selectedSpareparts.add({...option, 'jumlah': 1});
    });
  }

  // ===== SIMPAN SPK =====
  Future<void> simpanSPK() async {
    if (selectedPelanggan == null) {
      _showSnackbar("Pilih pelanggan dulu", isError: true);
      return;
    }
    if (keluhanController.text.trim().isEmpty) {
      _showSnackbar("Isi detail keluhan dulu", isError: true);
      return;
    }
    if (selectedJenisServis.isEmpty) {
      _showSnackbar("Pilih jenis servis dulu", isError: true);
      return;
    }
    if (selectedMontir == null) {
      _showSnackbar("Pilih montir dulu", isError: true);
      return;
    }
    if (selectedDate == null || selectedTime == null) {
      _showSnackbar("Pilih tanggal dan waktu dulu", isError: true);
      return;
    }

    final estimasiMenit = int.tryParse(estimasiController.text.trim());
    if (estimasiMenit == null || estimasiMenit <= 0) {
      _showSnackbar("Estimasi waktu tidak valid", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final sparepartSnapshot = selectedSpareparts.map((item) => {
        'sparepart_id': item['id'],
        'nama': item['nama'],
        'kode': item['kode'],
        'harga_jual_saat_itu': item['harga'],
        'jumlah': item['jumlah'],
        'subtotal': int.parse(item['harga'].toString()) * (item['jumlah'] as int),
      }).toList();

      final now = DateTime.now();
      final waktuFormat = selectedTime!.format(context);
      final tahunBulan = "${now.year}${now.month.toString().padLeft(2, '0')}";
      final spkSnapshot = await FirebaseFirestore.instance.collection('spk').get();
      final urutan = (spkSnapshot.docs.length + 1).toString().padLeft(4, '0');
      final noSpk = "SPK-$tahunBulan-$urutan";

      // String estimasi menit mentah (dipakai juga sebagai estimasi per item)
      final estimasiMentah = estimasiMenit.toString();
      // Label estimasi yang enak dibaca, misal "1 Jam 30 Menit"
      final estimasiLabel = _formatEstimasi(estimasiMenit);

      List<Map<String, dynamic>> itemsServisArray = selectedJenisServis.map((item) {
        // Ambil waktu per item dari map jenisServisDanEstimasi
        final estimasiPerItem = (jenisServisDanEstimasi[item] ?? 0).toString(); 
        
        return {
          'nama': item,
          'estimasi': estimasiPerItem, // <--- SEKARANG PAKAI WAKTU SPESIFIK
          'status': 'Belum Mulai',
        };
      }).toList();

      final biayaJasa = int.tryParse(biayaJasaController.text.replaceAll('.', '')) ?? 0;

      await FirebaseFirestore.instance.collection('spk').add({
        'no_spk': noSpk,
        'pelanggan_id': selectedPelanggan!['id'],
        'nama_pelanggan': selectedPelanggan!['nama'],
        'plat': selectedPelanggan!['plat'],
        'kendaraan': selectedPelanggan!['kendaraan'],
        'km': selectedPelanggan!['km'],
        'email': selectedPelanggan!['email'] ?? '',
        'keluhan': keluhanController.text.trim(),
        'jenis_servis': selectedJenisServis,
        'items': itemsServisArray,
        'montir_id': selectedMontir!['id'],
        'montir_uid': selectedMontir!['uid_akun'],
        'nama_montir': selectedMontir!['nama'],
        'sparepart': sparepartSnapshot,
        'total_harga': totalHarga,
        'biaya_jasa': biayaJasa,
        'tanggal': "${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}",
        'waktu': waktuFormat,
        'estimasi': estimasiLabel,
        'estimasi_waktu': estimasiMentah,
        'jam_masuk': waktuFormat,
        'status': 'Menunggu',
        'created_at': Timestamp.now(),
        'waktu_dibuat': Timestamp.now(),
      });

      for (var item in selectedSpareparts) {
        final sparepartId = item['id'];
        final jumlahDipakai = item['jumlah'] as int;

        final sparepartDoc = await FirebaseFirestore.instance
            .collection('sparepart')
            .doc(sparepartId)
            .get();

        if (sparepartDoc.exists) {
          final stokSekarang = sparepartDoc.data()?['stok'] ?? 0;
          final stokBaru = (stokSekarang - jumlahDipakai).clamp(0, 999999);
          await FirebaseFirestore.instance
              .collection('sparepart')
              .doc(sparepartId)
              .update({'stok': stokBaru});
        }
      }

      if (!mounted) return;
      _showSnackbar("SPK berhasil disimpan!", isError: false);
      widget.onBack();

    } catch (e) {
      if (!mounted) return;
      _showSnackbar("Gagal simpan SPK: $e", isError: true);
    }

    setState(() => isLoading = false);
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Buat Surat Perintah Kerja (SPK)",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text("Lengkapi formulir dibawah untuk mendaftarkan antrian servis"),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ===== 1. DATA PELANGGAN =====
                  sectionTitle(Icons.person, "1. Data Pelanggan & Kendaraan"),
                  label("Cari Pelanggan / No. Plat"),

                  Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text == '') return const Iterable<Map<String, dynamic>>.empty();
                      var result = await FirebaseFirestore.instance.collection('pelanggan').get();
                      return result.docs
                          .map((e) => {
                                'id': e.id,
                                'nama': e['nama'],
                                'plat': e['plat'],
                                'kendaraan': e['kendaraan'],
                                'km': e['km'] ?? '-',
                                'email': e.data().containsKey('email') ? e['email'] : '',
                              })
                          .where((item) =>
                              item['nama'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                              item['plat'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    displayStringForOption: (option) => option['nama'],
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: "Contoh: B 1234 ABC atau nama pelanggan",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      );
                    },
                    onSelected: (option) => setState(() => selectedPelanggan = option),
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          child: Container(
                            width: 400,
                            color: Colors.white,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option['nama']),
                                  subtitle: Text(option['plat']),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columns: const [
                        DataColumn(label: Text("Nama Pelanggan")),
                        DataColumn(label: Text("No. Plat")),
                        DataColumn(label: Text("Kendaraan")),
                        DataColumn(label: Text("KM Terakhir")),
                      ],
                      rows: selectedPelanggan == null
                          ? []
                          : [
                              DataRow(cells: [
                                DataCell(Text(selectedPelanggan!['nama'])),
                                DataCell(Text(selectedPelanggan!['plat'])),
                                DataCell(Text(selectedPelanggan!['kendaraan'])),
                                DataCell(Text(selectedPelanggan!['km'].toString())),
                              ])
                            ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ===== 2. KELUHAN & JENIS SERVIS =====
                  sectionTitle(Icons.description, "2. Keluhan & Jenis Servis"),
                  label("Detail Keluhan"),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: keluhanController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Contoh: Mesin berisik saat jalan",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  label("Jenis Servis"),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: jenisServisDanHarga.entries.map((entry) {
                        final servis = entry.key;
                        final harga = entry.value;
                        final estimasiMenit = jenisServisDanEstimasi[servis] ?? 0;
                        final isSelected = selectedJenisServis.contains(servis);

                        return FilterChip(
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(servis, style: const TextStyle(fontSize: 13)),
                              Text(
                                harga == 0
                                    ? "Harga fleksibel"
                                    : "Rp ${_formatRupiah(harga)}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white70 : Colors.grey,
                                ),
                              ),
                              Text(
                                "Estimasi: ${_formatEstimasi(estimasiMenit)}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedJenisServis.add(servis);
                              } else {
                                selectedJenisServis.remove(servis);
                              }
                              _onJenisServisChanged();
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),
                  label("Biaya Jasa Servis (Rp)"),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: biayaJasaController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            prefixText: "Rp ",
                            hintText: "0",
                            helperText: "Otomatis terisi saat pilih servis — bisa diedit manual untuk harga fleksibel",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ===== 3. MONTIR — CARD GRID =====
                  sectionTitle(Icons.engineering, "3. Pilih Montir"),
                  label("Pilih montir yang akan bertugas"),
                  const SizedBox(height: 8),

                  _buildMontirSection(),

                  const SizedBox(height: 25),

                  // ===== 4. SPAREPART =====
                  sectionTitle(Icons.build, "4. Pilih Sparepart"),
                  label("Cari dan tambahkan sparepart yang dibutuhkan"),
                  const SizedBox(height: 8),

                  _buildSparepartSection(),

                  const SizedBox(height: 25),

                  // ===== 5. WAKTU =====
                  sectionTitle(Icons.access_time, "5. Pilih Waktu"),
                  const SizedBox(height: 15),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("TANGGAL MULAI",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime(2030),
                                );
                                if (pickedDate != null) setState(() => selectedDate = pickedDate);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selectedDate == null
                                            ? "Pilih Tanggal"
                                            : "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("WAKTU MULAI",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (pickedTime != null) setState(() => selectedTime = pickedTime);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selectedTime == null ? "Pilih Waktu" : selectedTime!.format(context),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.access_time, color: Colors.grey, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // ===== ESTIMASI PENGERJAAN — SEKARANG SEPERTI BIAYA JASA =====
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("ESTIMASI PENGERJAAN (Menit)",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: estimasiController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                suffixText: "Menit",
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                helperText: estimasiController.text.isEmpty
                                    ? null
                                    : "≈ ${_formatEstimasi(int.tryParse(estimasiController.text) ?? 0)}",
                                helperMaxLines: 2,
                              ),
                              onChanged: (_) => setState(() {}), // refresh helperText "≈ X Jam Y Menit"
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ===== TOTAL & TOMBOL =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade800,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 16,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Total Biaya Sparepart", style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 5),
                            Text(
                              "Rp ${_formatRupiah(totalHarga)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: widget.onBack,
                              child: const Text("Batal"),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue.shade800,
                              ),
                              onPressed: isLoading ? null : simpanSPK,
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(isLoading ? "Menyimpan..." : "Simpan Data Servis"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  SECTION MONTIR — CARD GRID (LANGSUNG TAMPIL SEMUA)
  // ============================================================
  Widget _buildMontirSection() {
    if (_isLoadingMontir) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_daftarMontir.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            const Text("Tidak ada montir tersedia", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedMontir != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 6),
                Text(
                  "Terpilih: ${selectedMontir!['nama']}",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => selectedMontir = null),
                  child: Icon(Icons.close, size: 16, color: Colors.blue.shade400),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _daftarMontir.map((montir) {
            final isSelected = selectedMontir?['id'] == montir['id'];
            return InkWell(
              onTap: () => setState(() => selectedMontir = montir),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 160,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade700 : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.blue.shade200, blurRadius: 8, offset: const Offset(0, 3))]
                      : [BoxShadow(color: Colors.grey.shade100, blurRadius: 4)],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isSelected ? Colors.white24 : Colors.blue.shade50,
                      child: Text(
                        _getInisial(montir['nama']),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      montir['nama'],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    if ((montir['spesialisasi'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        montir['spesialisasi'],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white70 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "✓ Dipilih",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Klik untuk pilih",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================
  //  SECTION SPAREPART — SEARCH + CARD HASIL + TABEL TERPILIH
  // ============================================================
  Widget _buildSparepartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: sparepartSearchController,
          onChanged: (val) => _searchSparepart(val),
          decoration: InputDecoration(
            hintText: "Ketik nama atau kode sparepart...",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: sparepartSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      sparepartSearchController.clear();
                      setState(() => _sparepartResults = []);
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),

        if (_isSearchingSparepart)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_sparepartResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hasil Pencarian (${_sparepartResults.length} item)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _sparepartResults.map((item) {
                    final stok = item['stok'] as int;
                    final harga = int.parse(item['harga'].toString());
                    final sudahDipilih = selectedSpareparts.any((s) => s['id'] == item['id']);
                    final habis = stok <= 0;

                    Color stokColor = Colors.green.shade700;
                    String stokLabel = "Stok: $stok";
                    if (habis) {
                      stokColor = Colors.red;
                      stokLabel = "Stok Habis";
                    } else if (stok <= 3) {
                      stokColor = Colors.orange;
                      stokLabel = "Stok: $stok (terbatas)";
                    }

                    return InkWell(
                      onTap: (habis || sudahDipilih) ? null : () => _tambahSparepart(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: sudahDipilih
                              ? Colors.green.shade50
                              : habis
                                  ? Colors.grey.shade100
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sudahDipilih
                                ? Colors.green.shade300
                                : habis
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['nama'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: habis ? Colors.grey : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (sudahDipilih)
                                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['kode'],
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Rp ${_formatRupiah(harga)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 12, color: stokColor),
                                const SizedBox(width: 4),
                                Text(
                                  stokLabel,
                                  style: TextStyle(fontSize: 11, color: stokColor, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: (habis || sudahDipilih) ? null : () => _tambahSparepart(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: sudahDipilih ? Colors.green : Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                icon: Icon(
                                  sudahDipilih ? Icons.check : habis ? Icons.block : Icons.add_shopping_cart,
                                  size: 14,
                                ),
                                label: Text(
                                  sudahDipilih ? "Sudah Ditambahkan" : habis ? "Stok Habis" : "Tambahkan",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ] else if (sparepartSearchController.text.isNotEmpty && _sparepartResults.isEmpty && !_isSearchingSparepart)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(Icons.search_off, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text("Sparepart tidak ditemukan", style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),

        if (selectedSpareparts.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.blue, size: 18),
              const SizedBox(width: 6),
              Text(
                "Sparepart Dipilih (${selectedSpareparts.length} item)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(2),
                  5: FlexColumnWidth(2),
                  6: FlexColumnWidth(1),
                },
                border: TableBorder.all(color: Colors.grey.shade200),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blue.shade50),
                    children: const [
                      _TableHeader("Nama Sparepart"),
                      _TableHeader("Kode"),
                      _TableHeader("Stok"),
                      _TableHeader("Jumlah"),
                      _TableHeader("Harga Satuan"),
                      _TableHeader("Subtotal"),
                      _TableHeader(""),
                    ],
                  ),
                  ...selectedSpareparts.map((item) {
                    final harga = int.parse(item['harga'].toString());
                    final jumlah = item['jumlah'] as int;
                    final subtotal = harga * jumlah;
                    final stokTersedia = item['stok'] as int;
                    final melebihiStok = jumlah > stokTersedia;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: melebihiStok ? Colors.red.shade50 : Colors.white,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(item['nama'], style: const TextStyle(fontSize: 13)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(item['kode'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(
                            "$stokTersedia",
                            style: TextStyle(
                              fontSize: 13,
                              color: stokTersedia <= 3 ? Colors.orange : Colors.black,
                              fontWeight: stokTersedia <= 3 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                color: Colors.red.shade400,
                                onTap: () {
                                  if (item['jumlah'] > 1) setState(() => item['jumlah']--);
                                },
                              ),
                              Container(
                                width: 36,
                                alignment: Alignment.center,
                                child: Text(
                                  "$jumlah",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: melebihiStok ? Colors.red : Colors.black,
                                  ),
                                ),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                color: Colors.green.shade600,
                                onTap: () {
                                  if (jumlah >= stokTersedia) {
                                    _showSnackbar(
                                      "Jumlah tidak boleh melebihi stok ($stokTersedia)",
                                      isError: true,
                                    );
                                    return;
                                  }
                                  setState(() => item['jumlah']++);
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text("Rp ${_formatRupiah(harga)}", style: const TextStyle(fontSize: 13)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(
                            "Rp ${_formatRupiah(subtotal)}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            tooltip: "Hapus",
                            onPressed: () => setState(() => selectedSpareparts.remove(item)),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          if (selectedSpareparts.any((item) => (item['jumlah'] as int) > (item['stok'] as int)))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "Jumlah melebihi stok tersedia, harap sesuaikan",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  "Total Sparepart: Rp ${_formatRupiah(totalHarga)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getInisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return nama.isNotEmpty ? nama[0].toUpperCase() : "?";
  }

  String _formatRupiah(int angka) {
    return angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Ubah menit jadi label yang enak dibaca, misal 90 -> "1 Jam 30 Menit"
  String _formatEstimasi(int totalMenit) {
    if (totalMenit <= 0) return "0 Menit";
    final hari = totalMenit ~/ 1440;
    final sisaSetelahHari = totalMenit % 1440;
    final jam = sisaSetelahHari ~/ 60;
    final menit = sisaSetelahHari % 60;

    final parts = <String>[];
    if (hari > 0) parts.add("$hari Hari");
    if (jam > 0) parts.add("$jam Jam");
    if (menit > 0) parts.add("$menit Menit");
    return parts.isEmpty ? "0 Menit" : parts.join(" ");
  }

  Widget sectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}

// ===== HELPER WIDGET =====

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}