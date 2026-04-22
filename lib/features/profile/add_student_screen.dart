import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/utils/countries.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _nameController = TextEditingController();
  String? _selectedClassId;
  String? _selectedGender;
  DateTime? _selectedDob;
  String? _selectedCountry = 'India';
  
  List<dynamic> _classes = [];
  bool _isLoadingClasses = true;
  bool _isSubmitting = false;
  List<String> _filteredCountries = [];
  final _countrySearchController = TextEditingController();

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _countries = CountryData.countries;

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

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final api = ref.read(apiServiceProvider);
      final classes = await api.getClasses();
      setState(() {
        _classes = classes;
        _isLoadingClasses = false;
        if (classes.isNotEmpty) {
          _selectedClassId = classes[0]['id'];
        }
      });
    } catch (e) {
      setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _selectedClassId == null || _selectedGender == null || _selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(apiServiceProvider);
      
      // Get the email from auth state for the signup call
      final user = ref.read(authProvider).user;
      final email = user?.email ?? "";

      await api.studentSignUp({
        'name': _nameController.text.trim(),
        'email': email,
        'classId': _selectedClassId,
        'gender': _selectedGender,
        'dob': DateFormat('yyyy-MM-dd').format(_selectedDob!),
        'country': _selectedCountry,
      });

      if (mounted) {
        // Success! Go back to profile selection to pick the newly created profile
        context.go('/select-profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save details: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Details',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Name *'),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Enter Name',
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Class *'),
                      _isLoadingClasses
                          ? const LinearProgressIndicator(color: AppColors.primary)
                          : _buildDropdown(
                              value: _selectedClassId,
                              items: _classes.map((c) {
                                return DropdownMenuItem(
                                  value: c['id'].toString(),
                                  child: Text(c['name'] ?? 'Grade'),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedClassId = val),
                              hint: 'Select Class',
                            ),
                      const SizedBox(height: 16),
                      _buildLabel('Gender *'),
                      _buildDropdown(
                        value: _selectedGender,
                        items: _genders.map((g) {
                          return DropdownMenuItem(value: g, child: Text(g));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedGender = val),
                        hint: 'Select Gender',
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Date of Birth *'),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDob == null
                                    ? 'dd-mm-yyyy'
                                    : DateFormat('dd-MM-yyyy').format(_selectedDob!),
                                style: TextStyle(
                                  color: _selectedDob == null ? Colors.grey : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Country *'),
                      InkWell(
                        onTap: _showCountrySearch,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedCountry ?? 'Select Country',
                                style: TextStyle(
                                  color: _selectedCountry == null ? Colors.grey : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(Icons.search, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Submit',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(hint, style: const TextStyle(color: Colors.grey)),
          ),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ),
      ),
    );
  }
}
