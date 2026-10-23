# KLIP — Video Editor (CapCut Parity)

Flutter-based mobile video editor dengan 99% feature parity ke CapCut 19.9.0.

## Features

### ✓ Core Features (MVP)
- **Timeline Editor** — Multi-track timeline, segment trim/split/duplicate/reverse
- **Transitions** — 18 FFmpeg xfade modes (fade, slide, zoom, circle, wipe, dll)
- **Effects** — 14 filters (brightness, contrast, blur, grayscale, sepia, temperature, dll)
- **Audio** — Multi-track audio mixing, volume control, fade in/out
- **Text** — Text overlay, animations (entrance/exit timing), styling presets
- **Overlays** — Image/text overlays dengan position, scale, opacity control
- **Speed Ramp** — Per-segment speed control (0.25x - 4x)
- **Color Grading** — HSL curves (hue, saturation, lightness, shadows, midtones, highlights)
- **Keyframes** — Keyframe markers untuk animation (position, scale, opacity, rotation)
- **Real-time Preview** — Live effect preview sebelum export
- **Export** — Quality presets (720p-4K), codec selection (H.264/H.265/VP9)

### ⚙️ Edit Tab Actions
- Split segment di playhead
- Delete segment
- Duplicate segment
- Reverse segment playback
- Freeze frame (awal/akhir)
- Mute/unmute audio
- Speed adjustment
- Cover thumbnail

## Getting Started

```bash
flutter pub get
flutter run
```

Build APK:
```bash
flutter build apk --debug --split-per-abi
```

Output: `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk` (untuk Android ARM64)

## License

Private
