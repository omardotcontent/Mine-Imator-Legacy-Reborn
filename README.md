# Mine-imator: Legacy Reborn Build

<p align="center">
  <img src="https://www.mineimatorforums.com/uploads/monthly_2021_08/image.png.4699187f1f02be8222a5bf5100c1738f.png" width="800" alt="Mine-imator Banner"/>
  <br/><br/>
  <img src="https://www.mineimatorforums.com/uploads/monthly_2023_03/336815532_programview.png.9212aa1f6d1bed63411408aa5e905ce0.png" width="800" alt="Program View"/>
</p>

**Mine-imator: Legacy Reborn Build** is an enhanced edition of Mine-imator created and maintained by **OmarDotContent**.

This project takes the classic pre-2.0 render pipeline and maxes it out with modern features—making it fully usable and optimized for weaker and older hardware while delivering advanced visual tools.

---

## ⚡ Highlights & Features

- Using the pre 2.0 render pipeline to make it work again on weaker hardware!
- Added new features that are on the other modded mine-imator projects to this one like (Volumetric features)
- Custom model support, fbx, gtlf, etc
- EMIT light support to any object!
- Animation modifiers
- gizmos
- Video placer + audio track added feature
- planar mirror
- light gobos for spot lights
- Screen space reflectiosn
- Water ripples and rain puddles
- contact shadows
- cloud and stained glass shadows
- cloud shadows
- sun lens flare
- sun god rays
- weather and lens drops
- motion / zoom blur and speed lines
- PBR support on older pipeline 
- SUperSampling (SSAA)
- hemisphere sky, ground lightning
- rim / backlight highlight
- scale/scretch keyframes
- unlimited view port fps unlocked with background fps limit
- auto-save feature (if it wasn't there before)

---

## 📦 Downloads & Releases

Pre-compiled binary packages for Windows, Linux, and macOS are available on the [Releases Page](https://github.com/omardotcontent/Mine-Imator-Legacy-Reborn/releases).

---

## 🛠️ Building from Source

The project consists of transpiled C++ sources using Qt5 and CMake.

### Prerequisites
- **CMake** (3.16+)
- **C++17 Compiler** (MSVC 2019/2022 on Windows, GCC 11+ or Clang 14+ on Linux/macOS)
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

For complete Windows and macOS build steps, see the GitHub Actions configuration in [`.github/workflows/release.yml`](.github/workflows/release.yml).

---

## 📜 Credits & Acknowledgments

- **Mine-imator Original Creator**: [David Andrei (stuffbydavid)](https://github.com/stuffbydavid) — [mineimator.com](https://www.mineimator.com)
- **Community & Continuation Contributors**: Nimi, mbandersmc, and the Mine-imator community.
- **Legacy Reborn Build**: Maintained and developed by **OmarDotContent**.
