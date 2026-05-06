import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/user_provider.dart';
import 'widgets/avatar_display.dart';
import '../../data/models/user_avatar_config.dart';
import 'data/avatar_parts_data.dart';

const Map<String, Map<String, int>> avatarPartPrices = {

  'hairStyle': {'normal': 0, 'thick': 0, 'mohawk': 20, 'womanLong': 20, 'womanShort': 20},
  'hatStyle': {'none': 0, 'beanie': 50, 'turban': 50},
  'eyeStyle': {'circle': 0, 'oval': 0, 'smile': 20},
  'eyeBrowStyle': {'up': 0, 'upWoman': 0},
  'glassesStyle': {'none': 0, 'round': 10, 'square': 20},
  'earSize': {'small': 20, 'big': 0},
  'noseStyle': {'short': 20, 'long': 0, 'round': 0},
  'mouthStyle': {'laugh': 30, 'smile': 0, 'peace': 0},
  'shirtStyle': {'hoody': 0, 'short': 10, 'polo': 20},
  'shirtColor': {'#9287FF': 0, '#6BD9E9': 0, '#FC909F': 0, '#F4D150': 0, '#77311D': 0},
  'bgColor': {'#F44336': 10, '#4CAF50': 10, '#2196F3': 10, '#9C27B0': 10, '#FFFFFF': 0},
  'faceColor': {'#F9C9B6': 0, '#E5A07E': 0, '#C68642': 0},
};

int getAvatarPartPrice(String category, String value) {
  return avatarPartPrices[category]?[value] ?? 0;
}

class AvatarEditorScreen extends ConsumerStatefulWidget {
  const AvatarEditorScreen({super.key});

  @override
  ConsumerState<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends ConsumerState<AvatarEditorScreen> {
  late UserAvatarConfig _currentConfig;
  late UserAvatarConfig _initialConfig;
  bool _isModified = false;
  String _activeCategory = 'faceColor';
  int _localPoints = 0;
  final Set<String> _unlockedParts = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProvider).profile;
    _initialConfig = profile?.avatarConfig ?? UserAvatarConfig(
      sex: 'man',
      bgColor: '#FFFFFF',
      faceColor: '#F9C9B6',
      hairStyle: 'normal',
      hairColor: '#000000',
      eyeStyle: 'circle',
      mouthStyle: 'smile',
      shirtStyle: 'hoody',
      shirtColor: '#2196F3',
      earSize: 'big',
      eyeBrowStyle: 'up',
      noseStyle: 'long',
      glassesStyle: 'none',
      hatStyle: 'none',
    );
    _currentConfig = _initialConfig;
    _localPoints = profile?.upPoints ?? 0;

    _initializeUnlockedParts();
  }

  void _initializeUnlockedParts() {
    final profile = ref.read(userProvider).profile;
    
    // 1. Load from profile parsed list - Benefits from Triple-Key logic in model
    final purchased = profile?.purchasedAvatars;
                      
    if (purchased != null) {
      for (var item in purchased) {
        _unlockedParts.add('${item.part}:${item.value}');
      }
    }

    // 2. Add defaults (price 0)
    avatarPartPrices.forEach((category, parts) {
      parts.forEach((value, price) {
        if (price == 0) {
          _unlockedParts.add('$category:$value');
        }
      });
    });

    // 3. Current equipped should only be unlocked if price is 0
    // (Actual purchases are handled by Step 1)
    _addIfFree('sex', _currentConfig.sex);
    _addIfFree('faceColor', _currentConfig.faceColor);
    _addIfFree('bgColor', _currentConfig.bgColor);
    _addIfFree('hairStyle', _currentConfig.hairStyle);
    _addIfFree('eyeStyle', _currentConfig.eyeStyle);
    _addIfFree('mouthStyle', _currentConfig.mouthStyle);
    _addIfFree('shirtStyle', _currentConfig.shirtStyle);
    _addIfFree('hatStyle', _currentConfig.hatStyle);
    _addIfFree('eyeBrowStyle', _currentConfig.eyeBrowStyle);
    _addIfFree('glassesStyle', _currentConfig.glassesStyle);
    _addIfFree('earSize', _currentConfig.earSize);
    _addIfFree('noseStyle', _currentConfig.noseStyle);
  }

  void _addIfFree(String category, String? value) {
    if (value != null && getAvatarPartPrice(category, value) == 0) {
      _unlockedParts.add('$category:$value');
    }
  }

  String _getHairSvgForStyle(String style) {
    final color = _currentConfig.hairColor ?? '#000000';
    switch (style) {
      case 'thick': return AvatarPartsData.getHairThick(color);
      case 'mohawk': return AvatarPartsData.getHairMohawk(color);
      case 'womanLong': return AvatarPartsData.getHairWomanLong(color);
      case 'womanShort': return AvatarPartsData.getHairWomanShort(color);
      default: return AvatarPartsData.getHairNormal(color);
    }
  }

  String _getEyesSvgForStyle(String style) {
    switch (style) {
      case 'oval': return AvatarPartsData.getEyesOval();
      case 'smile': return AvatarPartsData.getEyesSmile();
      default: return AvatarPartsData.getEyesCircle();
    }
  }

  String _getMouthSvgForStyle(String style) {
    switch (style) {
      case 'laugh': return AvatarPartsData.getMouthLaugh();
      case 'peace': return AvatarPartsData.getMouthPeace();
      default: return AvatarPartsData.getMouthSmile();
    }
  }

  String _getShirtSvgForStyle(String style) {
    final color = _currentConfig.shirtColor ?? '#9287FF';
    switch (style) {
      case 'short': return AvatarPartsData.getShirtShort(color);
      case 'polo': return AvatarPartsData.getShirtPolo(color, color);
      default: return AvatarPartsData.getShirtHoody(color);
    }
  }

  String _getEyebrowSvgForStyle(String style) {
    switch (style) {
      case 'upWoman': return AvatarPartsData.getEyebrowUpWoman();
      default: return AvatarPartsData.getEyebrowUp();
    }
  }

  String _getGlassesSvgForStyle(String style) {
    switch (style) {
      case 'square': return AvatarPartsData.getGlassesSquare();
      default: return AvatarPartsData.getGlassesRound();
    }
  }

  String _getEarSvgForStyle(String style) {
    final color = _currentConfig.faceColor ?? '#F9C9B6';
    if (style == 'big') return AvatarPartsData.getEarBig(color);
    return AvatarPartsData.getEarSmall(color);
  }

  String _getHatSvgForStyle(String style) {
    final color = _currentConfig.hatColor ?? '#000000';
    if (style == 'beanie') return AvatarPartsData.getHatBeanie(color);
    return AvatarPartsData.getHatTurban(color);
  }

  String _getNoseSvgForStyle(String style) {
    switch (style) {
      case 'long': return AvatarPartsData.getNoseLong();
      case 'round': return AvatarPartsData.getNoseRound();
      default: return AvatarPartsData.getNoseShort();
    }
  }

  void _updateConfig(UserAvatarConfig newConfig, {int cost = 0, String? category, String? value}) {
    if (cost > 0) {
      if (_localPoints < cost) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough points!')),
        );
        return;
      }
      _showUnlockDialog(category ?? '', value ?? '', cost, () {
        setState(() {
          _currentConfig = newConfig;
          _isModified = true;
          if (_localPoints >= cost) {
            _localPoints -= cost;
          }
          if (category != null && value != null) {
            _unlockedParts.add('$category:$value');
          }
        });
      });
    } else {
      setState(() {
        _currentConfig = newConfig;
        _isModified = true;
        if (category != null && value != null) {
          _unlockedParts.add('$category:$value');
        }
      });
    }
  }

  String _getPrettyName(String value) {
    final Map<String, String> names = {
      'man': 'Male', 'woman': 'Female',
      '#F44336': 'Red', '#4CAF50': 'Green', '#2196F3': 'Blue', '#9C27B0': 'Purple',
      '#FFFFFF': 'White', '#FCED70': 'Yellow', '#F9C9B6': 'Peach', '#E5A07E': 'Tan', '#C68642': 'Brown',
      '#9287FF': 'Purple', '#6BD9E9': 'Cyan', '#FC909F': 'Pink', '#F4D150': 'Gold', '#77311D': 'Dark Brown',
      'normal': 'Normal', 'thick': 'Thick', 'mohawk': 'Mohawk', 'womanLong': 'Long Hair', 'womanShort': 'Short Hair',
      'circle': 'Circle', 'oval': 'Oval', 'smile': 'Smile', 'laugh': 'Laugh', 'peace': 'Peace',
      'hoody': 'Hoody', 'short': 'Short Sleeve', 'polo': 'Polo Shirt',
      'up': 'Classic', 'upWoman': 'Elegant', 'none': 'None', 'round': 'Round', 'square': 'Square',
      'small': 'Small', 'big': 'Big', 'beanie': 'Beanie', 'turban': 'Turban', 'long': 'Long',
    };
    return names[value] ?? value.replaceAll('#', '').toUpperCase();
  }

  void _showUnlockDialog(String category, String value, int cost, VoidCallback onConfirm) {
    final prettyName = _getPrettyName(value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                const Text('Unlock Item', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Color(0xFFE91E63), size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                children: [
                  const TextSpan(text: 'Do you want to unlock '),
                  TextSpan(text: '"$prettyName" ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const TextSpan(text: 'for '),
                  TextSpan(text: '$cost UP', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: _buildPartPreview(category, value, false),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: const Text('Unlock Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleReset() {
    setState(() {
      _currentConfig = _initialConfig;
      _isModified = false;
      _localPoints = ref.read(userProvider).profile?.upPoints ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), // gray-900
      body: Stack(
        children: [
          Column(
            children: [
              // Header - Web Parity
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 40, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const Text('Edit', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPointsBadge(),
                            const SizedBox(width: 4),
                            _buildHeaderButton(Icons.refresh, _handleReset, _isModified),
                            const SizedBox(width: 4),
                            _buildHeaderButton(Icons.delete, _handleRemove, true, color: Colors.red),
                            const SizedBox(width: 4),
                            _buildHeaderButton(Icons.save, _handleSave, _isModified, color: Colors.blue),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    
              // Select Part To Edit - Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Part To Edit', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildCategoryIcon('faceColor', Icons.palette),
                        _buildCategoryIcon('hairStyle', Icons.content_cut),
                        _buildCategoryIcon('hatStyle', Icons.theater_comedy),
                        _buildCategoryIcon('eyeStyle', Icons.visibility),
                        _buildCategoryIcon('eyeBrowStyle', Icons.face),
                        _buildCategoryIcon('glassesStyle', Icons.badge),
                        _buildCategoryIcon('earSize', Icons.hearing),
                        _buildCategoryIcon('noseStyle', Icons.auto_fix_normal),
                        _buildCategoryIcon('mouthStyle', Icons.sentiment_satisfied),
                        _buildCategoryIcon('shirtStyle', Icons.checkroom),
                        _buildCategoryIcon('shirtColor', Icons.format_paint),
                        _buildCategoryIcon('bgColor', Icons.circle, color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: AvatarDisplay(
                      key: ValueKey(_currentConfig),
                      config: _currentConfig,
                      size: 250,
                      shape: 'circle',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 250,
                color: const Color(0xFF1F2937),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _activeCategory.replaceAll('Style', '').replaceAll('Color', ' Color').toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Icon(Icons.close, color: Colors.white54, size: 20),
                        ],
                      ),
                    ),
                    Expanded(child: _buildOptionsGrid()),
                  ],
                ),
              ),
            ],
          ),
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.blue),
                      SizedBox(height: 16),
                      Text('Saving your avatar...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPointsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _localPoints < 0 ? Colors.red : Colors.amber[700],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$_localPoints UP',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onPressed, bool enabled, {Color? color}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: enabled ? (color ?? Colors.white12) : Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20, color: enabled ? Colors.white : Colors.white24),
      ),
    );
  }

  Widget _buildCategoryIcon(String category, IconData icon, {Color? color}) {
    final isActive = _activeCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = category),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : (color ?? Colors.grey[800]),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildOptionsGrid() {
    switch (_activeCategory) {

      case 'faceColor':
        return _buildColorOptions(['#F9C9B6', '#E5A07E', '#C68642'], 'faceColor');
      case 'bgColor':
        return _buildColorOptions(['#F44336', '#4CAF50', '#2196F3', '#9C27B0', '#FFFFFF'], 'bgColor');
      case 'hairStyle':
        return _buildStyleOptions(['normal', 'thick', 'mohawk', 'womanLong', 'womanShort'], 'hairStyle');
      case 'eyeStyle':
        return _buildStyleOptions(['circle', 'oval', 'smile'], 'eyeStyle');
      case 'mouthStyle':
        return _buildStyleOptions(['laugh', 'smile', 'peace'], 'mouthStyle');
      case 'shirtStyle':
        return _buildStyleOptions(['hoody', 'short', 'polo'], 'shirtStyle');
      case 'shirtColor':
        return _buildColorOptions(['#9287FF', '#6BD9E9', '#FC909F', '#F4D150', '#77311D'], 'shirtColor');
      case 'eyeBrowStyle':
        return _buildStyleOptions(['up', 'upWoman'], 'eyeBrowStyle');
      case 'glassesStyle':
        return _buildStyleOptions(['none', 'round', 'square'], 'glassesStyle');
      case 'earSize':
        return _buildStyleOptions(['small', 'big'], 'earSize');
      case 'hatStyle':
        return _buildStyleOptions(['none', 'beanie', 'turban'], 'hatStyle');
      case 'noseStyle':
        return _buildStyleOptions(['short', 'long', 'round'], 'noseStyle');
      default:
        return const Center(child: Text('More options coming soon...', style: TextStyle(color: Colors.white54)));
    }
  }

  Widget _buildColorOptions(List<String> colors, String field) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final colorStr = colors[index];
        final isSelected = (_getField(field) ?? '') == colorStr;
        final price = getAvatarPartPrice(field, colorStr);
        final isUnlocked = _unlockedParts.contains('$field:$colorStr');
        final isLocked = !isUnlocked && price > 0;

        final colorValue = _hexToColor(colorStr);

        return GestureDetector(
          onTap: () => _updateConfig(_copyWith(field, colorStr), cost: isLocked ? price : 0, category: field, value: colorStr),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: Colors.blue, width: 4) : Border.all(color: Colors.white10),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Color preview
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorValue,
                        shape: BoxShape.circle,
                      ),
                      child: isLocked 
                        ? Container(
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                            child: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                          )
                        : null,
                    ),
                    if (isLocked)
                      Positioned(
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Unlock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8)),
                        ),
                      ),
                  ],
                ),
              ),
              if (price > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber[700], borderRadius: BorderRadius.circular(10)),
                    child: Text('$price', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyleOptions(List<String> styles, String field) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: styles.length,
      itemBuilder: (context, index) {
        final style = styles[index];
        final isSelected = (_getField(field) ?? '') == style;
        final price = getAvatarPartPrice(field, style);
        final isUnlocked = _unlockedParts.contains('$field:$style');
        final isLocked = !isUnlocked && price > 0;

        return GestureDetector(
          onTap: () => _updateConfig(_copyWith(field, style), cost: isLocked ? price : 0, category: field, value: style),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: Colors.blue, width: 4) : Border.all(color: Colors.white10),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Preview (Grey circle backdrop for styles)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                      child: Opacity(
                        opacity: isLocked ? 0.4 : 1.0,
                        child: _buildPartPreview(field, style, isSelected),
                      ),
                    ),
                    if (isLocked)
                      const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                    if (isLocked)
                      Positioned(
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Unlock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8)),
                        ),
                      ),
                  ],
                ),
              ),
              if (price > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber[700], borderRadius: BorderRadius.circular(10)),
                    child: Text('$price', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartPreview(String field, String style, bool isSelected) {
    String? svg;
    Color iconColor = isSelected ? Colors.white : Colors.white70;

    switch (field) {

      case 'hairStyle':
        svg = _getHairSvgForStyle(style);
        break;
      case 'eyeStyle':
        svg = _getEyesSvgForStyle(style);
        break;
      case 'mouthStyle':
        svg = _getMouthSvgForStyle(style);
        break;
      case 'shirtStyle':
        svg = _getShirtSvgForStyle(style);
        break;
      case 'eyeBrowStyle':
        svg = _getEyebrowSvgForStyle(style);
        break;
      case 'glassesStyle':
        if (style == 'none') return Icon(Icons.close, color: iconColor);
        svg = _getGlassesSvgForStyle(style);
        break;
      case 'earSize':
        svg = _getEarSvgForStyle(style);
        break;
      case 'hatStyle':
        if (style == 'none') return Icon(Icons.close, color: iconColor);
        svg = _getHatSvgForStyle(style);
        break;
      case 'noseStyle':
        svg = _getNoseSvgForStyle(style);
        break;
    }

    if (svg != null) {
      Widget picture = SvgPicture.string(
        svg,
        key: ValueKey(svg),
        fit: field == 'shirtStyle' ? BoxFit.fitHeight : BoxFit.contain,
      );

      if (field == 'shirtStyle') {
        picture = ClipRect(child: picture);
      }

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: picture,
      );
    }

    if (field == 'bgColor' || field == 'faceColor') {
      return Center(
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: _hexToColor(style), shape: BoxShape.circle),
        ),
      );
    }

    return Text(
      _getPrettyName(style).toUpperCase(),
      style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold),
    );
  }



  String? _getField(String field) {
    switch (field) {
      case 'sex': return _currentConfig.sex;
      case 'faceColor': return _currentConfig.faceColor;
      case 'bgColor': return _currentConfig.bgColor;
      case 'hairStyle': return _currentConfig.hairStyle;
      case 'eyeStyle': return _currentConfig.eyeStyle;
      case 'mouthStyle': return _currentConfig.mouthStyle;
      case 'shirtStyle': return _currentConfig.shirtStyle;
      case 'hatStyle': return _currentConfig.hatStyle;
      case 'eyeBrowStyle': return _currentConfig.eyeBrowStyle;
      case 'glassesStyle': return _currentConfig.glassesStyle;
      case 'earSize': return _currentConfig.earSize;
      case 'noseStyle': return _currentConfig.noseStyle;
      case 'shirtColor': return _currentConfig.shirtColor;
      default: return null;
    }
  }

  UserAvatarConfig _copyWith(String field, String value) {
    if (field == 'sex') {
      if (value == 'woman') {
        String hair = _currentConfig.hairStyle ?? 'normal';
        if (hair == 'normal' || hair == 'thick' || hair == 'mohawk') {
          hair = 'womanLong';
        }
        String eyebrow = _currentConfig.eyeBrowStyle ?? 'up';
        if (eyebrow == 'up') {
          eyebrow = 'upWoman';
        }
        return _currentConfig.copyWith(
          sex: 'woman',
          hairStyle: hair,
          eyeBrowStyle: eyebrow,
        );
      } else if (value == 'man') {
        String hair = _currentConfig.hairStyle ?? 'normal';
        if (hair == 'womanLong' || hair == 'womanShort') {
          hair = 'normal';
        }
        String eyebrow = _currentConfig.eyeBrowStyle ?? 'upWoman';
        if (eyebrow == 'upWoman') {
          eyebrow = 'up';
        }
        return _currentConfig.copyWith(
          sex: 'man',
          hairStyle: hair,
          eyeBrowStyle: eyebrow,
        );
      }
    }

    switch (field) {
      case 'sex': return _currentConfig.copyWith(sex: value);
      case 'faceColor': return _currentConfig.copyWith(faceColor: value);
      case 'bgColor': return _currentConfig.copyWith(bgColor: value);
      case 'hairStyle': return _currentConfig.copyWith(hairStyle: value);
      case 'eyeStyle': return _currentConfig.copyWith(eyeStyle: value);
      case 'mouthStyle': return _currentConfig.copyWith(mouthStyle: value);
      case 'shirtStyle': return _currentConfig.copyWith(shirtStyle: value);
      case 'shirtColor': return _currentConfig.copyWith(shirtColor: value);
      case 'hatStyle': return _currentConfig.copyWith(hatStyle: value);
      case 'eyeBrowStyle': return _currentConfig.copyWith(eyeBrowStyle: value);
      case 'glassesStyle': return _currentConfig.copyWith(glassesStyle: value);
      case 'earSize': return _currentConfig.copyWith(earSize: value);
      case 'noseStyle': return _currentConfig.copyWith(noseStyle: value);
      default: return _currentConfig;
    }
  }

  void _showSaveConfirmDialog(VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Do you want to save your new avatar configuration?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10, width: 2),
              ),
              child: ClipOval(
                child: AvatarDisplay(
                  key: ValueKey(_currentConfig),
                  config: _currentConfig,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: const Text('Save Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() async {
    if (!_isModified) {
      Navigator.of(context).pop();
      return;
    }

    _showSaveConfirmDialog(() async {
      try {
        final profile = ref.read(userProvider).profile;
        if (profile == null) return;

        final name = profile.name;
        
        // Convert Set to Web-compatible List of Maps
        final List<Map<String, dynamic>> purchasedList = _unlockedParts.map((item) {
          final split = item.split(':');
          return {
            'part': split[0],
            'value': split.length > 1 ? split[1] : '',
          };
        }).toList();

        final purchasedItems = {
          name: purchasedList,
        };

        setState(() => _isSaving = true);
        final success = await ref.read(userProvider.notifier).updateAvatar(
          _currentConfig,
          upPoints: _localPoints,
          purchasedItems: purchasedItems,
        );

        if (success) {
          // Add a small safety delay to ensure backend has propagated changes
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Explicitly refetch the latest data before popping to guarantee sync
          await ref.read(userProvider.notifier).loadProfile();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Avatar saved successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            setState(() {
              _isModified = false;
              _initialConfig = _currentConfig;
              _isSaving = false;
            });
            context.pop(true);
          }
        } else {
          setState(() => _isSaving = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving avatar: $e')),
          );
        }
      }
    });
  }

  void _handleRemove() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Avatar', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to reset your avatar to default?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _currentConfig = UserAvatarConfig(
                  sex: 'man',
                  bgColor: '#FFFFFF',
                  faceColor: '#F9C9B6',
                  hairStyle: 'normal',
                  hairColor: '#000000',
                  eyeStyle: 'circle',
                  mouthStyle: 'smile',
                  shirtStyle: 'hoody',
                  shirtColor: '#9287FF',
                  earSize: 'big',
                  eyeBrowStyle: 'up',
                  noseStyle: 'long',
                  glassesStyle: 'none',
                  hatStyle: 'none',
                );
                _isModified = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
