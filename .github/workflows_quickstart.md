# 🚀 GitHub Actions Quick Start Guide

## Prerequisites

✅ Repository pushed to GitHub  
✅ Actions enabled (Settings → Actions → General → Allow all actions)  
✅ Workflow files in `.github/workflows/` directory  

---

## 📦 Build APK (Testing/Development)

**When to use:** You want to build APKs for testing without creating a public release

### Step 1: Create Release Branch
```bash
# Create a release branch using semantic versioning (recommended)
git checkout -b release-1.0.0

# Version 1.0.0 will be automatically extracted from branch name
```

### Step 2: Push Branch
```bash
git push origin release-1.0.0
```

### Step 3: Monitor Build
1. Go to your GitHub repository
2. Click **Actions** tab
3. Watch the **"Build Release APK"** workflow run

### Step 4: Download APKs
1. Click on the completed workflow run
2. Scroll down to **Artifacts** section
3. Download `asset-it-apk-X.X.X.zip`
4. Extract and install on your device

**⏱️ Build time:** ~5-10 minutes  
**📦 Artifact retention:** 30 days

---

## 🎉 Create Public Release

**When to use:** You want to publish a version for users to download

### Step 1: Ensure Code is Ready
```bash
# Make sure you're on main branch with latest code
git checkout main
git pull origin main
```

### Step 2: Update Version in pubspec.yaml
```yaml
version: 1.0.0+1  # Update this line
```

### Step 3: Commit Version Change
```bash
git add pubspec.yaml
git commit -m "Bump version to 1.0.0"
git push origin main
```

### Step 4: Create and Push Tag
```bash
# Create tag (must match v*.*.* format)
git tag v1.0.0

# Push tag to trigger release workflow
git push origin v1.0.0
```

### Step 5: Wait for Release
1. Go to **Actions** tab
2. Watch **"Create GitHub Release"** workflow
3. Once complete, go to **Releases** tab
4. Your release is published! 🎉

### Step 6: Edit Release Notes (Optional)
1. Click on the release
2. Click **Edit**
3. Replace placeholder text with actual changes
4. Click **Update release**

---

## 🔧 Quick Commands Cheat Sheet

```bash
# Check current version in pubspec
grep "version:" pubspec.yaml

# Create release branch and push (recommended format)
git checkout -b release-1.0.0 && git push origin release-1.0.0

# Create tag and push (for public release)
git tag v1.0.0 && git push origin v1.0.0

# Delete local and remote branch
git branch -d release-1.0.0
git push origin --delete release-1.0.0

# Delete tag (if needed)
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0

# List all tags
git tag -l

# List all release branches
git branch -r | grep release

# Extract version from branch name
BRANCH=$(git branch --show-current)
echo "$BRANCH" | grep -oP 'release-\K[0-9]+\.[0-9]+\.[0-9]+'
```

---

## 📱 Testing the APK

### On Physical Device
1. Download APK from artifacts/release
2. Transfer to device via USB or cloud
3. Enable **Install from Unknown Sources**:
   - Settings → Security → Unknown Sources (Android 7 and below)
   - Settings → Apps → Special Access → Install Unknown Apps (Android 8+)
4. Open APK file to install
5. Test thoroughly!

### On Emulator
1. Start Android emulator
2. Drag and drop APK onto emulator window
3. App installs automatically

---

## 🎯 Recommended Workflow

### For Feature Development
```bash
feature/new-feature
    ↓
main (merge PR)
    ↓
release-1.0.0 (build APKs, test)
    ↓
main (merge after testing)
    ↓
v1.0.0 tag (create public release)
```

### For Hotfixes
```bash
hotfix/critical-bug
    ↓
main (merge PR)
    ↓
release-1.0.1 (quick build & test)
    ↓
main (merge)
    ↓
v1.0.1 tag (release immediately)
```

### Branch Naming Examples
- ✅ `release-1.0.0` - Major release (auto-extracts version)
- ✅ `release-1.0.1` - Patch release (auto-extracts version)  
- ✅ `release-2.3.0` - Minor release (auto-extracts version)
- ✅ `release-hotfix` - Emergency fix (reads version from pubspec.yaml)
- ✅ `release/beta-1.0.0` - Beta release (reads version from pubspec.yaml)

---

## ❗ Common Issues

### ❌ Workflow not running
**Solution:** Check workflow file is on `main` branch
```bash
git checkout main
git add .github/workflows/
git commit -m "Add workflows"
git push origin main
```

### ❌ Build fails with "version not found"
**Solution:** Ensure `pubspec.yaml` has proper version format
```yaml
version: 1.0.0+1  # Must be: major.minor.patch+build
```

### ❌ Can't find artifacts
**Solution:** 
- Wait until workflow shows green checkmark ✅
- Artifacts appear at bottom of workflow run page
- Check artifacts haven't expired (30 days)

### ❌ Release not created
**Solution:** 
- Tag must match `v*.*.*` format exactly
- Check repository permissions (needs write access)
- Verify workflow runs from Actions tab

### ❌ Gradle error: "Unrecognized option: -Xlint:-options"
**Solution:** Update `android/gradle.properties`:
```properties
# Remove or replace this line:
# org.gradle.jvmargs=-Xmx1536M -Xlint:-options

# With proper Java 17 compatible settings:
org.gradle.jvmargs=-Xmx4096M -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError
```

---

## 🔐 Optional: Add App Signing

For production releases, you should sign your APK:

1. **Generate keystore:**
   ```bash
   keytool -genkey -v -keystore asset-it-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias asset-it
   ```

2. **Encode keystore to base64:**
   ```bash
   # Windows (PowerShell)
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("asset-it-release.jks")) | Out-File keystore_base64.txt
   
   # Linux/Mac
   base64 asset-it-release.jks > keystore_base64.txt
   ```

3. **Add GitHub secrets:**
   - Go to: Settings → Secrets and variables → Actions
   - Add secrets:
     - `KEYSTORE_BASE64` (content of keystore_base64.txt)
     - `KEYSTORE_PASSWORD` (your keystore password)
     - `KEY_ALIAS` (e.g., asset-it)
     - `KEY_PASSWORD` (your key password)

4. **Update workflow** (see workflows/README.md for details)

---

## 📞 Need Help?

- 📖 Read: `.github/workflows/README.md`
- 🐛 Found a bug? Create an issue using bug report template
- ✨ Want a feature? Create an issue using feature request template
- 💬 Questions? Open a discussion on GitHub

---

## ✅ Checklist for First Release

- [ ] Version updated in `pubspec.yaml`
- [ ] All features tested locally
- [ ] Workflow files committed to `main` branch
- [ ] Created release branch and tested APKs
- [ ] APKs tested on physical device/emulator
- [ ] Created and pushed version tag
- [ ] Release published successfully
- [ ] Updated release notes with actual changes
- [ ] Announced release to users

---

**Happy Releasing! 🎊**
