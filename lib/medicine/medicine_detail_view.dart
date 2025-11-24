import 'dart:io';

import 'package:aarogya/medicine/medicin_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class MedicineDetailView extends StatelessWidget {
    late final String imagePath;
  final MedicineController controller = Get.find();
   MedicineDetailView({required this.imagePath});


  @override
  Widget build(BuildContext context) {
    final medicine = controller.foundMedicine.value;

    return Scaffold(
      appBar: AppBar(
        title: Text("Medicine Details"),
        backgroundColor: Colors.blue[900],
      ),
      body: medicine == null
          ? Center(child: Text("No medicine details available."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Image.file(File(imagePath), height: 120),
                  SizedBox(height: 20),
                  Text(
                    medicine.medicineName,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900]),
                  ),
                  SizedBox(height: 20),
                  // Show usage (which contains all info from API)
                  if (medicine.usageInfo.isNotEmpty)
                    _buildDetailCard("Medicine Information", medicine.usageInfo),
                  // Only show these if they have content
                  if (medicine.dosageInfo.isNotEmpty)
                    _buildDetailCard("Dosage Information", medicine.dosageInfo),
                  if (medicine.warningInfo.isNotEmpty)
                    _buildDetailCard("Side Effects / Warnings", medicine.warningInfo),
                  SizedBox(height: 30),
                  Text(
                    "Disclaimer: Not a substitute for medical advice.",
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailCard(String title, String data) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900])),
            SizedBox(height: 8),
            Text(data, style: TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
