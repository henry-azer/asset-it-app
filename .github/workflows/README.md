# GitHub Actions Workflows

This directory contains automated CI/CD workflows for the Asset-It Flutter app.

## 📋 Available Workflows

### 1. Build Release APK & IPA (`build-release.yml`)

**Trigger:** Automatically runs when you create or push to a release branch

**Branch naming patterns (in order of priority):**
- `release-x.x.x` (e.g., `release-1.0.0`, `release-2.3.1`) ⭐ **Recommended**
- `release-*` (e.g., `release-hotfix`, `release-beta`)
- `release/**` (e.g., `release/v1.0.0`, `release/2024-Q1`)

**Smart Version Detection:**
- If branch name is `release-1.0.0`, version `1.0.0` is automatically extracted
- Otherwise, version is read from `pubspec.yaml`

**What it does:**

**Android Build (Ubuntu Runner):**
- ✅ Sets up Flutter environment with Java 17
- ✅ Gets dependencies
- ✅ Runs Flutter analyzer (non-blocking)
- ✅ Builds split APKs for different architectures:
  - `app-armeabi-v7a-release.apk` (ARM 32-bit)
  - `app-arm64-v8a-release.apk` (ARM 64-bit)
  - `app-x86_64-release.apk` (x86 64-bit)
- ✅ Uploads APKs as artifacts (available for 30 days)

**iOS Build (macOS Runner):**
- ✅ Sets up Flutter environment
- ✅ Gets dependencies
- ✅ Runs Flutter analyzer (non-blocking)
- ✅ Builds iOS IPA (no code sign for testing)
- ✅ Creates IPA file from Runner.app
- ✅ Uploads IPA as artifact (available for 30 days)
- ⚠️ IPA is built without code signing (suitable for testing, requires signing for device installation)

**Usage:**
```bash
# Create a release branch (recommended format)
git checkout -b release-1.0.0

# Push the branch to trigger the workflow
git push origin release-1.0.0

# Alternative formats also work:
# git checkout -b release/v1.0.0
# git checkout -b release-hotfix
```

**Download Artifacts:**
1. Go to the Actions tab in your GitHub repository
2. Click on the workflow run
3. Scroll down to "Artifacts" section
4. Download artifacts:
   - **asset-it-apk-X.X.X.zip** - Contains all Android APKs
   - **asset-it-ipa-X.X.X.zip** - Contains iOS IPA

---

### 2. Create GitHub Release (`create-release.yml`)

**Trigger:** Automatically runs when you push a version tag

**Tag format:** `v*.*.*` (e.g., `v1.0.0`, `v2.3.1-beta`)

**What it does:**

**Build Phase:**
- 🤖 **Android Job** (Ubuntu Runner):
  - Builds split APKs (armeabi-v7a, arm64-v8a, x86_64)
  - Builds universal APK
  - Renames APKs with version numbers
  - Uploads to artifacts
  
- 🍎 **iOS Job** (macOS Runner):
  - Builds iOS app without code signing
  - Creates IPA file
  - Renames IPA with version number
  - Uploads to artifacts

**Release Phase:**
- ✅ Downloads all build artifacts
- ✅ Creates a GitHub Release with:
  - Release notes template (Android & iOS sections)
  - All APK variants attached
  - iOS IPA attached
  - Installation instructions for both platforms
- ✅ Makes release publicly available

**Usage:**
```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0

# Or create an annotated tag with message
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

**Generated APK files:**
- `asset-it-v1.0.0-armeabi-v7a.apk`
- `asset-it-v1.0.0-arm64-v8a.apk`
- `asset-it-v1.0.0-x86_64.apk`
- `asset-it-v1.0.0-universal.apk`

**Customize release notes:**
After the release is created, edit it on GitHub to add:
- Feature highlights
- Bug fixes
- Breaking changes
- Known issues

---

## 🚀 Recommended Release Process

1. **Development Phase**
   ```bash
   git checkout -b feature/new-feature
   # ... develop and commit changes
   git push origin feature/new-feature
   ```

2. **Create Release Branch** (Triggers APK build)
   ```bash
   git checkout main
   git pull origin main
   git checkout -b release-1.0.0
   git push origin release-1.0.0
   ```
   - Version `1.0.0` automatically extracted from branch name
   - Workflow builds and uploads APKs
   - Test the APKs from artifacts

3. **Merge to Main** (after testing)
   ```bash
   git checkout main
   git merge release-1.0.0
   git push origin main
   ```

4. **Create Release Tag** (Creates GitHub Release)
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
   - Workflow creates public release
   - APKs attached automatically
   - Users can download from Releases page

5. **Clean Up** (optional)
   ```bash
   # Delete release branch after merging
   git branch -d release-1.0.0
   git push origin --delete release-1.0.0
   ```

---

## 🔧 Configuration

### Flutter Version

The project uses **Flutter 3.27.0** (standardized across development and CI/CD):

**Version Control:**
- `.flutter-version` file locks the Flutter version to `3.27.0`
- Both workflow files are configured to use the same version
- Ensures consistency between local development and CI/CD builds

**To update Flutter version:**
1. Update `.flutter-version` file in project root
2. Update `flutter-version` in both workflow files:
   ```yaml
   flutter-version: '3.27.0'  # Match .flutter-version
   ```
3. Test locally before pushing

**Requirements:**
- Minimum Flutter: `3.24.0` (from pubspec.lock)
- Current: `3.27.0` (includes Dart SDK 3.5.3+)
- Dart SDK: `>=3.5.3` (from pubspec.yaml)

### Update Java Version
```yaml
java-version: '17'  # Android requires Java 17+
```

### Customize APK Artifact Retention
```yaml
retention-days: 30  # Change to 7, 60, 90, etc.
```

---

## 📱 Platform Build Guide

### Android APK Architecture

| Architecture | Description | Devices |
|-------------|-------------|---------|
| **arm64-v8a** | 64-bit ARM | Modern Android phones (2019+) - **Recommended** |
| **armeabi-v7a** | 32-bit ARM | Older Android devices (2015-2019) |
| **x86_64** | 64-bit Intel/AMD | Android emulators, rare x86 devices |
| **universal** | All architectures | Works everywhere but larger file size |

### iOS IPA Signing

The workflow builds unsigned IPA files for flexibility. Here's what you can do:

**For Testing/Development:**
- Use **AltStore**, **Sideloadly**, or **Apple Configurator**
- Valid for 7 days with free Apple ID
- No jailbreak required

**For Distribution:**
- Use **Xcode** with proper provisioning profiles
- Sign with Apple Developer account
- Submit to App Store or use TestFlight

**For Jailbroken Devices:**
- Install **AppSync Unified**
- Install IPA directly without signing

---

## 🐛 Troubleshooting

### Workflow not triggering?
- Check branch name matches patterns: `release/**` or `release-*`
- Ensure workflow file is in `main` or `default` branch
- Check Actions tab is enabled in repository settings

### Build failing?
- Verify `pubspec.yaml` version format: `version: 1.0.0+1`
- Check Flutter version compatibility
- Review error logs in Actions tab

### Dart SDK version error?
If you see: `The current Dart SDK version is X.X.X` but requires higher:
- Update Flutter version in both workflow files to 3.27.0 or higher
- Flutter 3.27.0+ includes Dart SDK 3.5.3+
- Match Flutter version to your local development environment

### Gradle build error: "Unrecognized option: -Xlint:-options"?
This error occurs when Gradle properties are incompatible with Java 17:
- Remove `-Xlint:-options` from `android/gradle.properties`
- Use proper JVM args: `-Xmx4096M -XX:MaxMetaspaceSize=1024m`
- Ensure `org.gradle.jvmargs` only contains valid JVM flags (not javac flags)

### iOS build failing?
Common iOS build issues:
- **Xcode version**: Ensure macOS runner has compatible Xcode
- **CocoaPods**: Run `cd ios && pod install` if dependencies fail
- **Code signing**: The workflow uses `--no-codesign` which is intentional
- **Simulator vs Device**: Workflow builds for device (iphoneos), not simulator

### IPA installation issues?
- **"Unable to install"**: IPA needs to be signed for your device
- **Use signing tools**: AltStore, Sideloadly, or Xcode for signing
- **Free Apple ID**: Limited to 3 apps, 7-day validity
- **Paid Developer**: Use Xcode and provisioning profiles

### APK/IPA not found?
- Wait for workflow to complete (green checkmark)
- Scroll to "Artifacts" section at bottom of workflow run
- Artifacts expire after retention period (default 30 days)

---

## 📝 Notes

### Build Times
- **Android build:** ~5-10 minutes (Ubuntu runner)
- **iOS build:** ~10-15 minutes (macOS runner)
- **Both platforms:** ~15-20 minutes total (parallel execution)

### Artifact Sizes
- **Android APK:** Split APKs ~20-40MB each, Universal ~60-80MB
- **iOS IPA:** ~50-100MB (uncompressed)

### Runner Costs (GitHub Actions)
- **Ubuntu runner:** Included in free tier (2,000 minutes/month)
- **macOS runner:** 10x cost multiplier (consumes more free minutes)
- **Tip:** Consider building iOS only when needed to conserve minutes
- **Signing:** APKs are release builds but not signed (add keystore for production)
- **Permissions:** Release creation requires `contents: write` permission

---

## 🔐 Adding Keystore Signing (Optional)

To sign APKs for production release:

1. **Create GitHub Secrets:**
   - `KEYSTORE_BASE64`: Base64 encoded keystore file
   - `KEYSTORE_PASSWORD`: Keystore password
   - `KEY_ALIAS`: Key alias
   - `KEY_PASSWORD`: Key password

2. **Add to workflow before build step:**
   ```yaml
   - name: Decode Keystore
     run: |
       echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
       
   - name: Create key.properties
     run: |
       cat > android/key.properties << EOF
       storePassword=${{ secrets.KEYSTORE_PASSWORD }}
       keyPassword=${{ secrets.KEY_PASSWORD }}
       keyAlias=${{ secrets.KEY_ALIAS }}
       storeFile=keystore.jks
       EOF
   ```

3. **Update `android/app/build.gradle` to use signing config**

---

For more information, see [GitHub Actions Documentation](https://docs.github.com/en/actions).
