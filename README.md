# Mine-imator: Legacy Reborn Build

<p align="center">
  <img src="https://www.mineimatorforums.com/uploads/monthly_2021_08/image.png.4699187f1f02be8222a5bf5100c1738f.png" width="800" alt="Mine-imator Banner"/>
  <br/><br/>
  <img src="https://www.mineimatorforums.com/uploads/monthly_2023_03/336815532_programview.png.9212aa1f6d1bed63411408aa5e905ce0.png" width="800" alt="Program View"/>
</p>

**Mine-imator: Legacy Reborn Build** is an enhanced edition of Mine-imator created and maintained by **OmarDotContent**.

This project takes the classic, beloved **Mine-imator 1.2.9 engine** architecture and maxes it out with modern features—specifically optimized for **fast render times** and **ultra-lightweight performance** on any computer, including low-end and older PCs.

---

## ⚡ Highlights & Features

This is the **initial v1.0.0 release** of the Legacy Reborn Build, bringing the speed of the classic 1.2.9 era together with modern capabilities:

### 🚀 Lightweight & Maxed-Out Engine
- **Classic 1.2.9 Engine Foundation**: Built upon the responsive, lightweight legacy engine core to ensure minimal CPU and RAM overhead.
- **Fast Render Times**: Highly efficient render and viewport pipeline designed to export animations quickly without requiring a high-end graphics card or heavy workstation specs.
- **Smooth Performance on Any PC**: Tuned to run fluidly on low-end laptops, older desktop computers, and modern systems alike.

### 🎨 Modern Asset Importing & Models
- **Advanced Model Support**: Full compatibility with `.mimodel` models, custom orientations, and element properties.
- **Texture Scrolling & Custom UVs**: Support for texture scrolling on models and advanced texture mapping.
- **Modern Minecraft Assets**: Import and animate using modern textures, blocks, and items while keeping the interface and workflow snappy.

### 🎬 Fast Video Exporting
- **Upgraded Multimedia Pipeline**: Integrated modern video encoding and decoding for rapid, high-quality video, image sequence, and animation exports.
- **Lightweight Export Footprint**: Export your scenes smoothly without software hangs or extreme system strain.

### 🌐 Cross-Platform Distribution
- **Automated CI/CD Builds**: Native executables and packages for:
  - **Windows (x64)**: Portable ZIP and full Installer (`.exe`).
  - **Linux (x86_64)**: Portable Tarball (`.tar.gz`) and standard Debian package (`.deb`) with desktop shortcut.
  - **macOS (x86_64 / Apple Silicon)**: Portable Application bundle (`.zip`) and disk image (`.dmg`).

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
