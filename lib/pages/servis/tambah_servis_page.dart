import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TambahServisPage extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic> spkData;

  const TambahServisPage({
    super.key,
    required this.onBack,
    required this.spkData,
  });

  @override
  State<TambahServisPage> createState() => _TambahServisPageState();
}

class _TambahServisPageState extends State<TambahServisPage> {
  String metodePembayaran = "Cash";
  bool isSaving = false;

  // ================= HARGA DEFAULT JENIS SERVIS =================
  static const Map<String, double> _hargaServisDefault = {
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

  // ================= KALKULASI BIAYA (TANPA PPN) =================
  double get biayaJasa => (widget.spkData['biaya_jasa'] ?? 0).toDouble();
  double get subtotalSparepart => (widget.spkData['total_harga'] ?? 0).toDouble();
  double get totalAkhir => biayaJasa + subtotalSparepart;

  List<dynamic> get jenisServisList =>
      (widget.spkData['jenis_servis'] as List?) ?? [];

  String _formatRupiah(num value) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return 'Rp ${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 900;

            if (isNarrow) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildKolomKiriContent(),
                    const SizedBox(height: 15),
                    summaryCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= LEFT =================
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: _buildKolomKiriContent(),
                  ),
                ),

                const SizedBox(width: 20),

                // ================= RIGHT =================
                Expanded(
                  flex: 1,
                  child: summaryCard(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildKolomKiriContent() {
    return Column(
      children: [
        cardSPK(),
        const SizedBox(height: 15),
        cardJenisServis(),
        const SizedBox(height: 15),
        cardSparepart(),
        const SizedBox(height: 15),
        cardRincian(),
        const SizedBox(height: 15),
        cardPembayaran(),
        const SizedBox(height: 80),
      ],
    );
  }

  // ================= CARD SPK =================
  Widget cardSPK() {
    return card(
      "Data SPK",
      Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              border: TableBorder.all(color: Colors.grey.shade300),
              columns: const [
                DataColumn(label: Text("Nomor SPK")),
                DataColumn(label: Text("Nama Pelanggan")),
                DataColumn(label: Text("Kendaraan")),
                DataColumn(label: Text("Total Sparepart")),
              ],
              rows: [
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        widget.spkData['no_spk'] ?? '-',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    DataCell(Text(widget.spkData['nama_pelanggan'] ?? '-')),
                    DataCell(Text(widget.spkData['kendaraan'] ?? '-')),
                    DataCell(Text(_formatRupiah(widget.spkData['total_harga'] ?? 0))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= CARD JENIS SERVIS (DIJABARKAN) =================
  Widget cardJenisServis() {
    final List<dynamic> items = jenisServisList;

    if (items.isEmpty) {
      return card(
        "Daftar Jenis Servis / Jasa",
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text("Tidak ada jenis servis yang dipilih.",
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return card(
      "Daftar Jenis Servis / Jasa",
      Column(
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              border: TableBorder.all(color: Colors.grey.shade300),
              headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
              columns: const [
                DataColumn(label: Text("No.")),
                DataColumn(label: Text("Jenis Pekerjaan / Jasa Servis")),
                DataColumn(label: Text("Biaya Jasa")),
              ],
              rows: List.generate(items.length, (i) {
                final nama = items[i].toString();
                final harga = _hargaServisDefault[nama] ?? 0;
                return DataRow(cells: [
                  DataCell(Text("${i + 1}")),
                  DataCell(Text(nama)),
                  DataCell(Text(
                    harga == 0 ? "Sesuai Kesepakatan" : _formatRupiah(harga),
                    style: TextStyle(
                      color: harga == 0 ? Colors.orange : Colors.black,
                    ),
                  )),
                ]);
              }),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Total Biaya Jasa: ${_formatRupiah(biayaJasa)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CARD SPAREPART =================
  Widget cardSparepart() {
    final List<dynamic> sparepartList =
        (widget.spkData['sparepart'] as List?) ?? [];

    if (sparepartList.isEmpty) {
      return card(
        "Daftar Sparepart",
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text("Tidak ada sparepart yang digunakan.",
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return card(
      "Daftar Sparepart",
      Column(
        children: [
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              border: TableBorder.all(color: Colors.grey.shade300),
              headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
              columns: const [
                DataColumn(label: Text("No.")),
                DataColumn(label: Text("Nama")),
                DataColumn(label: Text("Kode")),
                DataColumn(label: Text("Jumlah")),
                DataColumn(label: Text("Harga")),
                DataColumn(label: Text("Total")),
              ],
              rows: List.generate(sparepartList.length, (i) {
                final item = sparepartList[i];
                return DataRow(cells: [
                  DataCell(Text("${i + 1}")),
                  DataCell(Text(item['nama'] ?? '-')),
                  DataCell(Text(item['kode'] ?? '-')),
                  DataCell(Text("${item['jumlah'] ?? 0}")),
                  DataCell(Text(_formatRupiah(item['harga_jual_saat_itu'] ?? 0))),
                  DataCell(Text(_formatRupiah(item['subtotal'] ?? 0))),
                ]);
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CARD RINCIAN (TANPA PPN) =================
  Widget cardRincian() {
    return card(
      "Rincian Biaya Akhir",
      Column(
        children: [
          rowText("Subtotal Jasa Servis", _formatRupiah(biayaJasa)),
          rowText("Subtotal Sparepart", _formatRupiah(subtotalSparepart)),
          const Divider(),
          rowText("TOTAL BIAYA AKHIR", _formatRupiah(totalAkhir), bold: true),
        ],
      ),
    );
  }

  // ================= CARD PEMBAYARAN =================
  Widget cardPembayaran() {
    return card(
      "Metode Pembayaran",
      Column(
        children: [
          RadioListTile<String>(
            title: const Text("Tunai (Cash)"),
            value: "Cash",
            groupValue: metodePembayaran,
            onChanged: (String? value) {
              setState(() {
                metodePembayaran = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text("Transfer Bank"),
            value: "Transfer",
            groupValue: metodePembayaran,
            onChanged: (String? value) {
              setState(() {
                metodePembayaran = value!;
              });
            },
          ),
          if (metodePembayaran == "Transfer")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nomor Rekening", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("BCA : 2940825272"),
                  Text("A/N Sarjimu"),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ================= SUMMARY CARD (TANPA PPN) =================
  Widget summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "RINGKASAN BIAYA",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          rowText("Subtotal Jasa", _formatRupiah(biayaJasa)),
          rowText("Subtotal Sparepart", _formatRupiah(subtotalSparepart)),

          const Divider(),

          const Text("TOTAL BIAYA AKHIR",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),

          Text(
            _formatRupiah(totalAkhir),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: isSaving ? null : _simpanInvoice,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(isSaving ? "Menyimpan..." : "Simpan & Selesaikan"),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: widget.onBack,
            child: const Text("Batal Transaksi"),
          ),
        ],
      ),
    );
  }

  // ================= SIMPAN INVOICE (TANPA PPN, SERTAKAN JENIS SERVIS) =================
  Future<void> _simpanInvoice() async {
    setState(() => isSaving = true);

    try {
      final cekInvoice = await FirebaseFirestore.instance
          .collection('invoice')
          .where('spk_id', isEqualTo: widget.spkData['id'])
          .limit(1)
          .get();

      if (cekInvoice.docs.isNotEmpty) {
        setState(() => isSaving = false);
        return;
      }

      await FirebaseFirestore.instance.collection('invoice').add({
        'spk_id': widget.spkData['id'],
        'no_spk': widget.spkData['no_spk'],
        'nama_pelanggan': widget.spkData['nama_pelanggan'],
        'nama_montir': widget.spkData['nama_montir'],
        'kendaraan': widget.spkData['kendaraan'],
        'plat': widget.spkData['plat'],
        'sparepart': widget.spkData['sparepart'] ?? [],
        'jenis_servis': widget.spkData['jenis_servis'] ?? [],
        'biaya_jasa': biayaJasa,
        'total_harga': subtotalSparepart,
        'pajak': 0,
        'total_akhir': totalAkhir,
        'metode_pembayaran': metodePembayaran,
        'status': 'Lunas',
        'created_at': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('spk')
          .doc(widget.spkData['id'])
          .update({
        'status_invoice': true,
      });

      widget.onBack();
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  // ================= COMPONENT HELPERS =================

  Widget card(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child
        ],
      ),
    );
  }

  Widget rowText(String title, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}