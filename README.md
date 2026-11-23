# Mine-imator: Legacy Reborn Build

<p align="center">
  <img src="https://www.mineimatorforums.com/uploads/monthly_2021_08/image.png.4699187f1f02be8222a5bf5100c1738f.png" width="800" alt="Mine-imator Banner"/>
  <br/><br/>
  <img src="https://www.mineimatorforums.com/uploads/monthly_2023_03/336815532_programview.png.9212aa1f6d1bed63411408aa5e905ce0.png" width="800" alt="Program View"/>
</p>

**Mine-imator: Legacy Reborn Build** is an enhanced, modernized edition of Mine-imator maintained by **OmarDotContent**.

This project is a fork based on the original open-source [Mine-imator by David Andrei (stuffbydavid)](https://github.com/stuffbydavid/Mine-imator), incorporating community updates and substantial improvements to rendering, performance, compatibility, and cross-platform distribution.

---

## 🚀 Changes & Improvements over `stuffbydavid/Mine-imator`

Compared to the original Mine-imator 2.0 release from [stuffbydavid/Mine-imator](https://github.com/stuffbydavid/Mine-imator), the **Legacy Reborn Build** introduces significant bug fixes, rendering enhancements, modern library support, and full cross-platform CI/CD automation:

### 1. Rendering & Shadow Improvements
- **Fixed Transparent / Empty-Pixel Shadow Casting**:
  - Eliminated the persistent bug where transparent or empty pixels on 3D cubes and character skin second layers (such as Steve's hat, jacket, sleeves, and pants) would cast solid rectangular shadows.
  - Resolved shadow map edge bleed on alpha-tested geometry.
- **Cross-Platform Shader Pipeline**:
  - Maintained and optimized native Direct3D 11 shaders for Windows.
  - Fully compatible OpenGL GLSL shaders for Linux and macOS.
- **Lighting & Volumetric Refinements**:
  - Emissive light casting updates for scene objects.
  - Improvements to volumetric light boundaries and region isolation.

### 2. Minecraft 1.20+ Asset & Model Support
- **Updated Block Model Loader**:
  - Added support for the `"nocull"` block texture property.
  - Fixed rotation and UV mapping bugs for inverted block models.
  - Resolved flat block element rendering errors.
  - Fixed texture scrolling features for `.mimodel` files.
- **Particle System Fixes**:
  - Fixed particle spawning delay and timing anomalies.

### 3. Modernized Engine & Toolchain
- **Upgraded Transpiler (CppGen)**:
  - Upgraded CppGen to a modern C# .NET solution (`CppGen/CppGen.sln`), replacing legacy C++ CLI generators.
  - Included transpiled C++ sources in `CppProject/Generated` for immediate, reproducible builds without requiring GameMaker or external transpiler setups.
- **Compiler Compatibility**:
  - Fixed type ambiguities and initializer list constructor conflicts (`VarArgs`) on GCC 13+ and modern Clang.
  - Clean compilation on Ubuntu 22.04 / 24.04 and macOS (Clang / Apple Silicon & Intel).
- **Modern Multimedia Decoding**:
  - Upgraded the media decoding pipeline to support modern **FFmpeg 6.x, 7.x, and 8.x** libraries, replacing deprecated FFmpeg channel layout and packet APIs.

### 4. Automated Multi-Platform CI/CD Releases
- **Automated GitHub Actions Build Matrix**:
  - **Windows (x64)**: Builds portable ZIP and Inno Setup installer (`.exe`) with bundled Qt5, FFmpeg, and OpenAL runtime dependencies.
  - **Linux (x86_64)**: Builds standalone portable archive (`.tar.gz`) and standard Debian package (`.deb`) with `.desktop` menu launcher and icons.
  - **macOS (x86_64 / Apple Silicon)**: Builds `.app` bundle, portable ZIP, and `.dmg` disk image.
- Releases are automatically compiled and published to the GitHub Releases page upon pushing version tags (`v*`).

---

## 📦 Downloads & Releases

Pre-compiled binary packages for Windows, Linux, and macOS are available on the [Releases Page](https://github.com/omardotcontent/Mine-Imator-Legacy-Reborn/releases).

---

## 🛠️ Building from Source

The project consists of GameMaker logic transpiled to high-performance C++ using Qt5.

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

For complete Windows and macOS build steps, refer to the GitHub Actions workflow in [`.github/workflows/release.yml`](.github/workflows/release.yml).

---

## 📜 Credits & Acknowledgments

- **Mine-imator Original Creator**: [David Andrei (stuffbydavid)](https://github.com/stuffbydavid) — [mineimator.com](https://www.mineimator.com)
- **Community & Continuation Contributors**: Nimi, mbandersmc, and the Mine-imator community.
- **Legacy Reborn Build**: Maintained and developed by **OmarDotContent**.
