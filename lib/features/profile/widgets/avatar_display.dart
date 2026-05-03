import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../data/models/user_avatar_config.dart';
import '../data/avatar_parts_data.dart';

class AvatarDisplay extends StatelessWidget {
  final UserAvatarConfig? config;
  final double size;
  final String shape; // 'circle', 'rounded', 'square'

  const AvatarDisplay({
    super.key,
    this.config,
    this.size = 100,
    this.shape = 'circle',
  });

  @override
  Widget build(BuildContext context) {
    if (config == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: shape == 'rounded' ? BorderRadius.circular(size * 0.1) : null,
        ),
        child: Icon(Icons.person, size: size * 0.6, color: Colors.grey[600]),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _hexToColor(config!.bgColor ?? '#FFFFFF'),
        shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: shape == 'rounded' ? BorderRadius.circular(size * 0.1) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth * 0.9;
          final double h = constraints.maxHeight;
          final double containerH = h * 0.9;
          final double containerTop = h * 0.1;

          return Stack(
            children: [
              Positioned(
                top: containerTop,
                left: (constraints.maxWidth - w) / 2,
                width: w,
                height: containerH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Face (base)
                    _buildPart(AvatarPartsData.getFace(config!.faceColor ?? '#F9C9B6'), 
                      width: w, height: containerH, top: 0, left: 0),
                    
                    // Hair or Hat
                    if (config!.hatStyle != 'none')
                      _buildHatPart(w, containerH)
                    else
                      _buildHairPart(w, containerH),

                    // Face details (centered area)
                    Positioned(
                      top: containerH * 0.3,
                      left: 0,
                      width: w,
                      height: containerH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Eyebrows
                          _buildPart(_getEyebrowSvg(), 
                            width: w * 0.8, height: containerH * 0.13, top: 0, left: w * 0.1),
                          
                          // Eyes
                          _buildPart(_getEyesSvg(), 
                            width: w, height: containerH * 0.12, top: containerH * 0.07, left: 0),
                          
                          // Glasses
                          if (config!.glassesStyle != 'none')
                            _buildPart(_getGlassesSvg(), 
                              width: w * 1.06, height: containerH * 0.22, top: containerH * 0.03, left: -w * 0.035),

                          // Ears
                          _buildPart(_getEarSvg(), 
                            width: w * 0.16, height: containerH * 0.15, top: containerH * 0.13, left: w * 0.198),
                          
                          // Nose
                          _buildPart(_getNoseSvg(), 
                            width: w * 0.1, height: containerH * 0.1, top: containerH * 0.15, left: w * 0.46),
                          
                          // Mouth
                          _buildPart(_getMouthSvg(), 
                            width: w * 0.5, height: containerH * 0.17, top: containerH * 0.23, left: w * 0.27),
                        ],
                      ),
                    ),

                    // Shirt (bottom)
                    _buildShirtPart(w, containerH),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPart(String svg, {double? width, double? height, double? top, double? left, double? bottom, double? right}) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      width: width,
      height: height,
      child: SvgPicture.string(
        svg,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildHairPart(double w, double h) {
    String svg;
    double widthFactor = 0.94;
    double heightFactor = 0.81;
    double topFactor = 0;
    double leftFactor = -0.005;

    String hairColor = config!.hairColor ?? '#000000';
    
    // Website parity: certain styles default to black if randomization is off
    if ((config!.hairStyle == 'thick' || config!.hairStyle == 'mohawk') && 
        (config!.hairColorRandom != true)) {
      hairColor = '#000000';
    }

    switch (config!.hairStyle) {
      case 'normal':
        svg = AvatarPartsData.getHairNormal(hairColor);
        widthFactor = 0.94;
        heightFactor = 0.81;
        topFactor = -0.01;
        leftFactor = -0.005;
        break;
      case 'thick':
        svg = AvatarPartsData.getHairThick(hairColor);
        widthFactor = 0.935;
        heightFactor = 0.64;
        topFactor = -0.042;
        leftFactor = 0;
        break;
      case 'mohawk':
        svg = AvatarPartsData.getHairMohawk(hairColor);
        widthFactor = 0.976;
        heightFactor = 0.635;
        topFactor = -0.043;
        leftFactor = -0.018;
        break;
      case 'womanLong':
        svg = AvatarPartsData.getHairWomanLong(hairColor);
        widthFactor = 1.25;
        heightFactor = 1.0;
        topFactor = -0.05;
        leftFactor = -0.12;
        break;
      case 'womanShort':
        svg = AvatarPartsData.getHairWomanShort(hairColor);
        widthFactor = 1.1;
        heightFactor = 0.85;
        topFactor = 0;
        leftFactor = -0.05;
        break;
      default:
        svg = AvatarPartsData.getHairNormal(hairColor);
        widthFactor = 0.94;
        heightFactor = 0.81;
        topFactor = -0.01;
        leftFactor = -0.005;
    }

    return _buildPart(svg, 
      width: w * widthFactor, 
      height: h * heightFactor, 
      top: h * topFactor, 
      left: w * leftFactor);
  }

  Widget _buildHatPart(double w, double h) {
    String svg;
    double widthFactor = 0.64;
    double heightFactor = 0.84;
    double bottomFactor = 0.33;
    double leftFactor = 0.158;

    switch (config!.hatStyle) {
      case 'beanie':
        svg = AvatarPartsData.getHatBeanie(config!.hatColor ?? '#000000');
        widthFactor = 0.49;
        heightFactor = 0.85;
        bottomFactor = 0.34;
        leftFactor = 0.22;
        break;
      case 'turban':
        svg = AvatarPartsData.getHatTurban(config!.hatColor ?? '#000000');
        widthFactor = 0.64;
        heightFactor = 0.84;
        bottomFactor = 0.33;
        leftFactor = 0.158;
        break;
      default:
        return const SizedBox.shrink();
    }

    return _buildPart(svg, 
      width: w * widthFactor, 
      height: h * heightFactor, 
      bottom: h * bottomFactor, 
      left: w * leftFactor);
  }

  Widget _buildShirtPart(double w, double h) {
    final color = config!.shirtColor ?? '#2196F3';
    String svg;
    double widthFactor = 1.0;
    double heightFactor = 0.26;
    double bottomFactor = -0.025;
    double leftFactor = 0;

    switch (config!.shirtStyle) {
      case 'short':
        svg = AvatarPartsData.getShirtShort(color);
        break;
      case 'polo':
        svg = AvatarPartsData.getShirtPolo(color, color);
        break;
      default:
        svg = AvatarPartsData.getShirtHoody(color);
        break;
    }

    return _buildPart(svg, 
      width: w * widthFactor, 
      height: h * heightFactor, 
      bottom: h * bottomFactor, 
      left: w * leftFactor);
  }

  String _getEyesSvg() {
    switch (config!.eyeStyle) {
      case 'oval': return AvatarPartsData.getEyesOval();
      case 'smile': return AvatarPartsData.getEyesSmile();
      default: return AvatarPartsData.getEyesCircle();
    }
  }

  String _getEyebrowSvg() {
    switch (config!.eyeBrowStyle) {
      case 'upWoman': return AvatarPartsData.getEyebrowUpWoman();
      default: return AvatarPartsData.getEyebrowUp();
    }
  }

  String _getGlassesSvg() {
    switch (config!.glassesStyle) {
      case 'square': return AvatarPartsData.getGlassesSquare();
      default: return AvatarPartsData.getGlassesRound();
    }
  }

  String _getMouthSvg() {
    switch (config!.mouthStyle) {
      case 'laugh': return AvatarPartsData.getMouthLaugh();
      case 'peace': return AvatarPartsData.getMouthPeace();
      default: return AvatarPartsData.getMouthSmile();
    }
  }

  String _getEarSvg() {
    final color = config!.faceColor ?? '#F9C9B6';
    if (config!.earSize == 'big') return AvatarPartsData.getEarBig(color);
    return AvatarPartsData.getEarSmall(color);
  }

  String _getNoseSvg() {
    switch (config!.noseStyle) {
      case 'long': return AvatarPartsData.getNoseLong();
      case 'round': return AvatarPartsData.getNoseRound();
      default: return AvatarPartsData.getNoseShort();
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
