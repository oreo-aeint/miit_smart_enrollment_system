import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:excel/excel.dart' as ex;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class ExcelUploader extends StatefulWidget {
  @override
  _ExcelUploaderPageState createState() => _ExcelUploaderPageState();
}

class _ExcelUploaderPageState extends State<ExcelUploader> {
  List<PlatformFile> uploadedFiles = [];
  List<Map<String, dynamic>> uploadedFileData = [];
  String _selectedCollection = 'students';

  // Academic year and payment settings
  final TextEditingController _startYearController = TextEditingController();
  final TextEditingController _endYearController = TextEditingController();
  final TextEditingController _normalPaymentController = TextEditingController();
  final TextEditingController _masterPaymentController = TextEditingController();
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadUploadedFiles();
    _loadAcademicSettings();
  }

  // Generate unique batch ID
  String _generateBatchId() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomStr = String.fromCharCodes(Iterable.generate(
        6,
            (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
    return 'batch_${timestamp}_$randomStr';
  }

  // Standardize roll number format
  String _standardizeRollNumber(String rollNumber) {
    if (rollNumber.isEmpty) return rollNumber;

    String standardized = rollNumber.trim().toLowerCase();
    standardized = standardized
        .replaceAll(' ', '-')
        .replaceAll('_', '-')
        .replaceAll('--', '-')
        .replaceAll('miit', 'miit')
        .replaceAll('@miit.edu.mm', '');
    return standardized;
  }

  // Show file type selection dialog
  Future<void> _showFileTypeSelection() async {
    final selectedType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Select Data Type'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What type of data do you want to upload?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCollection = 'exams';
                });
                Navigator.of(context).pop('exam_results');
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green[50],
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_turned_in, color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exam Results',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Student exam scores, grades and results',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.green, size: 16),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCollection = 'entrance_pass_stu';
                });
                Navigator.of(context).pop('entrance_pass');
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue[50],
                ),
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.blue, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entrance Pass Students',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Students who passed entrance examination',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (selectedType != null) {
      await _pickFile(selectedType);
    }
  }

  // Pick file after selecting type
  Future<void> _pickFile(String fileType) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv', 'txt'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: Could not read file content'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final batchId = _generateBatchId();

      setState(() {
        uploadedFiles.add(file);
        uploadedFileData.add({
          'name': file.name,
          'collection': _selectedCollection,
          'fileType': fileType,
          'uploadedAt': DateTime.now().toIso8601String(),
          'status': 'Pending',
          'batchId': batchId,
          'documentIds': [],
        });
      });

      await _saveUploadedFiles();
      await _processFile(file, _selectedCollection, uploadedFiles.length - 1, fileType, batchId);
    }
  }

  // Load uploaded files from storage
  void _loadUploadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final filesJson = prefs.getString('uploadedFiles');
    if (filesJson != null) {
      final List<dynamic> filesList = json.decode(filesJson);
      setState(() {
        uploadedFileData = filesList.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  // Save uploaded files to storage
  Future<void> _saveUploadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final filesJson = json.encode(uploadedFileData);
    await prefs.setString('uploadedFiles', filesJson);
  }

  // Process uploaded file
  Future<void> _processFile(PlatformFile file, String collection, int index, String fileType, String batchId) async {
    try {
      setState(() {
        uploadedFileData[index]['status'] = 'Processing...';
      });

      List<String> documentIds = [];
      if (fileType == 'exam_results') {
        documentIds = await _processExamResults(file, batchId);
      } else if (fileType == 'entrance_pass') {
        documentIds = await _processEntrancePass(file, batchId);
      }

      setState(() {
        uploadedFileData[index]['documentIds'] = documentIds;
        uploadedFileData[index]['status'] = 'Processed';
        uploadedFileData[index]['processedAt'] = DateTime.now().toIso8601String();
      });

      await _saveUploadedFiles();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_getFileTypeDisplayName(fileType)} processed successfully! (${documentIds.length} records)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        uploadedFileData[index]['status'] = 'Error: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error processing ${_getFileTypeDisplayName(fileType)}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Process exam results
  Future<List<String>> _processExamResults(PlatformFile file, String batchId) async {
    List<List<String>> fileData = await _parseFile(file);
    List<String> documentIds = await _uploadExamDataToFirestore(fileData, file.name, batchId);
    print('Exam results processed: ${file.name} - ${documentIds.length} records');
    return documentIds;
  }

  // Process entrance pass students
  Future<List<String>> _processEntrancePass(PlatformFile file, String batchId) async {
    List<List<String>> fileData = await _parseFile(file);
    List<String> documentIds = await _uploadEntranceDataToFirestore(fileData, file.name, batchId);
    print('Entrance pass students processed: ${file.name} - ${documentIds.length} records');
    return documentIds;
  }

  // Parse file
  Future<List<List<String>>> _parseFile(PlatformFile file) async {
    if (file.bytes == null) throw Exception('File bytes are null');

    if (file.extension == 'xlsx' || file.extension == 'xls') {
      return _parseExcelFile(file.bytes!);
    } else if (file.extension == 'csv' || file.extension == 'txt') {
      return _parseCsvFile(file.bytes!);
    } else {
      throw Exception('Unsupported file format: ${file.extension}');
    }
  }

  Future<List<List<String>>> _parseExcelFile(List<int> bytes) async {
    final excel = ex.Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return [];

    List<List<String>> data = [];
    for (var row in sheet.rows) {
      List<String> rowData = [];
      for (var cell in row) {
        rowData.add(cell?.value?.toString() ?? '');
      }
      data.add(rowData);
    }
    return data;
  }

  Future<List<List<String>>> _parseCsvFile(List<int> bytes) async {
    final content = String.fromCharCodes(bytes);
    final rows = const CsvToListConverter().convert(content);

    List<List<String>> data = [];
    for (var row in rows) {
      List<String> rowData = [];
      for (var cell in row) {
        rowData.add(cell.toString());
      }
      data.add(rowData);
    }
    return data;
  }

  // FIXED: Upload exam data to Firestore with proper nested structure
  Future<List<String>> _uploadExamDataToFirestore(List<List<String>> data, String fileName, String batchId) async {
    if (data.length <= 1) return [];

    final headers = data[0].map((h) => h.toLowerCase()).toList();
    List<String> documentIds = [];
    final batch = FirebaseFirestore.instance.batch();

    print('📊 Processing exams with ${data.length - 1} rows');
    print('📋 Headers: $headers');

    for (int i = 1; i < data.length; i++) {
      final row = data[i];
      if (row.isEmpty || row.every((cell) => cell.trim().isEmpty)) continue;

      // Create row data map
      final rowData = <String, String>{};
      for (int j = 0; j < headers.length && j < row.length; j++) {
        final value = row[j].trim();
        if (value.isNotEmpty) {
          rowData[headers[j]] = value;
        }
      }

      // Process exam row
      final documentId = await _processExamRow(rowData, batch, fileName, batchId);
      if (documentId != null) {
        documentIds.add(documentId);
      }
    }

    if (documentIds.isNotEmpty) {
      await batch.commit();
      print('✅ Successfully uploaded ${documentIds.length} exam records');
    }

    return documentIds;
  }

  // Process individual exam row
  Future<String?> _processExamRow(Map<String, String> rowData, WriteBatch batch, String fileName, String batchId) async {
    // Get required fields
    final rollNumber = _getRowValue(rowData, ['rollnumber', 'rollno', 'roll', 'studentid']);
    final year = _getRowValue(rowData, ['year']);
    final semester = _getRowValue(rowData, ['semester']);
    final cgpa = _getRowValue(rowData, ['cgpa']);
    final sgpa = _getRowValue(rowData, ['sgpa']);

    print('🔍 Processing exam row: $rollNumber, $year, $semester, CGPA: $cgpa, SGPA: $sgpa');

    // Validate required fields
    if (rollNumber == null || rollNumber.isEmpty) {
      print('❌ Missing roll number');
      return null;
    }
    if (year == null || year.isEmpty) {
      print('❌ Missing year');
      return null;
    }
    if (semester == null || semester.isEmpty) {
      print('❌ Missing semester');
      return null;
    }

    final standardizedRollNo = _standardizeRollNumber(rollNumber);
    final double? cgpaValue = double.tryParse(cgpa ?? '');
    final double? sgpaValue = double.tryParse(sgpa ?? '');

    // Skip if both CGPA and SGPA are empty
    if (cgpaValue == null && sgpaValue == null) {
      print('⚠️ Skipping: Both CGPA and SGPA are empty/invalid');
      return standardizedRollNo;
    }

    final docRef = FirebaseFirestore.instance.collection('exams').doc(standardizedRollNo);

    // Create semester data
    final semesterData = <String, dynamic>{};
    if (cgpaValue != null) semesterData['CGPA'] = cgpaValue;
    if (sgpaValue != null) semesterData['SGPA'] = sgpaValue;

    // Create update data with nested structure
    final updateData = {
      'studentEmail': '$standardizedRollNo@miit.edu.mm',
      'lastUpdated': FieldValue.serverTimestamp(),
      'fileName': fileName,

    };

    // Create nested structure: year -> semester -> data
    if (!updateData.containsKey(year)) {
      updateData[year] = {};
    }

    // Add the semester data to the year
    (updateData[year] as Map)[semester] = semesterData;

    print('📦 Exam update for $standardizedRollNo: $year -> $semester = $semesterData');
    batch.set(docRef, updateData, SetOptions(merge: true));

    return standardizedRollNo;
  }

  // Upload entrance data to Firestore
  Future<List<String>> _uploadEntranceDataToFirestore(List<List<String>> data, String fileName, String batchId) async {
    if (data.length <= 1) return [];

    final headers = data[0].map((h) => h.toLowerCase()).toList();
    List<String> documentIds = [];
    final batch = FirebaseFirestore.instance.batch();

    for (int i = 1; i < data.length; i++) {
      final row = data[i];
      if (row.isEmpty || row.every((cell) => cell.trim().isEmpty)) continue;

      final rowData = <String, dynamic>{};
      for (int j = 0; j < headers.length && j < row.length; j++) {
        final value = row[j].trim();
        if (value.isNotEmpty) {
          rowData[data[0][j]] = value;
        }
      }

      // Add metadata
      rowData['uploadedAt'] = FieldValue.serverTimestamp();
      rowData['fileName'] = fileName;
      rowData['batchId'] = batchId;

      final rollNumber = _getRowValue(rowData, ['rollnumber', 'rollno', 'roll', 'studentid']);
      if (rollNumber == null || rollNumber.isEmpty) {
        print('❌ Skipping row $i: No rollNumber found');
        continue;
      }

      final documentId = _standardizeRollNumber(rollNumber);
      final docRef = FirebaseFirestore.instance.collection('entrance_pass_stu').doc(documentId);
      batch.set(docRef, rowData);
      documentIds.add(documentId);
    }

    if (documentIds.isNotEmpty) {
      await batch.commit();
      print('✅ Successfully uploaded ${documentIds.length} entrance records');
    }

    return documentIds;
  }

  // Helper method to get value from row data
  String? _getRowValue(dynamic rowData, List<String> possibleKeys) {
    for (String key in possibleKeys) {
      final value = rowData[key]?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  // Delete Firestore data
  Future<void> _deleteFirestoreData(int index) async {
    try {
      final fileData = uploadedFileData[index];
      final fileType = fileData['fileType'];
      final documentIds = List<String>.from(fileData['documentIds'] ?? []);
      final batchId = fileData['batchId'];

      if (documentIds.isEmpty && batchId == null) return;

      String collectionName = fileType == 'exam_results' ? 'exams' : 'entrance_pass_stu';

      final batch = FirebaseFirestore.instance.batch();
      for (String docId in documentIds) {
        final docRef = FirebaseFirestore.instance.collection(collectionName).doc(docId);
        batch.delete(docRef);
      }
      await batch.commit();
      print('Deleted ${documentIds.length} documents from $collectionName');

      // Backup deletion by batchId
      if (batchId != null) {
        final query = await FirebaseFirestore.instance
            .collection(collectionName)
            .where('batchId', isEqualTo: batchId)
            .get();

        if (query.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (var doc in query.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          print('Deleted ${query.docs.length} documents with batchId $batchId');
        }
      }
    } catch (e) {
      print('Error deleting Firestore data: $e');
    }
  }

  // UI Helper methods
  String _getFileTypeDisplayName(String fileType) {
    return fileType == 'exam_results' ? 'Exam Results' : 'Entrance Pass Students';
  }

  String _getFileTypeIcon(String fileType) {
    return fileType == 'exam_results' ? '📊' : '🎓';
  }

  // Remove single file
  void _removeFile(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete File'),
        content: Text('This will remove the file and delete all its data from the database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteFirestoreData(index);

              setState(() {
                uploadedFiles.removeAt(index);
                if (uploadedFileData.length > index) {
                  uploadedFileData.removeAt(index);
                }
              });
              await _saveUploadedFiles();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗑️ File and data deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Clear all files
  void _clearAllFiles() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Files'),
        content: Text('This will remove all uploaded files and delete their data from the database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              for (int i = 0; i < uploadedFileData.length; i++) {
                await _deleteFirestoreData(i);
              }

              setState(() {
                uploadedFiles.clear();
                uploadedFileData.clear();
              });
              await _saveUploadedFiles();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗑️ All files and data cleared'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // Academic settings methods
  Future<void> _loadAcademicSettings() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('admin_academic_year')
          .doc('admin')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          _startYearController.text = (data['astart_year'] as int?)?.toString() ?? '';
          _endYearController.text = (data['aend_year'] as int?)?.toString() ?? '';
          _normalPaymentController.text = (data['set_amount'] as num?)?.toString() ?? '0';
          _masterPaymentController.text = (data['set_amount_master'] as num?)?.toString() ?? '0';
          _isLoadingSettings = false;
        });
      } else {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    } catch (e) {
      print('Error loading academic settings: $e');
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _saveAcademicSettings() async {
    final startYear = int.tryParse(_startYearController.text);
    final endYear = int.tryParse(_endYearController.text);
    final normalPayment = double.tryParse(_normalPaymentController.text) ?? 0.0;
    final masterPayment = double.tryParse(_masterPaymentController.text) ?? 0.0;

    if (startYear == null || endYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Please enter valid start and end years'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (endYear <= startYear) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ End year must be greater than start year'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('admin_academic_year')
          .doc('admin')
          .set({
        'astart_year': startYear,
        'aend_year': endYear,
        'set_amount': normalPayment,
        'set_amount_master': masterPayment,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Academic settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error saving academic settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // UI Components
  Widget _buildAcademicYearCard() {
    final startYear = _startYearController.text;
    final endYear = _endYearController.text;
    final normalPayment = _normalPaymentController.text.isEmpty ? '0' : _normalPaymentController.text;
    final masterPayment = _masterPaymentController.text.isEmpty ? '0' : _masterPaymentController.text;

    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Academic Year and Payment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.blue, size: 24),
                  onPressed: _showAcademicSettingsDialog,
                ),
              ],
            ),
            SizedBox(height: 16),
            _isLoadingSettings
                ? Center(child: CircularProgressIndicator())
                : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Academic Year',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              startYear.isNotEmpty && endYear.isNotEmpty
                                  ? '$startYear - $endYear'
                                  : 'Not Set',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentCard(
                        'B.E Student Payment',
                        'Ks $normalPayment',
                        Icons.person,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildPaymentCard(
                        'M.E Student Payment',
                        'Ks $masterPayment',
                        Icons.school,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(String title, String amount, IconData icon, MaterialColor color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color[100]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showAcademicSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.school, color: Colors.blue),
                SizedBox(width: 8),
                Text('Academic Settings'),
              ],
            ),
            content: SingleChildScrollView(
              child: _isLoadingSettings
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startYearController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Start Year',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _endYearController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'End Year',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _normalPaymentController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'B.E Student Payment',
                      border: OutlineInputBorder(),
                      prefixText: 'Ks ',
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _masterPaymentController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'M.E Student Payment',
                      border: OutlineInputBorder(),
                      prefixText: 'Ks ',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveAcademicSettings();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilesList() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uploaded Files (${uploadedFiles.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: uploadedFiles.length,
                  itemBuilder: (context, index) {
                    final file = uploadedFiles[index];
                    final fileData = uploadedFileData[index];
                    final documentCount = (fileData['documentIds'] ?? []).length;

                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Text(
                          _getFileTypeIcon(fileData['fileType']),
                          style: TextStyle(fontSize: 20),
                        ),
                        title: Text(file.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${(file.size / 1024).toStringAsFixed(1)} KB • ${fileData['status']}'),
                            Text(
                              'Type: ${_getFileTypeDisplayName(fileData['fileType'])} • Records: $documentCount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_red_eye, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FilePreviewPage(file: file),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFile(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showFileTypeSelection,
          icon: Icon(Icons.add),
          label: Text('Add More Files'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _showFileTypeSelection,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.blue[100]!,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload, size: 64, color: Colors.blue[400]!),
            SizedBox(height: 16),
            Text(
              "Upload Excel/CSV File",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Click to select file type and upload",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
              "Supported formats: .xlsx, .xls, .csv, .txt",
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.purple[50]!],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload, size: 32, color: Colors.blue[700]!),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Student Data',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Upload Excel or CSV files for exam results or entrance pass students',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (uploadedFiles.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear_all, color: Colors.red, size: 28),
                    onPressed: _clearAllFiles,
                  ),
              ],
            ),
            SizedBox(height: 24),
            uploadedFiles.isEmpty ? _buildUploadArea() : _buildFilesList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildAcademicYearCard(),
              SizedBox(height: 20),
              _buildUploadSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// FilePreviewPage remains the same as in your original code
class FilePreviewPage extends StatefulWidget {
  final PlatformFile file;
  const FilePreviewPage({Key? key, required this.file}) : super(key: key);
  @override
  _FilePreviewPageState createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  List<List<String>>? _fileData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFileData();
  }

  Future<void> _loadFileData() async {
    try {
      if (widget.file.bytes == null) throw Exception('File bytes are null');

      if (widget.file.extension == 'xlsx' || widget.file.extension == 'xls') {
        _fileData = await _parseExcelFile(widget.file.bytes!);
      } else if (widget.file.extension == 'csv' || widget.file.extension == 'txt') {
        _fileData = await _parseCsvFile(widget.file.bytes!);
      } else {
        throw Exception('Unsupported file format: ${widget.file.extension}');
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<List<List<String>>> _parseExcelFile(List<int> bytes) async {
    final excel = ex.Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return [];

    List<List<String>> data = [];
    for (var row in sheet.rows) {
      data.add(row.map((cell) => cell?.value?.toString() ?? '').toList());
    }
    return data;
  }

  Future<List<List<String>>> _parseCsvFile(List<int> bytes) async {
    final content = String.fromCharCodes(bytes);
    final rows = const CsvToListConverter().convert(content);
    return rows.map((row) => row.map((cell) => cell.toString()).toList()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview: ${widget.file.name}',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text('${_fileData?.length ?? 0} rows', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading ? Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty ? Center(child: Text("Error: $_errorMessage"))
                : _fileData == null || _fileData!.isEmpty ? Center(child: Text("No data available"))
                : Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columns: _fileData![0].asMap().entries.map((entry) => DataColumn(
                        label: Expanded(child: Text(entry.value.isEmpty ? 'Column ${entry.key + 1}' : entry.value)),
                      )).toList(),
                      rows: _fileData!.sublist(1).asMap().entries.map((entry) => DataRow(
                        cells: entry.value.asMap().entries.map((cell) => DataCell(Text(cell.value))).toList(),
                      )).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

