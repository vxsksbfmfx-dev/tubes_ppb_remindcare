import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/medicine_service.dart';
import 'medicine_form_screen.dart';

class MedicineListScreen extends StatefulWidget {
  final String token;
  const MedicineListScreen({super.key, this.token = ''});
  const MedicineListScreen({super.key});
  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final _svc          = MedicineService();
  final _searchCtrl   = TextEditingController();
  List<MedicineModel> _list  = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load([String q = '']) async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _svc.getAll(search: q);
      setState(() { _list = res; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(MedicineModel m) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Hapus Obat', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: Text('Hapus ${m.name}?', style: GoogleFonts.poppins()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus', style: TextStyle(color: Colors.red))),
      ]));
    if (ok == true) {
      await _svc.delete(m.id);
      _load(_searchCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColor),
        title: Text('Database Obat', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(AppConstants.primaryColor),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MedicineFormScreen()));
          _load(_searchCtrl.text);
        }),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Cari obat...',
              prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            onChanged: _load)),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red)))
            : _list.isEmpty
              ? Center(child: Text('Tidak ada data', style: GoogleFonts.poppins(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: () => _load(_searchCtrl.text),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final m = _list[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x1A1B6CA8),
                            child: Icon(Icons.medication, color: Color(AppConstants.primaryColor))),
                          title: Text(m.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          subtitle: Text(m.genericName ?? '-', style: GoogleFonts.poppins(fontSize: 12)),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () async {
                              await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => MedicineFormScreen(medicine: m)));
                              _load(_searchCtrl.text);
                            }),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _delete(m)),
                          ])));
                    }))),
      ]),
    );
  }
}
