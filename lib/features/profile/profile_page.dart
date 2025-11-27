import 'dart:io';
import 'package:aarogya/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aarogya/login/login_controler.dart';
import 'profile_controller.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final ProfileController controller = Get.put(ProfileController());
  final LoginControler loginController = Get.put(LoginControler());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Health Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Obx(() => IconButton(
                icon: Icon(controller.isEditing.value ? Icons.close : Icons.edit),
                onPressed: controller.toggleEdit,
              )),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
            tooltip: 'Share Profile',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0F2F1), // Light Teal
                  AppTheme.backgroundColor,
                ],
              ),
            ),
          ),
          
          Obx(
            () => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPersonalInfoCard(),
                  const SizedBox(height: 16),
                  _buildVitalsCard(),
                  const SizedBox(height: 16),
                  _buildMedicalHistoryCard(),
                  const SizedBox(height: 16),
                  _buildEmergencyContactCard(),
                  const SizedBox(height: 24),
                  if (controller.isEditing.value)
                    ElevatedButton.icon(
                      onPressed: controller.saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onBackgroundColor),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.grey),
            _buildTextField(
              label: 'Full Name',
              value: controller.profile.value.name,
              onChanged: controller.updateName,
              icon: Icons.badge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Age',
                    value: controller.profile.value.age?.toString(),
                    onChanged: controller.updateAge,
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Gender',
                    value: controller.profile.value.gender,
                    items: ['Male', 'Female', 'Other'],
                    onChanged: controller.updateGender,
                    icon: Icons.wc,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Blood Type',
              value: controller.profile.value.bloodType,
              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
              onChanged: controller.updateBloodType,
              icon: Icons.bloodtype,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.monitor_heart, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Vitals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onBackgroundColor),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.grey),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Height (cm)',
                    value: controller.profile.value.height?.toString(),
                    onChanged: controller.updateHeight,
                    icon: Icons.height,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Weight (kg)',
                    value: controller.profile.value.weight?.toString(),
                    onChanged: controller.updateWeight,
                    icon: Icons.monitor_weight,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (controller.profile.value.bmi != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getBmiColor(controller.profile.value.bmi!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getBmiColor(controller.profile.value.bmi!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BMI', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        Text(
                          controller.profile.value.bmi!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getBmiColor(controller.profile.value.bmi!),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getBmiColor(controller.profile.value.bmi!),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        controller.profile.value.bmiCategory,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medical_services, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Medical History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onBackgroundColor),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.grey),
            _buildChipList(
              title: 'Allergies',
              items: controller.profile.value.allergies ?? [],
              onAdd: controller.addAllergy,
              onRemove: controller.removeAllergy,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildChipList(
              title: 'Chronic Conditions',
              items: controller.profile.value.chronicConditions ?? [],
              onAdd: controller.addChronicCondition,
              onRemove: controller.removeChronicCondition,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            _buildChipList(
              title: 'Current Medications',
              items: controller.profile.value.currentMedications ?? [],
              onAdd: controller.addMedication,
              onRemove: controller.removeMedication,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _buildChipList(
              title: 'Past Surgeries',
              items: controller.profile.value.pastSurgeries ?? [],
              onAdd: controller.addSurgery,
              onRemove: controller.removeSurgery,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emergency, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Emergency Contact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onBackgroundColor),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.grey),
            _buildTextField(
              label: 'Contact Name',
              value: controller.profile.value.emergencyContactName,
              onChanged: controller.updateEmergencyContactName,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Contact Phone',
              value: controller.profile.value.emergencyContactPhone,
              onChanged: controller.updateEmergencyContactPhone,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? value,
    required Function(String) onChanged,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: TextEditingController(text: value ?? ''),
      enabled: controller.isEditing.value,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: controller.isEditing.value ? Colors.white : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    String? value,
    required List<String> items,
    required Function(String) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true, // Ensures dropdown expands to fit container
      items: items.map((item) => DropdownMenuItem(
        value: item, 
        child: Text(
          item,
          overflow: TextOverflow.ellipsis, // Prevent text overflow
          style: const TextStyle(fontSize: 14),
        ),
      )).toList(),
      onChanged: controller.isEditing.value ? (val) => val != null ? onChanged(val) : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: controller.isEditing.value ? Colors.white : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      style: const TextStyle(fontSize: 14, color: AppTheme.onBackgroundColor),
      icon: const Icon(Icons.arrow_drop_down, size: 20),
    );
  }

  Widget _buildChipList({
    required String title,
    required List<String> items,
    required Function(String) onAdd,
    required Function(String) onRemove,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.onBackgroundColor),
            ),
            if (controller.isEditing.value)
              IconButton(
                icon: Icon(Icons.add_circle, color: color),
                onPressed: () => _showAddDialog(title, onAdd),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            'No $title added',
            style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic, fontSize: 14),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Chip(
                label: Text(item),
                backgroundColor: color.withOpacity(0.1),
                labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
                deleteIcon: controller.isEditing.value ? const Icon(Icons.close, size: 18) : null,
                onDeleted: controller.isEditing.value ? () => onRemove(item) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: color.withOpacity(0.3)),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showAddDialog(String title, Function(String) onAdd) {
    final textController = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add $title'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'Enter $title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                onAdd(textController.text);
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}
