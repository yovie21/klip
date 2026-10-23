import 'package:flutter/material.dart';

class TextStylePreset {
  const TextStylePreset({
    required this.id,
    required this.name,
    required this.color,
    required this.weight,
    this.strokeColor,
    this.strokeWidth = 0,
    this.shadow = false,
    this.background,
    this.italic = false,
    this.fontFamily = 'Roboto',
    this.fontFile = '/system/fonts/Roboto-Regular.ttf',
  });

  final String id;
  final String name;
  final Color color;
  final FontWeight weight;
  final Color? strokeColor;
  final double strokeWidth;
  final bool shadow;
  final Color? background;
  final bool italic;
  final String fontFamily;
  final String fontFile;

  static const all = <TextStylePreset>[
    TextStylePreset(
        id: 'classic',
        name: 'Classic',
        color: Colors.white,
        weight: FontWeight.w600,
        shadow: true),
    TextStylePreset(
        id: 'bold',
        name: 'Bold',
        color: Colors.white,
        weight: FontWeight.w900,
        strokeColor: Color(0xff171717),
        strokeWidth: 2),
    TextStylePreset(
        id: 'outline',
        name: 'Outline',
        color: Colors.white,
        weight: FontWeight.w800,
        strokeColor: Color(0xff111111),
        strokeWidth: 2.5),
    TextStylePreset(
        id: 'neon',
        name: 'Neon',
        color: Color(0xffff55e8),
        weight: FontWeight.w900,
        strokeColor: Color(0xff5b2bff),
        strokeWidth: 1,
        shadow: true),
    TextStylePreset(
        id: 'shadow',
        name: 'Shadow',
        color: Colors.white,
        weight: FontWeight.w800,
        shadow: true),
    TextStylePreset(
        id: 'label',
        name: 'Label',
        color: Colors.white,
        weight: FontWeight.w700,
        background: Color(0xff111111)),
    TextStylePreset(
        id: 'yellow',
        name: 'Highlight',
        color: Color(0xffffe34d),
        weight: FontWeight.w900,
        strokeColor: Color(0xff171717),
        strokeWidth: 1.5),
    TextStylePreset(
        id: 'elegant',
        name: 'Elegant',
        color: Color(0xffffd9b0),
        weight: FontWeight.w400,
        italic: true,
        shadow: true,
        fontFamily: 'serif',
        fontFile: '/system/fonts/NotoSerif-Regular.ttf'),
    TextStylePreset(
        id: 'mint',
        name: 'Mint',
        color: Color(0xff64f2c2),
        weight: FontWeight.w800,
        strokeColor: Color(0xff07392f),
        strokeWidth: 1.5),
    TextStylePreset(
        id: 'serif',
        name: 'Serif',
        color: Colors.white,
        weight: FontWeight.w600,
        fontFamily: 'serif',
        fontFile: '/system/fonts/NotoSerif-Regular.ttf'),
    TextStylePreset(
        id: 'mono',
        name: 'Mono',
        color: Color(0xffd8f3dc),
        weight: FontWeight.w600,
        fontFamily: 'monospace',
        fontFile: '/system/fonts/DroidSansMono.ttf'),
    TextStylePreset(
        id: 'hand',
        name: 'Handwritten',
        color: Color(0xfffff0a6),
        weight: FontWeight.w500,
        italic: true,
        fontFamily: 'cursive',
        fontFile: '/system/fonts/ComingSoon.ttf'),
    TextStylePreset(
        id: 'script',
        name: 'Script',
        color: Color(0xffffc6e8),
        weight: FontWeight.w500,
        fontFamily: 'cursive',
        fontFile: '/system/fonts/DancingScript-Regular.ttf'),
    TextStylePreset(
        id: 'condensed',
        name: 'Condensed',
        color: Colors.white,
        weight: FontWeight.w900,
        fontFamily: 'sans-serif-condensed',
        fontFile: '/system/fonts/RobotoStatic-Regular.ttf'),
    TextStylePreset(
        id: 'comic',
        name: 'Comic',
        color: Color(0xffffd166),
        weight: FontWeight.w700,
        fontFamily: 'casual',
        fontFile: '/system/fonts/ComingSoon.ttf'),
    TextStylePreset(
        id: 'serifBold',
        name: 'Serif Bold',
        color: Color(0xffffe0b2),
        weight: FontWeight.w700,
        fontFamily: 'serif',
        fontFile: '/system/fonts/NotoSerif-Bold.ttf'),
    TextStylePreset(
        id: 'serifItalic',
        name: 'Serif Italic',
        color: Color(0xffd7c7ff),
        weight: FontWeight.w400,
        italic: true,
        fontFamily: 'serif',
        fontFile: '/system/fonts/NotoSerif-Italic.ttf'),
    TextStylePreset(
        id: 'typewriter',
        name: 'Typewriter',
        color: Color(0xffc5e1a5),
        weight: FontWeight.w500,
        fontFamily: 'monospace',
        fontFile: '/system/fonts/CutiveMono.ttf'),
    TextStylePreset(
        id: 'retro',
        name: 'Retro',
        color: Color(0xffff6b6b),
        weight: FontWeight.w900,
        strokeColor: Color(0xfffff3b0),
        strokeWidth: 1,
        shadow: true),
    TextStylePreset(
        id: 'ice',
        name: 'Ice',
        color: Color(0xffa8e6ff),
        weight: FontWeight.w900,
        strokeColor: Color(0xff174a7e),
        strokeWidth: 1.5,
        shadow: true),
    TextStylePreset(
        id: 'boxed',
        name: 'Boxed',
        color: Color(0xff111111),
        weight: FontWeight.w900,
        background: Color(0xffffe34d)),
  ];

  static TextStylePreset byId(String id) => all.firstWhere(
        (preset) => preset.id == id,
        orElse: () => all.first,
      );
}
