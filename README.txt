================================================================================
       TRIPLE R AUDIO - ADVANCED TECHNICAL ARCHITECTURE & REFERENCE MANUAL
                          [FOR AUDIO ENGINEERS & NERDS]
================================================================================

1. SYSTEM SIGNAL FLOW & ARCHITECTURE
--------------------------------------------------------------------------------
Game Process (x64)
  | [Native 7.1 / 16-Channel Audio Bed: 48,000 Hz, 24-bit PCM]
  v
Windows Audio Endpoint Router (WASAPI Shared / Exclusive)
  | Endpoint: "Hi-Fi Cable Input (VB-Audio Hi-Fi Cable)"
  v
VB-Audio Hi-Fi Virtual Cable Driver (vbaudio_hificable64_win10.sys)
  | Bit-exact 24-bit / 48,000 Hz multi-channel digital pipe
  v
Equalizer APO Audio Processing Object Engine (EqualizerAPO.dll)
  | Ring-0 audio intercept before Windows mixer
  | Reads C:\Program Files\EqualizerAPO\config\config.txt live via file-watch interrupt
  |
  +--> Stage 1: Spatial Separation (ATK Spatial Engine Bravo VST / HeSuVi)
  |     - 7.1/16-channel down-mix via head-related impulse response (HRIR) convolution
  |     - EAC_Default.wav / EAC_Refined.wav (IEC 60318-4 calibrated)
  |     - Mid/Side stereo spatial enhancement & center-channel gun ducking
  |
  +--> Stage 2: Headphone Parametric Correction (IIR Biquad Filters)
  |     - Model-specific frequency response neutralization
  |     - High-Q notch filtering at transducer mechanical resonances
  |     - Pinna gain elevation (1,000 Hz - 3,200 Hz) for footstep audibility
  |
  +--> Stage 3: Loudness Equalization (WMALFXGFXDSP.dll) & Preamp Gain
        - Registry-level Microsoft Loudness Equalization APO
        - Release Time: Configurable from 2 (Instant / Short) to 7 (Slow / Long)
        - Master Preamp gain scaling (boost.txt)
  v
Elgato Wave Link 3.0 / Hardware Output Endpoint (DAC / USB / Wireless Dongle)
  v
Physical Transducer (KZ ZAR / Pulse Elite / Astro A50 / Logitech Pro X)


2. ELGATO WAVE LINK 3.0 ROUTING & TUNE ON/OFF SWITCHING
--------------------------------------------------------------------------------
How to route Triple R Audio with Elgato Wave Link 3.0 so you can toggle your
game tune ON and OFF or switch to Normal Audio anytime:

  [Step A: Windows Sound Control Panel (mmsys.cpl)]
  - Your virtual cable appears as "Hi-Fi Cable Input" (or renamed to "Art Tune").
  - Set "Hi-Fi Cable Input" to 7.1 Surround and 24-bit, 48000 Hz.

  [Step B: Elgato Wave Link 3.0 App Setup]
  - In Wave Link 3.0, add an input channel and select "Hi-Fi Cable Output"
    (this captures the processed audio coming out of Equalizer APO).
  - Keep a second channel in Wave Link 3.0 for "Game (Elgato Virtual Audio)" or
    "System / Normal Audio" for un-tuned raw game audio.
  - Set your Wave Link "Monitor Mix" output to your physical headphones/DAC
    (e.g., Elgato Wave:XLR headphone jack, Astro Base Station, or USB DAC).

  [Step C: Instant Tune ON / OFF Switching]
  - TUNE ON (Competitive Mode): Route your game or Windows Default Output to
    "Hi-Fi Cable Input". Audio flows through Triple R Audio -> Equalizer APO ->
    Wave Link Monitor Mix -> Your Headphones.
  - TUNE OFF (Normal Audio Mode): In Triple R Audio, click the "Bypass / Normal
    Audio" toggle button (or route the game directly to Wave Link "System" or
    your headphones). This bypasses the aggressive footstep compression when you
    just want to listen to music, watch YouTube, or play casual story games.


3. LOUDNESS EQUALIZATION (LEQ) & RELEASE TIME REGISTRY ARCHITECTURE
--------------------------------------------------------------------------------
Windows includes a native multiband compressor/limiter inside `WMALFXGFXDSP.dll`
(Microsoft Audio Home Theater Effects). Many USB and virtual audio drivers hide
the "Enhancements" tab by default.

Triple R Audio injects the exact COM CLSID property keys directly into the
Windows MMDevices Audio Render registry hive:
  Path: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render\{GUID}\FxProperties

  Key 1 (PreMixEffectClsid):
    "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},1" = "{62dc1a93-ae24-464c-a43e-452f824c4250}"
  Key 2 (PostMixEffectClsid):
    "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},2" = "{637c490d-eee3-4c0a-973f-371958802da2}"
  Key 3 (UserInterfaceClsid - Unlocks the Enhancements Tab in mmsys.cpl):
    "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},3" = "{5860E1C5-F95C-4a7a-8EC8-8AEF24F379A1}"
  Key 4 (Loudness Equalization Enable Flag):
    "{fc52a749-4be9-4510-896e-966ba6525980},3" = hex:0b,00,00,00,01,00,00,00,ff,ff,00,00 (Enabled)
                                                  hex:0b,00,00,00,01,00,00,00,00,00,00,00 (Disabled)
  Key 5 (Release Time Slider Value - Range 02 to 07):
    "{9c00eeed-edce-4cd8-ae08-cb05e8ef57a0},3" = hex:03,00,00,00,01,00,00,00,XX,00,00,00
    Where XX is:
      02 = Shortest Release Time (Instant recovery after gunshots; maximum footsteps)
      03 = Very Fast Release Time
      04 = Default Medium-Fast Release Time
      07 = Longest Release Time (Most natural dynamic feel, slowest pumping)


4. COMPLETE GUIDE: HOW TO USE SQUIGLINK FOR CUSTOM AUTO-EQ
--------------------------------------------------------------------------------
What is Squiglink?
  Squiglink is a free network of IEC 60318-4 (711 coupler) and B&K 5128 acoustic
  measurement databases run by audio reviewers (GadgetryTech, Crinacle, Super*
  Review, HBB, TimmyV). It measures the exact frequency response of thousands of
  IEMs and headsets from 20 Hz to 20,000 Hz.

How to Generate & Import a Custom Game EQ from Squiglink:
  1. In Triple R Audio, go to the "Squiglink Auto-EQ" tab.
  2. Type your IEM or headphone name (e.g., "KZ ZAR") and click "Open in Squiglink",
     or use the built-in "Auto-EQ & Add Model" button for instant background generation.
  3. If using the Squiglink website manually:
     - Left Sidebar -> "Models": Search and click your headphone/IEM so its curve
       appears on the graph.
     - Top Tab -> Click "Equalizer".
     - If you have a custom game target file (like `BO7_Target_V3.txt` in your
       library folder), click "Upload Target" to load it.
     - Set the Frequency Range to `20 Hz - 10000 Hz` (avoid auto-EQing above 10 kHz
       due to coupler resonance variance).
     - Click "AutoEQ".
     - Click "Export Parametric EQ (for Equalizer APO)". This downloads a `.txt`
       file containing `Preamp:` and `Filter 1..10: ON PK Fc ...` lines.
  4. In Triple R Audio, click "Import .txt EQ" and select that downloaded file.
     It is immediately added to your collection and ready to apply live!


5. PARAMETRIC BIQUAD FILTER MATHEMATICS & HARDWARE PROFILES
--------------------------------------------------------------------------------
All Equalizer APO filters generated by Triple R Audio use 2nd-order Infinite 
Impulse Response (IIR) biquad filters:

  H(s) = (s^2 + (A/Q)*s + 1) / (s^2 + (1/(A*Q))*s + 1)

Hardware-Specific Calibration Summary:
  * KZ ZAR (1DD + 7BA - Primary Reference):
    - Sub-bass control (-2.0 dB @ 65 Hz, Q 1.30)
    - Footstep gravel boost (+3.8 dB @ 1250 Hz, Q 1.90)
    - Pinna directional lift (+2.5 dB @ 2700 Hz, Q 1.80)
    - BA treble fatigue clamp (-4.0 dB @ 5000 Hz, Q 2.80 & -3.2 dB @ 8000 Hz)
  * PlayStation Pulse Elite (PS3/PC - BassImpact):
    - BassImpact rumble clamp (-4.5 dB @ 85 Hz), Footstep lift (+4.6 dB @ 1250 Hz)
  * Tangzu Fudu Verse 1:
    - Warm/dark tilt correction (+4.5 dB @ 1400 Hz, +3.2 dB @ 2900 Hz)
  * QKZ AK6:
    - Aggressive 90 Hz mud cut (-5.8 dB) + 1350 Hz footstep recovery (+5.0 dB)
  * Astro A50 Gen 4 / Astro A10 / Logitech Pro X / G935 / Razer BlackShark V2 X:
    - Boxy mid-bass resonance removal (95-120 Hz) + pinna directional boost.
================================================================================
