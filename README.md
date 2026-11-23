# Mine-imator: Legacy Reborn Build

<p align="center">
  <img src="https://www.mineimatorforums.com/uploads/monthly_2021_08/image.png.4699187f1f02be8222a5bf5100c1738f.png" width=800/>
  <br/>
  <br/>
  <img src="https://www.mineimatorforums.com/uploads/monthly_2023_03/336815532_programview.png.9212aa1f6d1bed63411408aa5e905ce0.png" width=800/>
</p>

**Mine-imator: Legacy Reborn Build** is an enhanced, modernized edition of Mine-imator created and maintained by **OmarDotContent**.

### Key Improvements & Features
- **Fixed Transparent / Empty-Pixel Shadow Casting**: Resolved shadow casting artifacts and edge bleeding on cubes and skin second layers (such as Steve's hat and jacket) with empty/transparent pixels.
- **Enhanced Shader Pipeline**: Cross-platform shader optimizations supporting both Direct3D 11 and modern OpenGL.
- **Modern Multimedia Support**: Upgraded video decoder pipeline with modern FFmpeg (FFmpeg 6/7/8) compatibility.
- **Cross-Platform Release Automation**: Automated CI/CD builds for Windows (x64 Installer & Portable ZIP), Linux (x64 Tarball & Debian package), and macOS (.app bundle & DMG).

Original software created by David Andrei.
Website: https://www.mineimator.com

### Building
The project consists of GameMaker sources transpiled to high-performance C++ using Qt5.
For automated multiplatform builds, see the GitHub Actions workflow in `.github/workflows/release.yml`.