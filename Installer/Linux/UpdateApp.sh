#!/bin/bash
set -euo pipefail

# Copy executable
app=Mine-imator-Legacy-Reborn
target="Mine-imator/usr/local/bin/$app"
mkdir -p "$target"
cp Build/Mine-imator "$target/"

# Set version
sed -i "s/Version: .*/Version: $1/" Mine-imator/DEBIAN/control

# Create Debian package
dpkg-deb --root-owner-group --build Mine-imator "$app.deb"

# Create archive
tar czf "$app.tar.gz" -C Mine-imator/usr/local/bin "$app"
