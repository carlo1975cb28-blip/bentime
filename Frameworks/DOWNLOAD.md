# VLCKit Framework Setup

Bentime uses VLCKit for video playback. The framework binary is not included in the repository due to its size (~88MB). Follow these steps to download and install it.

## Download Instructions

1. Download VLCKit 3.7.3 for macOS:

   ```bash
   curl -L -o VLCKit.tar.xz "https://download.videolan.org/pub/cocoapods/prod/VLCKit-3.7.3-319ed2c0-79128878.tar.xz"
   ```

2. Extract the archive:

   ```bash
   tar xf VLCKit.tar.xz
   ```

3. Copy the xcframework into this directory:

   ```bash
   cp -R "VLCKit - binary package/VLCKit.xcframework" Frameworks/
   ```

4. Clean up:

   ```bash
   rm -rf VLCKit.tar.xz "VLCKit - binary package"
   ```

## Expected Result

After setup, the `Frameworks/` directory should contain:

```
Frameworks/
  VLCKit.xcframework/
    Info.plist
    macos-arm64_x86_64/
      VLCKit.framework/
        ...
```

## Alternative: One-liner Script

From the project root directory:

```bash
cd Frameworks && \
curl -L "https://download.videolan.org/pub/cocoapods/prod/VLCKit-3.7.3-319ed2c0-79128878.tar.xz" | tar xJ --strip-components=1 "VLCKit - binary package/VLCKit.xcframework"
```

## Verification

The Xcode project expects `VLCKit.xcframework` to be located at `$(PROJECT_DIR)/Frameworks/VLCKit.xcframework`. If the framework is missing, the build will fail with a "No such module 'VLCKit'" error.

## Version

- VLCKit 3.7.3 (Build: 319ed2c0-79128878)
- Supports: macOS arm64 + x86_64 (Universal)
- Source: https://download.videolan.org/pub/cocoapods/prod/
