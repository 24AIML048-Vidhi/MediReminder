import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/medicine.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_text_field.dart';

class AddEditMedicineScreen extends StatefulWidget {
  final Medicine? medicine;

  const AddEditMedicineScreen({super.key, this.medicine});

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _dosageAmountController;
  late TextEditingController _doctorController;
  late TextEditingController _instructionsController;
  late TextEditingController _notesController;

  late String _selectedUnit;
  late String _selectedForm;
  late String _selectedFrequency;
  late bool _isOngoing;
  late DateTime _startDate;
  DateTime? _endDate;
  late List<TimeOfDay> _reminderTimes;
  late List<int> _selectedDays; // 1=Mon..7=Sun

  @override
  void initState() {
    super.initState();
    final med = widget.medicine;

    _nameController = TextEditingController(text: med?.name ?? '');
    _dosageAmountController = TextEditingController(
      text: med != null
          ? (med.dosageAmount % 1 == 0
                ? med.dosageAmount.toInt().toString()
                : med.dosageAmount.toString())
          : '1',
    );
    _doctorController = TextEditingController(text: med?.doctorName ?? '');
    _instructionsController = TextEditingController(
      text: med?.instructions ?? '',
    );
    _notesController = TextEditingController(text: med?.notes ?? '');

    _selectedUnit = med?.dosageUnit ?? AppConstants.dosageUnits.first;
    _selectedForm = med?.form ?? AppConstants.medicineForms.first;
    _selectedFrequency = med?.frequency ?? AppConstants.freqOnceDaily;
    _isOngoing = med?.isOngoing ?? true;
    _startDate = med?.startDate ?? DateTime.now();
    _endDate = med?.endDate;

    _reminderTimes = med != null
        ? List<TimeOfDay>.from(med.reminderTimes)
        : [const TimeOfDay(hour: 8, minute: 0)];

    _selectedDays = med != null ? List<int>.from(med.selectedDays) : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageAmountController.dispose();
    _doctorController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFrequencyChanged(String freq) {
    setState(() {
      _selectedFrequency = freq;
      if (freq == AppConstants.freqOnceDaily && _reminderTimes.length > 1) {
        _reminderTimes = [_reminderTimes.first];
      } else if (freq == AppConstants.freqTwiceDaily) {
        _reminderTimes = [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      } else if (freq == AppConstants.freqThreeDaily) {
        _reminderTimes = [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      }
    });
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );
    if (picked != null) {
      setState(() {
        _reminderTimes[index] = picked;
      });
    }
  }

  void _addReminderTime() {
    setState(() {
      _reminderTimes.add(const TimeOfDay(hour: 12, minute: 0));
    });
  }

  void _removeReminderTime(int index) {
    if (_reminderTimes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one reminder time is required.'),
        ),
      );
      return;
    }
    setState(() {
      _reminderTimes.removeAt(index);
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 7)),
      firstDate: _startDate,
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_reminderTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one reminder time.')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final medProvider = Provider.of<MedicineProvider>(context, listen: false);

    final uid = auth.user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save medications.')),
      );
      return;
    }

    final now = DateTime.now();
    final dosageAmount = double.tryParse(_dosageAmountController.text) ?? 1.0;

    final medicine = Medicine(
      id: widget.medicine?.id ?? '',
      userId: uid,
      name: _nameController.text.trim(),
      dosageAmount: dosageAmount,
      dosageUnit: _selectedUnit,
      form: _selectedForm,
      instructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
      doctorName: _doctorController.text.trim().isNotEmpty
          ? _doctorController.text.trim()
          : null,
      startDate: _startDate,
      endDate: _isOngoing ? null : _endDate,
      isOngoing: _isOngoing,
      frequency: _selectedFrequency,
      reminderTimes: _reminderTimes,
      selectedDays: _selectedDays,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      isActive: widget.medicine?.isActive ?? true,
      createdAt: widget.medicine?.createdAt ?? now,
      updatedAt: now,
    );

    bool success;
    if (widget.medicine != null) {
      success = await medProvider.updateMedicine(medicine);
    } else {
      success = await medProvider.addMedicine(medicine);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.medicine != null
                ? 'Medicine updated and reminders rescheduled.'
                : 'Medicine added and reminders scheduled!',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else if (medProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(medProvider.errorMessage!),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.medicine != null;
    final medProvider = Provider.of<MedicineProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Medicine' : 'Add Medicine'),
        actions: [
          TextButton(
            onPressed: medProvider.isLoading ? null : _handleSave,
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
              // Medicine Name
              CustomTextField(
                controller: _nameController,
                label: 'Medicine Name *',
                hint: 'e.g., Amoxicillin, Metformin, Lisinopril',
                prefixIcon: Icons.medication_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter medicine name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Dosage Amount & Unit Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _dosageAmountController,
                      label: 'Dosage Amount *',
                      hint: '1',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: Icons.straighten_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter amount';
                        }
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Must be > 0';
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
                          initialValue: _selectedUnit,
                          items: AppConstants.dosageUnits.map((u) {
                            return DropdownMenuItem(value: u, child: Text(u));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedUnit = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form Selector Chips (Tablet, Capsule, Syrup, etc.)
              const Text(
                'Medicine Form',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.medicineForms.map((form) {
                  final isSelected = _selectedForm == form;
                  return ChoiceChip(
                    label: Text(form),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedForm = form);
                    },
                    selectedColor: theme.colorScheme.primary.withValues(
                      alpha: 0.15,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Frequency Selector
              const Text(
                'Frequency',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.frequencyLabels.entries.map((entry) {
                  final isSelected = _selectedFrequency == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) _onFrequencyChanged(entry.key);
                    },
                    selectedColor: theme.colorScheme.primary.withValues(
                      alpha: 0.15,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Reminder Times List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reminder Times',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  TextButton.icon(
                    onPressed: _addReminderTime,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Time'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...List.generate(_reminderTimes.length, (index) {
                final time = _reminderTimes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          Formatters.formatTimeOfDay(time),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _pickTime(index),
                      ),
                      if (_reminderTimes.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          onPressed: () => _removeReminderTime(index),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Specific Days of the Week
              const Text(
                'Days of the Week',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final dayNum = i + 1; // 1 = Mon .. 7 = Sun
                  final dayName = Formatters.weekdayName(dayNum);
                  final isSelected =
                      _selectedDays.isEmpty || _selectedDays.contains(dayNum);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedDays.isEmpty) {
                          // Switching from "all days" to specific day toggle
                          _selectedDays = [1, 2, 3, 4, 5, 6, 7]..remove(dayNum);
                        } else if (_selectedDays.contains(dayNum)) {
                          _selectedDays.remove(dayNum);
                          if (_selectedDays.isEmpty) {
                            _selectedDays = [dayNum]; // Keep at least one
                          }
                        } else {
                          _selectedDays.add(dayNum);
                          if (_selectedDays.length == 7) {
                            _selectedDays.clear(); // Empty means every day
                          }
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1)),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dayName[0],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Schedule Duration (Ongoing toggle & Start/End Dates)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Ongoing Schedule',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'No specified end date (long-term medication)',
                ),
                value: _isOngoing,
                onChanged: (val) {
                  setState(() {
                    _isOngoing = val;
                    if (!val && _endDate == null) {
                      _endDate = _startDate.add(const Duration(days: 7));
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStartDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        'Start: ${Formatters.formatShortDate(_startDate)}',
                      ),
                    ),
                  ),
                  if (!_isOngoing) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickEndDate,
                        icon: const Icon(Icons.event_busy_rounded, size: 16),
                        label: Text(
                          'End: ${Formatters.formatShortDate(_endDate)}',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Doctor Name
              CustomTextField(
                controller: _doctorController,
                label: 'Prescribing Doctor (Optional)',
                hint: 'e.g., Dr. Smith',
                prefixIcon: Icons.person_pin_rounded,
              ),
              const SizedBox(height: 20),

              // Instructions
              CustomTextField(
                controller: _instructionsController,
                label: 'Instructions (Optional)',
                hint: 'e.g., Take after food with full glass of water',
                prefixIcon: Icons.info_outline_rounded,
              ),
              const SizedBox(height: 20),

              // Notes
              CustomTextField(
                controller: _notesController,
                label: 'Notes / Precautions (Optional)',
                hint: 'e.g., Avoid alcohol; store in refrigerator',
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: medProvider.isLoading ? null : _handleSave,
                child: medProvider.isLoading
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
                    : Text(isEditing ? 'Save Changes' : 'Create Schedule'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
