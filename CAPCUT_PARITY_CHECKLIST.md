# CapCut 19.9.0 Menu Structure → KLIP Mapping

## CapCut Main Menu Tabs (observed from APK structure)

### Tab 1: Edit (Trim, Split, Arrange)
- Trim start/end (scrubber + numeric input)
- Split at cursor
- Segment reorder (drag-drop)
- Delete segment
- **KLIP Status:** ✓ Partial (needs UI polish)

### Tab 2: Text
- Add text
- Font picker (serif, sans, script, etc)
- Text size slider
- Color picker
- Text position (canvas overlay)
- Shadow/outline toggle
- Animation (entrance, exit)
- **KLIP Status:** ✓ Exists (needs more fonts + animations UI)

### Tab 3: Music/Audio
- Add music from library
- Extract audio from video
- Volume control per track
- Fade in/out
- Audio effects (EQ, reverb—native only, skip)
- **KLIP Status:** ✓ Exists (needs library UI)

### Tab 4: Effects/Filters
- Effect category grid (beauty, blur, adjustment, etc)
- Browse effect list
- Apply effect
- Intensity slider
- **KLIP Status:** ✓ Exists (14 effects, needs category UI)

### Tab 5: Transition
- Transition type grid (fade, slide, zoom, wipe, circle, dissolve, push, squeeze)
- Duration slider (0.1s - 2s)
- Preview
- **KLIP Status:** ✓ Exists (18 modes, needs duration UI fix)

### Tab 6: Sticker/Overlay
- Image overlay (position, scale, rotate, opacity)
- Text sticker
- Shape overlay
- **KLIP Status:** ✓ Exists (needs shape + animation)

### Tab 7: Adjust
- Brightness slider
- Contrast slider
- Saturation slider
- Hue slider
- Exposure
- Clarity
- **KLIP Status:** ✓ Partial (basic sliders, needs HSL curves UI)

### Tab 8: Speed Ramp
- Speed control (0.25x - 4x)
- Speed curve (linear, ease-in, ease-out)
- **KLIP Status:** ✓ Exists (needs curve UI)

---

## Critical Gaps to Fix

### 1. Transition Duration (CRITICAL)
**CapCut:** Transition duration per segment, default 0.5s, range 0.1s - 2s
**KLIP:** No duration UI
**Fix:** Add duration slider to TransitionPickerSheet

### 2. Effect Duration (CRITICAL)
**CapCut:** Effect applies to selected segment or entire video
**KLIP:** Effects apply globally
**Fix:** Add segment-based effect application

### 3. Text Animation (HIGH)
**CapCut:** Entrance (pop, slide, fade) + exit animations
**KLIP:** No entrance/exit UI
**Fix:** Add TextAnimationSheet with entrance/exit presets

### 4. Audio Library (MEDIUM)
**CapCut:** Browse 1000+ royalty-free music tracks
**KLIP:** Only manual file picker
**Fix:** Add local music folder + metadata display

### 5. Export Quality (MEDIUM)
**CapCut:** Presets (720p, 1080p, 4K) + codec selection
**KLIP:** Hardcoded to 1080p H.264
**Fix:** Add export settings dialog

### 6. Real-time Preview (HIGH)
**CapCut:** Scrub timeline → see effects live
**KLIP:** No preview during editing
**Fix:** Add video_player preview with filter overlay

### 7. Segment Effects (HIGH)
**CapCut:** Apply effect to one segment only
**KLIP:** Effects global
**Fix:** Refactor to per-segment effects

---

## UI Navigation Flow

### CapCut Flow (observed)
1. Import video → Auto-detect scenes
2. Timeline view: tap segment → Edit menu appears
3. Tap tab (Text, Music, Effects, etc) → Panel slides up
4. Adjust settings (slider, picker, etc)
5. Preview → Export

### KLIP Current Flow
1. Pick video → Timeline visible
2. Tab bar at bottom (Edit, Text, Effects, Audio, Overlay, Adjust)
3. Tap tab → Controls appear in middle row
4. Export button

**Issue:** KLIP tabs are fixed across ALL tools (not context-sensitive). CapCut changes menu per action.

---

## Action Items (Priority Order)

### P0 (Critical - ship MVP)
- [ ] Add transition duration slider (TransitionPickerSheet update)
- [ ] Fix effect duration to be per-segment, not global
- [ ] Add text entrance/exit animations (TextAnimationSheet)
- [ ] Add export quality dialog (ExportSettingsSheet)

### P1 (High - feature parity)
- [ ] Real-time video preview with active effect overlay
- [ ] Effect category grid (not flat list)
- [ ] Audio track metadata display
- [ ] Speed curve selector (linear vs ease-in/out)

### P2 (Medium - polish)
- [ ] Local music library browser
- [ ] More text fonts (Google Fonts integration)
- [ ] Segment reorder via drag-drop
- [ ] Effect preview thumbnails

### P3 (Low - CapCut extras)
- [ ] Auto scene detection
- [ ] AI features (skip—out of scope)
- [ ] Green screen
- [ ] Advanced color grading curves
