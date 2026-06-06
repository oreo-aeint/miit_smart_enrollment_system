import 'dart:io' if (dart.library.io) 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import "package:share_plus/share_plus.dart";
import 'package:easy_localization/easy_localization.dart';
import 'package:miit_project/components/text.dart';
import 'package:universal_html/html.dart' as html;
import 'package:miit_project/screens/home_screen.dart';

class PdfVoucherScreen extends StatefulWidget {
  final String rollNo;
  final String studentName;
  final String referenceNo;
  final String amount;
  final String date;
  final String time;
  final String? courseYear;
  final String programType;

  const PdfVoucherScreen({
    super.key,
    required this.rollNo,
    required this.studentName,
    required this.referenceNo,
    required this.amount,
    required this.date,
    required this.time,
    this.courseYear,
    required this.programType,
  });

  @override
  State<PdfVoucherScreen> createState() => _PdfVoucherScreenState();
}

class _PdfVoucherScreenState extends State<PdfVoucherScreen> {
  final GlobalKey _printKey = GlobalKey();
  bool _isGenerating = false;
  Uint8List? _miitLogoBytes;

  @override
  void initState() {
    super.initState();
    _loadLogo();
    // Only set immersive mode if not web
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    // Only restore if not web
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _loadLogo() async {
    try {
      final byteData = await rootBundle.load('assets/img_2.png');
      setState(() {
        _miitLogoBytes = byteData.buffer.asUint8List();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading logo: $e');
      }
    }
  }

  // Check if running on a specific platform (safe for web)
  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  bool get isIOS => !kIsWeb && Platform.isIOS;

  bool get isMacOS => !kIsWeb && Platform.isMacOS;

  bool get isWindows => !kIsWeb && Platform.isWindows;

  bool get isLinux => !kIsWeb && Platform.isLinux;

  bool get isMobile => isAndroid || isIOS;

  bool get isDesktop => isMacOS || isWindows || isLinux;

  // Get the best save directory for current platform
  Future<Directory> getBestSaveDirectory({bool preferDownloads = true}) async {
    try {
      // If web, we can't save files directly
      if (kIsWeb) {
        throw Exception('File saving not supported on web');
      }

      // For mobile platforms
      if (isMobile) {
        return await _getMobileSaveDirectory(preferDownloads: preferDownloads);
      }

      // For desktop platforms
      else if (isDesktop) {
        return await _getDesktopSaveDirectory(preferDownloads: preferDownloads);
      }

      // Fallback
      else {
        return await getTemporaryDirectory();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting save directory: $e');
      }
      return await getTemporaryDirectory();
    }
  }

  Future<Directory> _getMobileSaveDirectory(
      {bool preferDownloads = true}) async {
    try {
      if (isAndroid) {
        // Android: Try Downloads first
        if (preferDownloads) {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
            return downloadsDir;
          }
        }

        // Fallback: External storage
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          if (!await externalDir.exists()) {
            await externalDir.create(recursive: true);
          }
          return externalDir;
        }

        // Last resort: Documents directory
        final documentsDir = await getApplicationDocumentsDirectory();
        if (!await documentsDir.exists()) {
          await documentsDir.create(recursive: true);
        }
        return documentsDir;
      } else if (isIOS) {
        // iOS: Documents directory (accessible via Files app)
        if (preferDownloads) {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
            return downloadsDir;
          }
        }

        // Use Documents directory for iOS
        final documentsDir = await getApplicationDocumentsDirectory();
        if (!await documentsDir.exists()) {
          await documentsDir.create(recursive: true);
        }
        return documentsDir;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting mobile directory: $e');
      }
    }

    // Ultimate fallback
    final tempDir = await getTemporaryDirectory();
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  Future<Directory> _getDesktopSaveDirectory(
      {bool preferDownloads = true}) async {
    try {
      // Try Downloads directory for desktop
      if (preferDownloads) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          return downloadsDir;
        }
      }

      // Use Documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }
      return documentsDir;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting desktop directory: $e');
      }
      // Fallback to temporary directory
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      return tempDir;
    }
  }

  // Request appropriate permissions for each platform
  Future<bool> _requestPermissions() async {
    // If web, no permissions needed
    if (kIsWeb) return true;

    // For Android, we'll handle permissions differently
    if (isAndroid) {
      // On Android, we try to save without explicit permission first
      // Modern Android (API 30+) doesn't need storage permission for app-specific directories
      return true;
    }

    // iOS/macOS/Desktop: No specific permissions needed
    return true;
  }

  // Save PDF function for web
  Future<void> _savePdfForWeb(Uint8List pdfBytes) async {
    try {
      // Method 1: Using Blob API (more reliable)
      try {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..download = 'MIIT_Voucher_${widget.rollNo}_${widget.date.replaceAll('-', '')}.pdf'
          ..style.display = 'none';

        html.document.body?.append(anchor);
        anchor.click();

        // Clean up
        Future.delayed(const Duration(milliseconds: 100), () {
          anchor.remove();
          html.Url.revokeObjectUrl(url);
        });
      } catch (e) {
        // Fallback to base64 method
        final base64 = base64Encode(pdfBytes);
        final uri = 'data:application/pdf;base64,$base64';

        final anchor = html.AnchorElement(href: uri)
          ..setAttribute('download', 'MIIT_Voucher_${widget.rollNo}_${widget.date.replaceAll('-', '')}.pdf')
          ..style.display = 'none';

        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('pdfDownloadedSuccessfully'.tr()),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving PDF on web: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'errorDownloadingPdf'.tr()}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save PDF function
  Future<void> _savePdf() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Create PDF
      final pdf = pw.Document();

      // Add page with content
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with logo
                _buildHeader(),
                pw.SizedBox(height: 20),

                // Title
                pw.Center(
                  child: pw.Text(
                    'paymentVOUCHER'.tr(),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 2, color: PdfColors.indigo),
                pw.SizedBox(height: 20),

                // Student Information Section
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'studentInformation'.tr(),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      _buildInfoRow('referenceNo'.tr(), widget.referenceNo),
                      _buildInfoRow('date'.tr(), widget.date),
                      _buildInfoRow('time'.tr(), widget.time),
                      _buildInfoRow('rollNo'.tr(), widget.rollNo),
                      _buildInfoRow('studentName'.tr(), widget.studentName),
                      if (widget.courseYear != null &&
                          widget.courseYear!.isNotEmpty)
                        _buildInfoRow('courseYear'.tr(), widget.courseYear!),
                      _buildInfoRow('program'.tr(), widget.programType),
                      _buildInfoRow('amount'.tr(), '${widget.amount} MMK'),
                      _buildInfoRow('paymentStatus'.tr(), 'paid'.tr()),
                      _buildInfoRow(
                          'paymentMethod'.tr(), 'digitalPayment'.tr()),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'authorizedSignature'.tr(),
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 30),
                        pw.Text(
                          '___________________',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'studentSignature'.tr(),
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 30),
                        pw.Text(
                          '___________________',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Footer note
                pw.Center(
                  child: pw.Text(
                    'computerGeneratedVoucher'.tr(),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Generate PDF bytes
      final pdfBytes = await pdf.save();

      // WEB: Handle web download
      if (kIsWeb) {
        await _savePdfForWeb(pdfBytes);
        return;
      }

      // NATIVE PLATFORMS
      // Request permissions for native platforms
      final hasPermission = await _requestPermissions();
      if (!hasPermission && isAndroid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('storagePermissionRequired'.tr()),
                action: SnackBarAction(
                  label: 'settings'.tr(),
                  onPressed: () {
                    // Open app settings
                    if (isAndroid) {
                      // For Android, we can't open settings programmatically without permission_handler
                      // We'll just show a message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('pleaseGrantStoragePermissionManually'.tr()),
                        ),
                      );
                    }
                  },
                )),
          );
        }
        return;
      }

      // Get the best directory for saving
      final saveDir = await getBestSaveDirectory(preferDownloads: true);

      // Create filename
      final fileName = 'MIIT_Voucher_${widget.rollNo}_${widget.date.replaceAll('-', '')}.pdf';
      final filePath = '${saveDir.path}/$fileName';

      // Save PDF file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes, flush: true);

      // Show success message with platform-specific info
      String platformInfo = '';
      if (isAndroid) {
        platformInfo = 'filesApp'.tr();
      } else if (isIOS) {
        platformInfo = 'filesApp'.tr();
      } else if (isMacOS) {
        platformInfo = 'downloadsFolder'.tr();
      } else if (isWindows) {
        platformInfo = 'downloadsFolder'.tr();
      } else if (isLinux) {
        platformInfo = 'downloadsFolder'.tr();
      } else {
        platformInfo = 'appDirectory'.tr();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('pdfSavedSuccessfully'.tr()),
                const SizedBox(height: 4),
                Text(
                  '${'location'.tr()}: $platformInfo',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'share'.tr(),
              textColor: Colors.white,
              onPressed: () async {
                await _shareFile(file);
              },
            ),
          ),
        );
      }

      // Debug: Print file path for testing
      if (kDebugMode) {
        print('PDF saved to: $filePath');
        print('File exists: ${await file.exists()}');
        print('File size: ${(await file.length()) / 1024} KB');
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Platform error saving PDF: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'platformError'.tr()}: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FileSystemException catch (e) {
      if (kDebugMode) {
        print('File system error saving PDF: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'fileSystemError'.tr()}: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving PDF: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'errorSavingPdf'.tr()}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  // Share file function
  Future<void> _shareFile(File? file) async {
    try {
      if (kIsWeb) {
        // For web, create PDF and share using share_plus
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(
                      'paymentVOUCHER'.tr(),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 2, color: PdfColors.indigo),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'studentInformation'.tr(),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        _buildInfoRow('referenceNo'.tr(), widget.referenceNo),
                        _buildInfoRow('date'.tr(), widget.date),
                        _buildInfoRow('time'.tr(), widget.time),
                        _buildInfoRow('rollNo'.tr(), widget.rollNo),
                        _buildInfoRow('studentName'.tr(), widget.studentName),
                        if (widget.courseYear != null &&
                            widget.courseYear!.isNotEmpty)
                          _buildInfoRow('courseYear'.tr(), widget.courseYear!),
                        _buildInfoRow('program'.tr(), widget.programType),
                        _buildInfoRow('amount'.tr(), '${widget.amount} MMK'),
                        _buildInfoRow('paymentStatus'.tr(), 'paid'.tr()),
                        _buildInfoRow(
                            'paymentMethod'.tr(), 'digitalPayment'.tr()),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );

        final pdfBytes = await pdf.save();
        final tempFile = XFile.fromData(
          pdfBytes,
          mimeType: 'application/pdf',
          name: 'MIIT_Voucher_${widget.rollNo}_${widget.date.replaceAll('-', '')}.pdf',
        );

        await Share.shareXFiles(
          [tempFile],
          text: 'MIIT ${'paymentVoucher'.tr()}\n'
              '${'student'.tr()}: ${widget.studentName}\n'
              '${'rollNo'.tr()}: ${widget.rollNo}\n'
              '${'amount'.tr()}: ${widget.amount} MMK\n'
              '${'date'.tr()}: ${widget.date}',
          subject: 'MIIT ${'paymentVoucher'.tr()} - ${widget.studentName}',
        );
      } else if (file != null) {
        // Original code for native platforms
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          text: 'MIIT ${'paymentVoucher'.tr()}\n'
              '${'student'.tr()}: ${widget.studentName}\n'
              '${'rollNo'.tr()}: ${widget.rollNo}\n'
              '${'amount'.tr()}: ${widget.amount} MMK\n'
              '${'date'.tr()}: ${widget.date}',
          subject: 'MIIT ${'paymentVoucher'.tr()} - ${widget.studentName}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing file: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'errorSharingFile'.tr()}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open file function (for desktop)
  Future<void> _openFile(File file) async {
    try {
      if (isMobile) {
        // For mobile, use share functionality
        await _shareFile(file);
      } else if (isDesktop) {
        // For desktop, open file with default application
        if (isWindows) {
          await Process.run('start', ['', file.path], runInShell: true);
        } else if (isMacOS) {
          await Process.run('open', [file.path]);
        } else if (isLinux) {
          await Process.run('xdg-open', [file.path]);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening file: $e');
      }
    }
  }

  pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        if (_miitLogoBytes != null)
          pw.Container(
            width: 60,
            height: 60,
            child: pw.Image(
              pw.MemoryImage(_miitLogoBytes!),
              fit: pw.BoxFit.contain,
            ),
          )
        else
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                'MIIT',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
        pw.SizedBox(width: 15),

        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'miit'.tr(),
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo,
              ),
            ),
            pw.Text(
              'paymentReceipt'.tr(),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.Text(
            ':',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF87CEFA),
                Color(0xFFADD8E6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Builder(
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    /* child: Image.asset(
                      'assets/img_2.png',
                      width: 50,
                      height: 50,
                    ), */
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "pVOUCHER".tr(),
                style: AppTextStyles.heading,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: DropdownButton<Locale>(
                underline: const SizedBox(),
                icon: const Icon(Icons.language, color: Colors.black),
                value: context.locale,
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) {
                    context.setLocale(newLocale);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: Locale('en'),
                    child: Text("English"),
                  ),
                  DropdownMenuItem(
                    value: Locale('my'),
                    child: Text("မြန်မာ"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: _printKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                // Header with MIIT Logo
                _buildVoucherHeader(),
                const SizedBox(height: 20),

                // Title
                Text(
                  'paymentVOUCHER'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const Divider(thickness: 2, color: Colors.indigo),
                const SizedBox(height: 20),

                // Student Information Section
                _buildInfoSection(),
                const SizedBox(height: 20),

                const SizedBox(height: 30),

                // Signatures
                _buildSignatureSection(),
                const SizedBox(height: 20),

                // Footer Note
                Text(
                  'computerGeneratedVoucher'.tr(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Platform info for debugging
                if (kDebugMode) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'platformInfo'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${'isWeb'.tr()}: $kIsWeb'),
                        Text('${'isMobile'.tr()}: $isMobile'),
                        Text('${'isDesktop'.tr()}: $isDesktop'),
                        if (!kIsWeb) ...[
                          Text('${'isAndroid'.tr()}: $isAndroid'),
                          Text('${'isIOS'.tr()}: $isIOS'),
                          Text('${'isMacOS'.tr()}: $isMacOS'),
                          Text('${'isWindows'.tr()}: $isWindows'),
                          Text('${'isLinux'.tr()}: $isLinux'),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildVoucherHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // MIIT Logo Image
        Container(
          width: 70,
          height: 70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/img_2.png',
              width: 70,
              height: 70,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'MIIT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 15),

        // Institute Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'miit'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              Text(
                '${'paymentReceipt'.tr()} - ${widget.date}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.indigo),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'studentInformation'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoRowUI('reference'.tr(), widget.referenceNo),
            _buildInfoRowUI('date'.tr(), widget.date),
            _buildInfoRowUI('time'.tr(), widget.time),
            _buildInfoRowUI('rollNo'.tr(), widget.rollNo),
            _buildInfoRowUI('studentName'.tr(), widget.studentName),
            if (widget.courseYear != null && widget.courseYear!.isNotEmpty)
              _buildInfoRowUI('cYear'.tr(), widget.courseYear!),
            _buildInfoRowUI('program'.tr(), widget.programType),
            _buildInfoRowUI('amount'.tr(), '${widget.amount} MMK'),
            _buildInfoRowUI('paymentStatus'.tr(), 'paid'.tr()),
            _buildInfoRowUI('paymentMethod'.tr(), 'digitalPayment'.tr()),
          ],
        )
    );
  }

  Widget _buildInfoRowUI(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const Text(':'),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Text(
              'authorizedSignature'.tr(),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 30),
            Container(
              width: 150,
              height: 1,
              color: Colors.black,
            ),
          ],
        ),
        Column(
          children: [
            Text(
              'studentSignature'.tr(),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 30),
            Container(
              width: 150,
              height: 1,
              color: Colors.black,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Single Save PDF Button on the left
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _savePdf,
            icon: _isGenerating
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.save_alt),
            label: Text(_isGenerating ? 'saving'.tr() : 'savePDF'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.indigo, width: 2),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(width: 16),

          ElevatedButton.icon(
            onPressed: _isGenerating ? null : () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MIITHomePage()),
              );
            },
            icon: _isGenerating
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.home),
            label: Text(_isGenerating ? 'going'.tr() : 'home'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.indigo, width: 2),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class PdfColors {
  static var indigo;

  static var blue50;

  static var grey;

  static var blue;

  static var white;
}