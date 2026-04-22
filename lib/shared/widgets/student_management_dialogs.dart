import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/utils/countries.dart';

class AddStudentDialog extends ConsumerStatefulWidget {
  const AddStudentDialog({super.key});

  @override
  ConsumerState<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends ConsumerState<AddStudentDialog> {
  final _nameController = TextEditingController();
  List<dynamic> _classes = [];
  String? _selectedClassId;
  String? _selectedGender;
  DateTime? _selectedDob;
  String? _selectedCountry;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _countries = CountryData.countries;
  List<String> _filteredCountries = [];
  final _countrySearchController = TextEditingController();

  bool _isLoadingClasses = false;
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


  @override
  void dispose() {
    _nameController.dispose();
    _countrySearchController.dispose();
    super.dispose();
  }

  void _showCountrySearch() {
    _filteredCountries = List.from(_countries);
    _countrySearchController.clear();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Country',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _countrySearchController,
                  onChanged: (val) {
                    setDialogState(() {
                      _filteredCountries = _countries
                          .where((c) => c.toLowerCase().contains(val.toLowerCase()))
                          .toList();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];
                      return ListTile(
                        title: Text(
                          country,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedCountry = country);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || 
        _selectedClassId == null || 
        _selectedGender == null || 
        _selectedDob == null || 
        _selectedCountry == null) {
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
        'gender': _selectedGender?.toLowerCase() == 'male' ? 'm' : (_selectedGender?.toLowerCase() == 'female' ? 'f' : 'o'),
        'dob': _selectedDob!.toIso8601String().split('T')[0],
        'country': _selectedCountry
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Gender Selector
                  _buildLabel('Gender', const Color(0xFFEC4899)),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    hint: 'Select Gender',
                    value: _selectedGender,
                    items: _genders.map((g) => DropdownMenuItem(
                      value: g,
                      child: Text(g, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),

                  const SizedBox(height: 16),

                  // Date of Birth
                  _buildLabel('Date of Birth', const Color(0xFFEC4899)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _selectedDob = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDob == null ? 'Select Date' : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _selectedDob == null ? Colors.grey[400] : Colors.black,
                            ),
                          ),
                          Icon(Icons.calendar_today, size: 18, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Country Selector
                  _buildLabel('Country', const Color(0xFFEC4899)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showCountrySearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCountry ?? 'Select Country',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _selectedCountry == null ? Colors.grey[400] : Colors.black,
                            ),
                          ),
                          Icon(Icons.search, size: 18, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

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
                        const Divider(height: 24),
                        _buildSummaryRow('Gender', _selectedGender ?? '-', const Color(0xFF1A1D4D)),
                        const Divider(height: 24),
                        _buildSummaryRow('Date of Birth', _selectedDob != null ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}' : '-', const Color(0xFF1A1D4D)),
                        const Divider(height: 24),
                        _buildSummaryRow('Country', _selectedCountry ?? '-', const Color(0xFF1A1D4D)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
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
  bool _isLoadingClasses = false;
  bool _isSubmitting = false;
  bool _showConfirm = false;
  String? _selectedClassId;

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


  Future<void> _submit() async {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select grade')),
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
    final user = ref.watch(userProvider).profile;
    final selectedClass = _classes.firstWhere((c) => c['id'].toString() == _selectedClassId, orElse: () => null);

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
              _showConfirm ? 'Please confirm your selection before proceeding.' : 'Move to a different grade level.',
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
                },
              ),
              
              const SizedBox(height: 16),
              

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
