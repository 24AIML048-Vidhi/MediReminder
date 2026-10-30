import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/health_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/formatters.dart';
import '../../utils/health_evaluator.dart';
import '../../widgets/custom_text_field.dart';

class AddEditHealthScreen extends StatefulWidget {
  final HealthRecord? record;

  const AddEditHealthScreen({super.key, this.record});

  @override
  State<AddEditHealthScreen> createState() => _AddEditHealthScreenState();
}

class _AddEditHealthScreenState extends State<AddEditHealthScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _dateTime;
  late TextEditingController _weightController;
  late TextEditingController _systolicController;
  late TextEditingController _diastolicController;
  late TextEditingController _glucoseController;
  late TextEditingController _temperatureController;
  late TextEditingController _notesController;
  late String _glucoseUnit;

  @override
  void initState() {
    super.initState();
    final rec = widget.record;

    _dateTime = rec?.dateTime ?? DateTime.now();
    _weightController = TextEditingController(
      text: rec?.weightKg != null ? rec!.weightKg.toString() : '',
    );
    _systolicController = TextEditingController(
      text: rec?.systolicBp != null ? rec!.systolicBp.toString() : '',
    );
    _diastolicController = TextEditingController(
      text: rec?.diastolicBp != null ? rec!.diastolicBp.toString() : '',
    );
    _glucoseController = TextEditingController(
      text: rec?.bloodGlucose != null ? rec!.bloodGlucose.toString() : '',
    );
    _temperatureController = TextEditingController(
      text: rec?.temperatureC != null ? rec!.temperatureC.toString() : '',
    );
    _notesController = TextEditingController(text: rec?.notes ?? '');
    _glucoseUnit = rec?.bloodGlucoseUnit ?? AppConstants.glucoseMgDl;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _glucoseController.dispose();
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _dateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightController.text.trim());
    final systolic = int.tryParse(_systolicController.text.trim());
    final diastolic = int.tryParse(_diastolicController.text.trim());
    final glucose = double.tryParse(_glucoseController.text.trim());
    final temperature = double.tryParse(_temperatureController.text.trim());

    if (weight == null &&
        systolic == null &&
        diastolic == null &&
        glucose == null &&
        temperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one health measurement.'),
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);

    final uid = auth.user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to record health vitals.'),
        ),
      );
      return;
    }

    final record = HealthRecord(
      id: widget.record?.id ?? '',
      userId: uid,
      dateTime: _dateTime,
      weightKg: weight,
      systolicBp: systolic,
      diastolicBp: diastolic,
      bloodGlucose: glucose,
      bloodGlucoseUnit: _glucoseUnit,
      temperatureC: temperature,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.record?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (widget.record != null) {
      success = await healthProvider.updateHealthRecord(record);
    } else {
      success = await healthProvider.addHealthRecord(record);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.record != null
                ? 'Health entry updated.'
                : 'Health measurement logged successfully.',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else if (healthProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(healthProvider.errorMessage!),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.record != null;
    final healthProvider = Provider.of<HealthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Health Entry' : 'Log Health Vitals'),
        actions: [
          TextButton(
            onPressed: healthProvider.isLoading ? null : _handleSave,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Measurement Date & Time picker
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.event_available_rounded, size: 18),
                label: Text(
                  'Measured: ${Formatters.formatDateTime(_dateTime)}',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Blood Pressure Row
              const Text(
                'Blood Pressure (mmHg)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _systolicController,
                      label: 'Systolic (Top)',
                      hint: '120',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.arrow_upward_rounded,
                      validator: (val) {
                        if (val != null && val.isNotEmpty) {
                          final num = int.tryParse(val);
                          if (num == null || num < 40 || num > 300) {
                            return 'Valid range: 40–300';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _diastolicController,
                      label: 'Diastolic (Bottom)',
                      hint: '80',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.arrow_downward_rounded,
                      validator: (val) {
                        if (val != null && val.isNotEmpty) {
                          final num = int.tryParse(val);
                          if (num == null || num < 30 || num > 200) {
                            return 'Valid range: 30–200';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Blood Glucose Row
              const Text(
                'Blood Glucose',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _glucoseController,
                      label: 'Glucose Level',
                      hint: '95',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: Icons.bloodtype_rounded,
                      validator: (val) {
                        if (val != null && val.isNotEmpty) {
                          final num = double.tryParse(val);
                          if (num == null || num <= 0 || num > 800) {
                            return 'Enter valid level';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _glucoseUnit,
                          items: const [
                            DropdownMenuItem(
                              value: AppConstants.glucoseMgDl,
                              child: Text(AppConstants.glucoseMgDl),
                            ),
                            DropdownMenuItem(
                              value: AppConstants.glucoseMmolL,
                              child: Text(AppConstants.glucoseMmolL),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _glucoseUnit = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Weight and Temperature Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      hint: '70.5',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: Icons.monitor_weight_outlined,
                      validator: (val) {
                        if (val != null && val.isNotEmpty) {
                          final num = double.tryParse(val);
                          if (num == null || num < 10 || num > 400) {
                            return 'Range: 10–400 kg';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _temperatureController,
                      label: 'Temperature (°C)',
                      hint: '36.8',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: Icons.thermostat_rounded,
                      validator: (val) {
                        if (val != null && val.isNotEmpty) {
                          final num = double.tryParse(val);
                          if (num == null || num < 30 || num > 45) {
                            return 'Range: 30–45 °C';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Symptoms & Notes
              CustomTextField(
                controller: _notesController,
                label: 'Symptoms / Context Notes (Optional)',
                hint: 'e.g., Measured fasting; slight dizziness in the morning',
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Academic / Clinical Disclaimer Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        HealthEvaluator.disclaimer,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: healthProvider.isLoading ? null : _handleSave,
                child: healthProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Record Measurement'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
