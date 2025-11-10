# 🌿 Branch Naming Convention

## Release Branches

Release branches follow a specific naming pattern for automated version extraction.

### ✅ Recommended Format: `release-x.x.x`

**Pattern:** `release-MAJOR.MINOR.PATCH`

**Examples:**
- `release-1.0.0` → Version: `1.0.0`
- `release-1.0.1` → Version: `1.0.1`
- `release-2.3.0` → Version: `2.3.0`
- `release-10.5.23` → Version: `10.5.23`

**Benefits:**
- ✅ Version automatically extracted from branch name
- ✅ No need to update `pubspec.yaml` before branch creation
- ✅ Clear semantic versioning
- ✅ Easy to identify release version at a glance
- ✅ Works perfectly with GitHub Actions workflows

**Usage:**
```bash
# Create release branch
git checkout -b release-1.0.0

# Push to trigger build
git push origin release-1.0.0

# Version 1.0.0 is automatically detected and used
```

---

### Alternative Formats (Fallback to pubspec.yaml)

If your branch name doesn't match the `release-x.x.x` pattern, the workflow will read the version from `pubspec.yaml`.

**Other valid formats:**
- `release-hotfix` → Reads version from `pubspec.yaml`
- `release-beta` → Reads version from `pubspec.yaml`
- `release/v1.0.0` → Reads version from `pubspec.yaml`
- `release/2024-Q1` → Reads version from `pubspec.yaml`

**Usage:**
```bash
# Create branch with custom name
git checkout -b release-hotfix

# Update pubspec.yaml first
# version: 1.0.1+2

# Push to trigger build
git push origin release-hotfix

# Version read from pubspec.yaml
```

---

## Semantic Versioning Guide

### Version Format: `MAJOR.MINOR.PATCH`

**MAJOR** (`x.0.0`)
- Breaking changes
- Incompatible API changes
- Major feature overhauls
- Example: `1.0.0` → `2.0.0`

**MINOR** (`0.x.0`)
- New features
- Backward-compatible changes
- New functionality added
- Example: `1.0.0` → `1.1.0`

**PATCH** (`0.0.x`)
- Bug fixes
- Security patches
- Minor improvements
- Example: `1.0.0` → `1.0.1`

---

## Build Number (pubspec.yaml only)

In `pubspec.yaml`, you can also specify a build number:

```yaml
version: 1.0.0+5
#         ↑     ↑
#      Version  Build
```

**Build number:**
- Increments with each build
- Not visible to users
- Useful for tracking internal builds
- Used by app stores for version comparison

**Note:** Build number is NOT extracted from branch name, only from `pubspec.yaml`.

---

## Complete Release Example

### Scenario: Releasing version 1.0.1

**Step 1: Create Release Branch**
```bash
git checkout main
git pull origin main
git checkout -b release-1.0.1
```

**Step 2: Update Build Number (optional)**
```yaml
# pubspec.yaml
version: 1.0.1+6  # Increment build number
```

**Step 3: Commit and Push**
```bash
git add pubspec.yaml
git commit -m "Bump version to 1.0.1"
git push origin release-1.0.1
```

**Step 4: GitHub Actions Workflow**
- Detects branch name: `release-1.0.1`
- Extracts version: `1.0.1`
- Builds APKs with version `1.0.1`
- Uploads artifacts: `asset-it-apk-1.0.1.zip`

**Step 5: Test APKs**
- Download from Actions artifacts
- Test on devices

**Step 6: Merge to Main**
```bash
git checkout main
git merge release-1.0.1
git push origin main
```

**Step 7: Create Release Tag**
```bash
git tag v1.0.1
git push origin v1.0.1
```

**Step 8: GitHub Release Created**
- APK files: `asset-it-v1.0.1-arm64-v8a.apk`, etc.
- Release notes
- Public download available

---

## Branch Lifecycle

### Typical Flow

```
1. Create: release-1.0.0
2. Build: APKs generated automatically
3. Test: Download and test artifacts
4. Merge: Merge to main
5. Tag: Create v1.0.0 tag
6. Release: Public release created
7. Clean: Delete release-1.0.0 branch
```

### Cleanup

After merging and tagging, delete the release branch:

```bash
# Delete local branch
git branch -d release-1.0.0

# Delete remote branch
git push origin --delete release-1.0.0
```

---

## Version Extraction Logic

The GitHub Actions workflow uses this logic:

```bash
BRANCH_NAME="release-1.0.0"

if [[ $BRANCH_NAME =~ ^release-([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  # Branch matches release-x.x.x pattern
  VERSION="${BASH_REMATCH[1]}"  # Extract: 1.0.0
  echo "✅ Version from branch: $VERSION"
else
  # Fallback to pubspec.yaml
  VERSION=$(grep "version:" pubspec.yaml | awk '{print $2}')
  echo "📄 Version from pubspec: $VERSION"
fi
```

---

## Quick Reference

| Branch Name | Version Source | Example Version |
|------------|----------------|-----------------|
| `release-1.0.0` | Branch name | `1.0.0` |
| `release-2.3.5` | Branch name | `2.3.5` |
| `release-hotfix` | pubspec.yaml | `1.0.1` (from file) |
| `release/v1.0.0` | pubspec.yaml | `1.0.0` (from file) |
| `release-beta` | pubspec.yaml | `1.0.0-beta` (from file) |

---

## Best Practices

✅ **DO:**
- Use `release-x.x.x` format for standard releases
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Update pubspec.yaml build number before pushing
- Test APKs before creating tags
- Delete release branches after merging
- Document changes in release notes

❌ **DON'T:**
- Use inconsistent versioning schemes
- Skip testing release builds
- Create tags without testing
- Forget to merge release branch to main
- Leave old release branches undeleted
- Use non-numeric version numbers in branch name

---

## Examples by Use Case

### Regular Release
```bash
git checkout -b release-1.2.0
git push origin release-1.2.0
# Version: 1.2.0 (from branch name)
```

### Hotfix Release
```bash
git checkout -b release-1.1.1
git push origin release-1.1.1
# Version: 1.1.1 (from branch name)
```

### Beta Release
```bash
git checkout -b release-beta
# Update pubspec.yaml: version: 2.0.0-beta+1
git push origin release-beta
# Version: 2.0.0-beta+1 (from pubspec.yaml)
```

### Emergency Hotfix
```bash
git checkout -b release-hotfix
# Update pubspec.yaml: version: 1.0.2+1
git push origin release-hotfix
# Version: 1.0.2+1 (from pubspec.yaml)
```

---

For more information, see:
- [Semantic Versioning 2.0.0](https://semver.org/)
- [GitHub Actions Workflows](./workflows/README.md)
- [Quick Start Guide](./workflows_quickstart)
