import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class AddStudentDialog extends ConsumerStatefulWidget {
  const AddStudentDialog({super.key});

  @override
  ConsumerState<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends ConsumerState<AddStudentDialog> {
  final _nameController = TextEditingController();
  List<dynamic> _classes = [];
  List<dynamic> _sections = [];
  String? _selectedClassId;
  String? _selectedSectionId;
  bool _isLoadingClasses = false;
  bool _isLoadingSections = false;
  bool _isSubmitting = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final classes = await ref.read(apiServiceProvider).getClasses();
      setState(() {
        _classes = classes..sort((a, b) {
          final ga = int.tryParse(a['grade']?.toString() ?? '0') ?? 0;
          final gb = int.tryParse(b['grade']?.toString() ?? '0') ?? 0;
          return ga.compareTo(gb);
        });
        _isLoadingClasses = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load grades')),
        );
      }
      setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _fetchSections(String classId) async {
    setState(() {
      _isLoadingSections = true;
      _selectedSectionId = null;
      _sections = [];
    });
    try {
      final user = ref.read(userProvider).profile;
      final schoolId = user?.schoolId ?? 'd3706d3c-4329-4bd5-b0f8-a9e113c7ae00';
      final sections = await ref.read(apiServiceProvider).getSections(schoolId, classId);
      setState(() {
        _sections = sections;
        _isLoadingSections = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load sections')),
        );
      }
      setState(() => _isLoadingSections = false);
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _selectedClassId == null || _selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (!_showConfirm) {
      setState(() => _showConfirm = true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(userProvider).profile;
      final payload = {
        'name': _nameController.text.trim(),
        'email': user?.email ?? '',
        'classId': _selectedClassId,
        'sectionId': _selectedSectionId,
        'schoolId': user?.schoolId,
        'gender': 'm',
        'dob': '2015-01-01',
        'country': user?.country ?? 'India'
      };

      await ref.read(apiServiceProvider).studentSignUp(payload);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully!')),
        );
        // Refresh home data
        ref.read(userProvider.notifier).loadHome();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedClass = _classes.firstWhere((c) => c['id'].toString() == _selectedClassId, orElse: () => null);
    final selectedSection = _sections.firstWhere((s) => s['id'].toString() == _selectedSectionId, orElse: () => null);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _showConfirm ? 'Confirm New Student' : 'Add New Student',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1D4D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showConfirm 
                ? 'Please confirm the student details before proceeding.' 
                : 'Create a sibling profile for this account.',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            
            if (!_showConfirm) ...[
              // Name Input
              _buildLabel('Student Name', const Color(0xFFEC4899)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: _inputDecoration('Enter student name', const Color(0xFFEC4899)),
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              
              const SizedBox(height: 16),
              
              // Grade Selector
              _buildLabel('Select Grade', const Color(0xFFEC4899)),
              const SizedBox(height: 8),
              _buildDropdown(
                hint: _isLoadingClasses ? 'Loading grades...' : 'Choose a grade',
                value: _selectedClassId,
                items: _classes.map((c) => DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text('Grade ${c['grade'] ?? c['name']}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                )).toList(),
                onChanged: (val) {
                  setState(() => _selectedClassId = val);
                  if (val != null) _fetchSections(val);
                },
              ),
              
              const SizedBox(height: 16),
              
              // Section Selector
              if (_selectedClassId != null) ...[
                _buildLabel('Select Section', const Color(0xFF6366F1)),
                const SizedBox(height: 8),
                _buildDropdown(
                  hint: _isLoadingSections ? 'Loading sections...' : 'Choose a section',
                  value: _selectedSectionId,
                  items: _sections.map((s) => DropdownMenuItem(
                    value: s['id'].toString(),
                    child: Text('Section ${s['name']}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedSectionId = val),
                ),
                const SizedBox(height: 24),
              ],

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFFFFB6C1),
                ),
                child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Add Student', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ] else ...[
              // Confirmation Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Student Name', _nameController.text, const Color(0xFF1A1D4D)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    _buildSummaryRow('Selected Grade', 'Grade ${selectedClass?['grade'] ?? selectedClass?['name']}', const Color(0xFFEC4899)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    _buildSummaryRow('Selected Section', 'Section ${selectedSection?['name']}', const Color(0xFF6366F1)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showConfirm = false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Text('Back', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: Colors.grey[600])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1D4D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Confirm & Create', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16)),
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

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color color) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.montserrat(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 2)),
    );
  }

  Widget _buildDropdown({required String hint, required String? value, required List<DropdownMenuItem<String>> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[400])),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class GradePromotionDialog extends ConsumerStatefulWidget {
  const GradePromotionDialog({super.key});

  @override
  ConsumerState<GradePromotionDialog> createState() => _GradePromotionDialogState();
}

class _GradePromotionDialogState extends ConsumerState<GradePromotionDialog> {
  List<dynamic> _classes = [];
  List<dynamic> _sections = [];
  String? _selectedClassId;
  String? _selectedSectionId;
  bool _isLoadingClasses = false;
  bool _isLoadingSections = false;
  bool _isSubmitting = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final user = ref.read(userProvider).profile;
      final classes = await ref.read(apiServiceProvider).getClasses();
      setState(() {
        _classes = classes.where((c) {
          final gradeStr = (c['grade'] ?? c['name'] ?? '').toString();
          return gradeStr != user?.className?.toString();
        }).toList()
        ..sort((a, b) {
          final ga = int.tryParse(a['grade']?.toString() ?? '0') ?? 0;
          final gb = int.tryParse(b['grade']?.toString() ?? '0') ?? 0;
          return ga.compareTo(gb);
        });
        _isLoadingClasses = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load grades')),
        );
      }
      setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _fetchSections(String classId) async {
    setState(() {
      _isLoadingSections = true;
      _selectedSectionId = null;
      _sections = [];
    });
    try {
      final user = ref.read(userProvider).profile;
      final schoolId = user?.schoolId ?? 'd3706d3c-4329-4bd5-b0f8-a9e113c7ae00';
      final sections = await ref.read(apiServiceProvider).getSections(schoolId, classId);
      
      String? autoSectionId;
      if (user?.sectionName != null) {
        for (var s in sections) {
          if (s['name'].toString().toLowerCase() == user!.sectionName!.toLowerCase()) {
            autoSectionId = s['id'].toString();
            break;
          }
        }
      }

      setState(() {
        _sections = sections;
        if (autoSectionId != null) _selectedSectionId = autoSectionId;
        _isLoadingSections = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load sections')),
        );
      }
      setState(() => _isLoadingSections = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedClassId == null || _selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select grade and section')),
      );
      return;
    }

    if (!_showConfirm) {
      setState(() => _showConfirm = true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(userProvider).profile;
      final payload = {
        'name': user?.name ?? '',
        'email': user?.email ?? '',
        'classId': _selectedClassId,
        'sectionId': _selectedSectionId,
        'schoolId': user?.schoolId,
        'gender': user?.gender ?? 'm',
        'dob': '2015-01-01',
        'country': user?.country ?? 'India'
      };

      await ref.read(apiServiceProvider).studentSignUp(payload);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grade changed successfully!')),
        );
        // Refresh EVERYTHING 
        ref.read(userProvider.notifier).loadHome();
        ref.read(userProvider.notifier).loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider).profile;
    final selectedClass = _classes.firstWhere((c) => c['id'].toString() == _selectedClassId, orElse: () => null);
    final selectedSection = _sections.firstWhere((s) => s['id'].toString() == _selectedSectionId, orElse: () => null);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _showConfirm ? 'Confirm Grade Change' : 'Change Grade',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1D4D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showConfirm 
                ? 'Please confirm your selection before proceeding.' 
                : 'Move to a different grade level.',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            
            if (!_showConfirm) ...[
              // Grade Selector
              _buildLabel('Target Grade', const Color(0xFF6366F1)),
              const SizedBox(height: 8),
              _buildDropdown(
                hint: _isLoadingClasses ? 'Loading grades...' : 'Choose a grade',
                value: _selectedClassId,
                items: _classes.map((c) => DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text('Grade ${c['grade'] ?? c['name']}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                )).toList(),
                onChanged: (val) {
                  setState(() => _selectedClassId = val);
                  if (val != null) _fetchSections(val);
                },
              ),
              
              const SizedBox(height: 16),
              
              // Section Selector
              if (_selectedClassId != null) ...[
                _buildLabel('Select Section', const Color(0xFF6366F1)),
                const SizedBox(height: 8),
                _buildDropdown(
                  hint: _isLoadingSections ? 'Loading sections...' : 'Choose a section',
                  value: _selectedSectionId,
                  items: _sections.map((s) => DropdownMenuItem(
                    value: s['id'].toString(),
                    child: Text('Section ${s['name']}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedSectionId = val),
                ),
                const SizedBox(height: 24),
              ],

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFFC7D2FE),
                ),
                child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Confirm Change', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ] else ...[
              // Confirmation Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Student Name', user?.name ?? '-', const Color(0xFF1A1D4D)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    _buildSummaryRow('New Grade', 'Grade ${selectedClass?['grade'] ?? selectedClass?['name']}', const Color(0xFF6366F1)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    _buildSummaryRow('New Section', 'Section ${selectedSection?['name']}', const Color(0xFF6366F1)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showConfirm = false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Text('Back', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: Colors.grey[600])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1D4D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Confirm & Proceed', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16)),
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

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDropdown({required String hint, required String? value, required List<DropdownMenuItem<String>> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[400])),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
