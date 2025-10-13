# Development Scripts

This directory contains automated scripts for building and deploying PySPHORB.

## Scripts Overview

| Script | Purpose | Safety Level |
|--------|---------|--------------|
| `setup_dev_env.sh` | Setup development environments | ✅ Safe |
| `build_wheels.sh` | Build wheels for all Python versions | ✅ Safe |
| `upload_testpypi.sh` | Upload to TestPyPI | ⚠️ Test environment |
| `upload_pypi.sh` | Upload to Production PyPI | 🔴 Irreversible |

## Quick Start

```bash
# 1. Setup development environment (first time only)
./scripts/setup_dev_env.sh

# 2. Build wheels
./scripts/build_wheels.sh

# 3. Test on TestPyPI
./scripts/upload_testpypi.sh

# 4. Deploy to PyPI (after testing)
./scripts/upload_pypi.sh
```

## Detailed Usage

### 1. Setup Development Environment

**Script:** `setup_dev_env.sh`

Sets up virtual environments for Python 3.11, 3.12, 3.13, 3.14.

```bash
./scripts/setup_dev_env.sh
```

**What it does:**
- Installs Python versions using `uv`
- Creates virtual environments (`.venv-py311`, `.venv-py312`, etc.)
- Installs build dependencies
- Creates main development environment (`.venv`)

**Requirements:**
- `uv` must be installed

**Output:**
```
.venv           # Main development environment (Python 3.12)
.venv-py311     # Python 3.11
.venv-py312     # Python 3.12
.venv-py313     # Python 3.13
.venv-py314     # Python 3.14
```

---

### 2. Build Wheels

**Script:** `build_wheels.sh`

Builds wheels for all supported Python versions and converts to manylinux format.

```bash
./scripts/build_wheels.sh
```

**What it does:**
1. Cleans previous builds
2. Builds source distribution (`.tar.gz`)
3. Builds wheels for Python 3.11, 3.12, 3.13, 3.14
4. Converts to manylinux format using `auditwheel`
5. Removes non-manylinux wheels

**Requirements:**
- Development environments must be set up first
- `auditwheel` must be installed

**Output:**
```
dist/
├── pysphorb-0.1.3.tar.gz
├── pysphorb-0.1.3-cp311-cp311-manylinux_2_35_x86_64.whl
├── pysphorb-0.1.3-cp312-cp312-manylinux_2_35_x86_64.whl
├── pysphorb-0.1.3-cp313-cp313-manylinux_2_35_x86_64.whl
└── pysphorb-0.1.3-cp314-cp314-manylinux_2_35_x86_64.whl
```

**Verification:**
```bash
# Test installation
pip install dist/pysphorb-*-cp312-*.whl --force-reinstall
python -c "import pysphorb; print(pysphorb.__version__)"
```

---

### 3. Upload to TestPyPI

**Script:** `upload_testpypi.sh`

Uploads to TestPyPI for testing before production deployment.

```bash
./scripts/upload_testpypi.sh
```

**What it does:**
1. Checks for built wheels in `dist/`
2. Prompts for TestPyPI API token (or uses `$TESTPYPI_TOKEN`)
3. Uploads wheels to TestPyPI
4. Creates test environment and verifies installation
5. Runs basic functionality tests

**Requirements:**
- Wheels must be built first
- TestPyPI API token (get from: https://test.pypi.org/manage/account/token/)

**Environment Variables:**
```bash
export TESTPYPI_TOKEN="pypi-AgEN..."
./scripts/upload_testpypi.sh
```

**Verification:**
After upload, test on different systems:

```bash
# Install from TestPyPI
pip install --index-url https://test.pypi.org/simple/ \
    --extra-index-url https://pypi.org/simple/ \
    pysphorb==0.1.3

# Test
python -c "
import pysphorb
detector = pysphorb.SPHORB()
print('Success!')
"
```

---

### 4. Upload to Production PyPI

**Script:** `upload_pypi.sh`

⚠️ **WARNING: IRREVERSIBLE ACTION** ⚠️

Uploads to production PyPI. Cannot be undone!

```bash
./scripts/upload_pypi.sh
```

**What it does:**
1. **Safety checks:**
   - Verifies version doesn't exist on PyPI
   - Checks if version was tested on TestPyPI
   - Checks git status
   - Checks for git tag
2. Prompts for PyPI API token (or uses `$PYPI_TOKEN`)
3. Requires manual confirmation (`yes`)
4. Uploads to PyPI
5. Tests installation from PyPI
6. Displays post-release checklist

**Requirements:**
- Package tested on TestPyPI
- PyPI API token (get from: https://pypi.org/manage/account/token/)
- Clean git status (recommended)

**Environment Variables:**
```bash
export PYPI_TOKEN="pypi-AgEI..."
./scripts/upload_pypi.sh
```

**Safety Features:**
- Version collision detection
- TestPyPI check
- Git status warning
- Final confirmation prompt
- Token format validation

**Post-Deployment:**
```bash
# Create git tag
git tag -a v0.1.3 -m "Release version 0.1.3"
git push origin v0.1.3

# Create GitHub release
# Visit: https://github.com/cshyundev/py_sphorb/releases/new
```

---

## Complete Workflow Example

```bash
# 1. Update version in pyproject.toml
vim pyproject.toml
# Change: version = "0.1.4"

# 2. Update version in pysphorb/__init__.py
vim pysphorb/__init__.py
# Change: __version__ = "0.1.4"

# 3. Commit changes
git add pyproject.toml pysphorb/__init__.py
git commit -m "Bump version to 0.1.4"

# 4. Setup environment (first time only)
./scripts/setup_dev_env.sh

# 5. Build wheels
./scripts/build_wheels.sh

# 6. Upload to TestPyPI
export TESTPYPI_TOKEN="pypi-AgEN..."
./scripts/upload_testpypi.sh

# 7. Test on multiple systems
# (Install and test on different machines/OS)

# 8. Upload to PyPI
export PYPI_TOKEN="pypi-AgEI..."
./scripts/upload_pypi.sh

# 9. Create git tag
git tag -a v0.1.4 -m "Release version 0.1.4"
git push origin v0.1.4

# 10. Create GitHub release
# Visit: https://github.com/cshyundev/py_sphorb/releases/new
```

---

## Troubleshooting

### Script Permission Denied

```bash
chmod +x scripts/*.sh
```

### uv Not Found

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc  # or ~/.zshrc
```

### auditwheel Not Installed

```bash
pip install auditwheel
```

### Virtual Environment Not Found

```bash
./scripts/setup_dev_env.sh
```

### Build Fails

```bash
# Clean and retry
rm -rf build/ dist/ *.egg-info _skbuild/
./scripts/build_wheels.sh
```

### TestPyPI Upload Fails

Check token format:
- TestPyPI tokens start with `pypi-AgEN`
- PyPI tokens start with `pypi-AgEI`

Get new token:
- TestPyPI: https://test.pypi.org/manage/account/token/
- PyPI: https://pypi.org/manage/account/token/

### PyPI Upload: Version Already Exists

You cannot re-upload the same version. Options:

1. **Add new wheels to existing version:**
   ```bash
   # Will skip existing files
   python -m twine upload dist/*.whl --skip-existing
   ```

2. **Bump version:**
   ```bash
   # Update version in pyproject.toml and __init__.py
   ./scripts/build_wheels.sh
   ./scripts/upload_pypi.sh
   ```

---

## Environment Variables

| Variable | Purpose | Required |
|----------|---------|----------|
| `TESTPYPI_TOKEN` | TestPyPI API token | Optional (will prompt) |
| `PYPI_TOKEN` | PyPI API token | Optional (will prompt) |

**Setting tokens:**

```bash
# Add to ~/.bashrc or ~/.zshrc
export TESTPYPI_TOKEN="pypi-AgEN..."
export PYPI_TOKEN="pypi-AgEI..."
```

**Temporary (current session only):**

```bash
export TESTPYPI_TOKEN="pypi-AgEN..."
./scripts/upload_testpypi.sh
```

---

## Best Practices

1. **Always test on TestPyPI first**
   ```bash
   ./scripts/upload_testpypi.sh
   # Test thoroughly
   ./scripts/upload_pypi.sh
   ```

2. **Version management**
   - Follow semantic versioning (MAJOR.MINOR.PATCH)
   - Update both `pyproject.toml` and `pysphorb/__init__.py`
   - Create git tags for releases

3. **Git workflow**
   - Commit version changes before building
   - Tag after successful PyPI upload
   - Keep clean git history

4. **Testing**
   - Test on TestPyPI first
   - Test installation on multiple Python versions
   - Test on different systems (if possible)

5. **Token security**
   - Never commit tokens to git
   - Use environment variables
   - Rotate tokens periodically

---

## See Also

- [PYPI_DEPLOYMENT.md](../docs/PYPI_DEPLOYMENT.md) - Detailed deployment guide
- [BUILD_WHEELS.md](../docs/BUILD_WHEELS.md) - Wheel building details
- [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) - Common issues
