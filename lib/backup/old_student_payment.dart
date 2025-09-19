import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'my_drawer.dart';
import 'package:miit_project/components/text.dart';

class OldStudentPaymentQR extends StatefulWidget {
  const OldStudentPaymentQR({super.key});

  @override
  State<OldStudentPaymentQR> createState() => _OldStudentPaymentQRState();
}

class _OldStudentPaymentQRState extends State<OldStudentPaymentQR> {
  final _formKey = GlobalKey<FormState>();

  final rollNoController = TextEditingController();
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final referenceController = TextEditingController();

  String _date = "";
  String? _qrData;

  @override
  void initState() {
    super.initState();
    referenceController.text = _generateReference();
    final today = DateTime.now();
    _date =
    "${today.year.toString().padLeft(4, '0')}-"
        "${today.month.toString().padLeft(2, '0')}-"
        "${today.day.toString().padLeft(2, '0')}";
  }

  String _generateReference() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final part =
    List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
    final today = DateTime.now();
    final ymd =
        "${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";
    return "MIIT-$ymd-$part";
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text("warning".tr()),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("ok".tr(), style: const TextStyle(color: Colors.indigo)),
          ),
        ],
      ),
    );
  }

  void _generateQR() {
    if (!_formKey.currentState!.validate()) {
      _showAlert("fillAllFields".tr());
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      _showAlert("invalidAmount".tr());
      return;
    }

    final payload = [
      "MIITPAY",
      "ref=${referenceController.text.trim()}",
      "roll=${rollNoController.text.trim()}",
      "name=${nameController.text.trim()}",
      "amt=${amount.toStringAsFixed(2)}",
      "date=$_date",
    ].join("|");

    setState(() {
      _qrData = payload;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("qrGenerated".tr())),
    );
  }

  OutlineInputBorder get inputBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.black26),
  );

  Widget _buildBoxField({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    rollNoController.dispose();
    nameController.dispose();
    amountController.dispose();
    referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const MyDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF87CEFA), Color(0xFFADD8E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child:
                  Image.asset('assets/img_2.png', width: 50, height: 50),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tr("paymentForm"), style: AppTextStyles.heading),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: DropdownButton<Locale>(
                underline: const SizedBox(),
                icon: const Icon(Icons.language, color: Colors.black),
                value: context.locale,
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) context.setLocale(newLocale);
                },
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text("English")),
                  DropdownMenuItem(value: Locale('my'), child: Text("မြန်မာ")),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildBoxField(
                    child: TextFormField(
                      controller: referenceController,
                      decoration: InputDecoration(
                        labelText: "reference".tr(),
                        border: inputBorder,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "required".tr()
                          : null,
                    ),
                  ),
                  _buildBoxField(
                    child: TextFormField(
                      controller: rollNoController,
                      decoration: InputDecoration(
                        labelText: "rollNo".tr(),
                        border: inputBorder,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "required".tr()
                          : null,
                    ),
                  ),
                  _buildBoxField(
                    child: TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "studentName".tr(),
                        border: inputBorder,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "required".tr()
                          : null,
                    ),
                  ),
                  _buildBoxField(
                    child: TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: "amount".tr(),
                        hintText: "e.g. 5".tr(),
                        border: inputBorder,
                      ),
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "required".tr()
                          : null,
                    ),
                  ),
                  _buildBoxField(
                    child: TextFormField(
                      initialValue: _date,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "paymentDate".tr(),
                        border: inputBorder,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _generateQR,
              icon: const Icon(Icons.qr_code),
              label: Text("generateQR".tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_qrData != null) ...[
              QrImageView(
                data: _qrData!,
                version: QrVersions.auto,
                size: 200,
              ),
              const SizedBox(height: 10),
              // Display roll number note under QR code
              Text(
                "kPayNote".tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Display actual roll number
              const SizedBox(height: 20),
              // Upload KPay Screenshot Placeholder
              const SizedBox(height: 20),
              // Payment Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("paymentHistory".tr(),
                        style: AppTextStyles.heading),
                    const Divider(),
                    Text("QR No  :  ${referenceController.text}"),
                    Text("Roll No: ${rollNoController.text}"),
                    Text("Name   : ${nameController.text}"),
                    Text("Amount : ${amountController.text}"),
                    Text("Date   : $_date"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _qrData!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("paymentSaved".tr())),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: Text("savePayment".tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24), // optional
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "submitted".tr(),
                                  style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 25),
                                Text(
                                  "adminReply".tr(),
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text("ok".tr(), style: const TextStyle(color: Colors.indigo)),
                              ),
                            ],
                          ),
                        );

                      },
                      icon: const Icon(Icons.check_circle),
                      label: Text("submit".tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
