# Mine-imator: Legacy Reborn Build

<p align="center">
  <img src="https://www.mineimatorforums.com/uploads/monthly_2021_08/image.png.4699187f1f02be8222a5bf5100c1738f.png" width="800" alt="Mine-imator Banner"/>
  <br/><br/>
  <img src="https://www.mineimatorforums.com/uploads/monthly_2023_03/336815532_programview.png.9212aa1f6d1bed63411408aa5e905ce0.png" width="800" alt="Program View"/>
</p>

**Mine-imator: Legacy Reborn Build** is an enhanced edition of Mine-imator created and maintained by **OmarDotContent**.

This project brings the lightweight pre-2.0 render pipeline back to life, optimized to run smoothly on weaker and older hardware while integrating modern visual features from community projects.

---

## Features and Highlights

### Performance and Core Pipeline
- **Pre-2.0 Render Pipeline**: Restored and optimized to run smoothly on weaker and older hardware.
- **PBR Support on Older Pipeline**: Physically Based Rendering integrated directly into the lightweight pipeline.
- **SuperSampling (SSAA)**: High-resolution supersampling anti-aliasing for clean renders.
- **Unlocked Viewport FPS**: Unlimited viewport framerate with background FPS limiting to save system resources.
- **Auto-Save System**: Automatic project saving to prevent lost work.

### Lighting and Shadows
- **Object Light Emission**: EMIT light support on any object.
- **Volumetric Lighting**: Volumetric fog and beam features integrated from community projects.
- **Contact Shadows**: Detailed contact shadow rendering for grounded objects.
- **Cloud and Stained Glass Shadows**: Realistic shadow casting through clouds and colored stained glass.
- **Light Gobos**: Custom gobo textures for spot lights.
- **Hemisphere Sky and Ground Lighting**: Natural ambient lighting calculation from the sky and ground.
- **Rim and Backlight Highlighting**: Controllable rim lighting for character separation and dramatic scenes.

### Visual Effects and Post-Processing
- **Screen Space Reflections (SSR)**: Dynamic surface reflections.
- **Planar Mirror**: Real-time planar reflection surfaces.
- **Water Ripples and Rain Puddles**: Animated water interaction and rain puddle surfaces.
- **Sun Lens Flare**: Cinematic camera lens flares.
- **Sun God Rays**: Volumetric sun shafts through geometry and fog.
- **Weather and Lens Drops**: Dynamic weather precipitation and lens water drop effects.
- **Motion Blur, Zoom Blur, and Speed Lines**: Post-processing motion blur, radial zoom blur, and anime-style speed lines.

### Models and Media
- **Custom Model Support**: Import external 3D formats including FBX, glTF, and more.
- **Video Placer with Audio Track**: Place video files directly onto surfaces in the 3D viewport with synchronized audio playback.

### Animation and Workflow
- **Interactive Gizmos**: Viewport transform gizmos for intuitive translating, rotating, and scaling.
- **Animation Modifiers**: Procedural animation modifiers for secondary motion and automated animation passes.
- **Scale and Stretch Keyframes**: Full timeline keyframing support for squash, stretch, and non-uniform scaling.

---

## Downloads and Releases

Pre-compiled binary packages for Windows and Linux are available on the [Releases Page](https://github.com/omardotcontent/Mine-Imator-Legacy-Reborn/releases).

---

## Building from Source

The project consists of transpiled C++ sources using Qt5 and CMake.

### Prerequisites
- **CMake** (3.16+)
- **C++17 Compiler** (MSVC 2019/2022 on Windows, GCC 11+ or Clang 14+ on Linux)
- **Qt 5.15** (Widgets, Gui, Core, Network, OpenGL)
- **Libraries**: zlib, libzip, FreeType, OpenAL Soft, FFmpeg (avcodec, avformat, avutil, swscale, swresample)

### Quick Build (Linux)
```bash
sudo apt-get update
sudo apt-get install -y cmake g++ qtbase5-dev libqt5opengl5-dev zlib1g-dev libzip-dev \
    libfreetype-dev libopenal-dev libavcodec-dev libavformat-dev libavutil-dev \
    libswscale-dev libswresample-dev

cd CppProject
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j$(nproc)
```

For complete Windows build steps, see the GitHub Actions configuration in [`.github/workflows/release.yml`](.github/workflows/release.yml).

---

## Credits and Acknowledgments

- **Mine-imator Original Creator**: [David Andrei (stuffbydavid)](https://github.com/stuffbydavid) (website: https://www.mineimator.com)
- **Community and Continuation Contributors**: Nimi, mbandersmc, and the Mine-imator community.
- **Legacy Reborn Build**: Maintained and developed by **OmarDotContent**.
