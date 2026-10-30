import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const PdfApp());

class PdfApp extends StatelessWidget {
  const PdfApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'استوديو PDF',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _createPdf(BuildContext context) async {
    final textController = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('إنشاء مستند جديد'),
      content: TextField(controller: textController, maxLines: 10, decoration: const InputDecoration(hintText: 'اكتب النص هنا...', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          final doc = pw.Document();
          doc.addPage(pw.MultiPage(build: (pw.Context context) => [pw.Paragraph(text: textController.text)]));
          final bytes = await doc.save();
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/مستند_${DateTime.now().millisecondsSinceEpoch}.pdf');
          await file.writeAsBytes(bytes);
          if (context.mounted) {
            Navigator.pop(ctx);
            _showOptions(context, file.path);
          }
        }, child: const Text('حفظ كـ PDF')),
      ],
    ));
  }

  Future<void> _openPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      if (context.mounted) _showPdfViewer(context, result.files.single.path!);
    }
  }

  void _showOptions(BuildContext context, String path) {
    showModalBottomSheet(context: context, builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(leading: const Icon(Icons.visibility), title: const Text('عرض الملف'), onTap: () { Navigator.pop(ctx); _showPdfViewer(context, path); }),
        ListTile(leading: const Icon(Icons.share), title: const Text('مشاركة الملف'), onTap: () { Navigator.pop(ctx); Share.shareXFiles([XFile(path)]); }),
      ],
    ));
  }

  void _showPdfViewer(BuildContext context, String path) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('عرض PDF'), actions: [
        IconButton(icon: const Icon(Icons.share), onPressed: () => Share.shareXFiles([XFile(path)])),
      ]),
      body: PdfPreview(build: (format) => File(path).readAsBytes(), canChangeOrientation: false, canChangePageFormat: false),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استوديو PDF'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16,
          children: [
            _buildCard(context, 'إنشاء PDF', Icons.note_add, Colors.teal, () => _createPdf(context)),
            _buildCard(context, 'فتح PDF', Icons.folder_open, Colors.blue, () => _openPdf(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
