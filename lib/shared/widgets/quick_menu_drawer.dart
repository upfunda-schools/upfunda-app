import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import 'student_management_dialogs.dart';

class QuickMenuDrawer extends ConsumerStatefulWidget {
  const QuickMenuDrawer({super.key});

  @override
  ConsumerState<QuickMenuDrawer> createState() => _QuickMenuDrawerState();
}

class _QuickMenuDrawerState extends ConsumerState<QuickMenuDrawer> {
  bool _quickLinksExpanded = false;
  bool _ourCompanyExpanded = false;
  bool _contactExpanded = false;

  final String _assetPath = 'assets/images/quick_menu/';

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final profile = userState.profile;

    final userName = profile?.name ?? 'Guest User';
    const userRole = 'Student'; 
    final initials = userName.isNotEmpty 
        ? userName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase() 
        : '?';

    return Drawer(
      backgroundColor: Colors.white,
      width: 320, 
      child: SafeArea(
        child: Column(
          children: [
            // Header
            const SizedBox(height: 10),
            ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6B63D4),
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                userName,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                userRole,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF757575),
                ),
              ),
              trailing: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: _buildAssetImage('ci_close-lg.png', width: 20, fallback: Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 20, color: Color(0xFFEEEEEE)),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Pricing
                  _buildMenuItem(
                    title: 'Pricing',
                    useBold: false,
                    color: const Color(0xFF757575),
                    onTap: () => _launchUrl('https://upfunda.academy/pricingAmount'),
                  ),
                  
                  _buildAssetImage('Line 14.png', height: 1),

                  // Quick Links
                  _buildExpandableSection(
                    title: 'Quick Links',
                    isExpanded: _quickLinksExpanded,
                    onToggle: () => setState(() => _quickLinksExpanded = !_quickLinksExpanded),
                    children: [
                      _buildActionItem('Add Grade', () {
                        Navigator.pop(context);
                        showDialog(context: context, builder: (_) => const GradePromotionDialog());
                      }),
                      _buildActionItem('Add Student', () {
                        Navigator.pop(context);
                        showDialog(context: context, builder: (_) => const AddStudentDialog());
                      }),
                      _buildSubMenuItem('Login', 'https://upfunda.academy/login'),
                      _buildSubMenuItem('School Login', 'https://bo.upfunda.academy/login'),
                      _buildSubMenuItem('Student Sign Up', 'https://upfunda.academy/signup'),
                      _buildSubMenuItem('School Sign Up', 'https://upfunda.academy/signup-school'),
                      _buildSubMenuItem('FAQS', 'https://upfunda.academy/faq'),
                    ],
                  ),

                  _buildAssetImage('Line 15.png', height: 1),

                  // Our Company
                  _buildExpandableSection(
                    title: 'Our Company',
                    isExpanded: _ourCompanyExpanded,
                    onToggle: () => setState(() => _ourCompanyExpanded = !_ourCompanyExpanded),
                    children: [
                      _buildSubMenuItem('About Us', 'https://upfunda.academy/about'),
                      _buildSubMenuItem('Contact Us', 'https://upfunda.academy/contact'),
                      _buildSubMenuItem('Privacy Policy', 'https://upfunda.academy/privacy-policy'),
                      _buildSubMenuItem('Data Deletion', 'https://upfunda.academy/Data-Deletion'),
                      _buildSubMenuItem('Terms & Conditions', 'https://upfunda.academy/terms-conditions'),
                      _buildSubMenuItem('Refund Policy', 'https://upfunda.academy/refund-policy'),
                    ],
                  ),

                  _buildAssetImage('Line 16.png', height: 1),

                  // Contact
                  _buildExpandableSection(
                    title: 'Contact',
                    isExpanded: _contactExpanded,
                    onToggle: () => setState(() => _contactExpanded = !_contactExpanded),
                    children: [
                      _buildContactItem(
                        icon: 'lets-icons_phone-fill.png',
                        fallbackIcon: Icons.phone,
                        text: '+91 99941 80706',
                        onTap: () => _launchUrl('tel:+919994180706'),
                      ),
                      _buildContactItem(
                        icon: '', // Forcing fallback icon (Generation)
                        fallbackIcon: Icons.mail_rounded,
                        text: 'contact.upfunda@gmail.com',
                        onTap: () => _launchUrl('mailto:contact.upfunda@gmail.com'),
                      ),
                    ],
                  ),

                  _buildAssetImage('Line 17.png', height: 1),

                  const SizedBox(height: 20),

                  // My Profile
                  _buildLinkWithIcon(
                    icon: 'iconamoon_profile-fill.png',
                    fallbackIcon: Icons.person,
                    title: 'My Profile',
                    onTap: () {
                      context.push('/profile');
                      Navigator.pop(context);
                    },
                  ),

                  // Logout
                  _buildLinkWithIcon(
                    icon: 'humbleicons_logout.png',
                    fallbackIcon: Icons.logout,
                    title: 'Logout',
                    titleColor: const Color(0xFFF14336),
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/');
                      }
                    },
                  ),
                ],
              ),
            ),

            // Footer Logo
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildAssetImage(
                    'Upfunda logo 2.png',
                    height: 25,
                    fallback: Icons.school,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetImage(String fileName, {double? width, double? height, IconData? fallback}) {
    if (fileName.isEmpty && fallback != null) {
      return Icon(fallback, size: width ?? 20, color: const Color(0xFF6B63D4));
    }
    return Image.asset(
      '$_assetPath$fileName',
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        if (fallback != null) {
          return Icon(fallback, size: width ?? 20, color: const Color(0xFF6B63D4));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMenuItem({
    required String title,
    bool useBold = true,
    Color color = const Color(0xFF2D2D2D),
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: useBold ? FontWeight.bold : FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: onToggle, 
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          trailing: _buildAssetImage(
            isExpanded ? 'icon-park-outline_down-c.png' : 'arrow_down.png',
            width: 24,
            fallback: isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
      ],
    );
  }

  Widget _buildSubMenuItem(String title, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF757575),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF757575),
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required String icon,
    required IconData fallbackIcon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            _buildAssetImage(icon, width: 18, fallback: fallbackIcon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF757575),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkWithIcon({
    required String icon,
    required IconData fallbackIcon,
    required String title,
    Color titleColor = const Color(0xFF757575),
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _buildAssetImage(icon, width: 22, fallback: fallbackIcon),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      onTap: onTap,
    );
  }
}
