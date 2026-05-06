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
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;
          final double containerH = h * 0.9;
          final double containerTop = h * 0.1;

          return Stack(
            children: [
              Positioned(
                top: containerTop,
                left: 0,
                width: w,
                height: containerH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Face (base)
                    _buildPart(AvatarPartsData.getFace(config!.faceColor ?? '#F9C9B6'), 
                      width: w, height: containerH, top: 0, left: 0),
                    
                    // Hair or Hat
                    if (config!.hatStyle != null && config!.hatStyle != 'none')
                      _buildHatPart(w, containerH)
                    else
                      _buildHairPart(w, containerH),

                    // Face details (centered area)
                    Positioned(
                      top: containerH * 0.3,
                      left: w * 0.03, // Matches frontend right: -3% shift
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
                          if (config!.glassesStyle != null && config!.glassesStyle != 'none')
                            _buildPart(_getGlassesSvg(), 
                              width: w, 
                              height: containerH * 0.22, 
                              top: containerH * 0.005, 
                              left: w * -0.03),

                          // Ears - Moved back here to match frontend parity
                          _buildPart(_getEarSvg(), 
                            width: w * 0.16, height: containerH * 0.15, top: containerH * 0.13, left: w * 0.198),
                          
                          // Nose
                          _buildPart(_getNoseSvg(), 
                            width: w * 0.1, height: containerH * 0.1, top: containerH * 0.15, left: w * 0.46),
                          
                          // Mouth
                          _buildPart(_getMouthSvg(), 
                            width: w * 0.5, height: containerH * 0.19, top: containerH * 0.23, left: w * 0.27),
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
        key: ValueKey(svg),
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
      case 'none':
        return const SizedBox.shrink();
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
        widthFactor = 0.97;
        heightFactor = 1.0;
        topFactor = 0.022; // bottom: -2.2% in frontend
        leftFactor = 0;
        break;
      case 'womanShort':
        svg = AvatarPartsData.getHairWomanShort(hairColor);
        widthFactor = 0.92;
        heightFactor = 0.75;
        topFactor = 0; // bottom: 25% in frontend
        leftFactor = -0.008;
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
    double widthFactor = 0.98;
    double heightFactor = 0.26;
    double bottomFactor = -0.02;
    double leftFactor = (1.0 - widthFactor) / 2;

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
    final style = config!.eyeStyle;
    if (style == 'oval') return AvatarPartsData.getEyesOval();
    if (style == 'smile') return AvatarPartsData.getEyesSmile();
    return AvatarPartsData.getEyesCircle();
  }

  String _getEyebrowSvg() {
    if (config!.eyeBrowStyle == 'upWoman') return AvatarPartsData.getEyebrowUpWoman();
    return AvatarPartsData.getEyebrowUp();
  }

  String _getGlassesSvg() {
    final style = config!.glassesStyle;
    if (style == 'square') return AvatarPartsData.getGlassesSquare();
    if (style == 'round') return AvatarPartsData.getGlassesRound();
    return '';
  }

  String _getMouthSvg() {
    final style = config!.mouthStyle;
    if (style == 'laugh') return AvatarPartsData.getMouthLaugh();
    if (style == 'peace') return AvatarPartsData.getMouthPeace();
    return AvatarPartsData.getMouthSmile();
  }

  String _getEarSvg() {
    final color = config!.faceColor ?? '#F9C9B6';
    if (config!.earSize == 'big') return AvatarPartsData.getEarBig(color);
    return AvatarPartsData.getEarSmall(color);
  }

  String _getNoseSvg() {
    final style = config!.noseStyle;
    if (style == 'long') return AvatarPartsData.getNoseLong();
    if (style == 'round') return AvatarPartsData.getNoseRound();
    if (style == 'short') return AvatarPartsData.getNoseShort();
    return '';
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
