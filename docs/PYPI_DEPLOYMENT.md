# PyPI Deployment Guide

This document describes the complete process for deploying PySPHORB to PyPI, including testing on TestPyPI.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Version Update](#version-update)
3. [Local Testing](#local-testing)
4. [Build Wheels](#build-wheels)
5. [Testing on TestPyPI](#testing-on-testpypi)
6. [Deploy to PyPI](#deploy-to-pypi)
7. [Verification](#verification)
8. [Post-Deployment](#post-deployment)

## Prerequisites

### Required Tools

```bash
# Install build and deployment tools
pip install build twine auditwheel

# Install uv for Python version management
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### API Tokens

You need API tokens for both TestPyPI and PyPI:

1. **TestPyPI Token**: https://test.pypi.org/manage/account/token/
2. **PyPI Token**: https://pypi.org/manage/account/token/

Store tokens securely. Never commit them to git.

## Version Update

1. Update version in `pyproject.toml`:

```toml
[project]
name = "pysphorb"
version = "0.1.3"  # Update this
```

2. Update version in `pysphorb/__init__.py`:

```python
__version__ = "0.1.3"  # Update this
```

## Local Testing

Before building wheels, test the package builds and works locally:

```bash
# Clean previous builds
rm -rf build/ dist/ *.egg-info

# Build source distribution
python -m build --sdist

# Install from source distribution
pip install dist/pysphorb-*.tar.gz

# Test import
python -c "import pysphorb; print(pysphorb.__version__)"
```

## Build Wheels

Build wheels for multiple Python versions. See [BUILD_WHEELS.md](BUILD_WHEELS.md) for detailed instructions.

### Quick Build (All Versions)

```bash
# Install Python versions
uv python install 3.11 3.12 3.13 3.14

# Create virtual environments and build wheels
for ver in 311 312 313 314; do
    uv venv .venv-py${ver} --python 3.${ver#3}
    source .venv-py${ver}/bin/activate
    pip install build
    python -m build --wheel
    deactivate
done
```

### Convert to manylinux

Wheels must use manylinux tags for PyPI:

```bash
# Convert all wheels
for wheel in dist/*-linux_x86_64.whl; do
    auditwheel repair "$wheel" -w dist/
done

# Verify manylinux wheels created
ls -lh dist/*manylinux*.whl
```

Expected output:
```
pysphorb-0.1.3-cp311-cp311-manylinux_2_35_x86_64.whl
pysphorb-0.1.3-cp312-cp312-manylinux_2_35_x86_64.whl
pysphorb-0.1.3-cp313-cp313-manylinux_2_35_x86_64.whl
pysphorb-0.1.3-cp314-cp314-manylinux_2_35_x86_64.whl
```

## Testing on TestPyPI

Always test on TestPyPI before production deployment.

### Upload to TestPyPI

```bash
python -m twine upload --repository testpypi dist/*manylinux*.whl \
    --username __token__ \
    --password pypi-AgENdGVzdC5weXBpLm9yZwIk...  # Your TestPyPI token
```

### Install from TestPyPI

```bash
# Create fresh virtual environment
python3 -m venv test_env
source test_env/bin/activate

# Install from TestPyPI
pip install --index-url https://test.pypi.org/simple/ \
    --extra-index-url https://pypi.org/simple/ \
    pysphorb

# Test functionality
python -c "
import pysphorb
import cv2
import numpy as np

print(f'Version: {pysphorb.__version__}')

# Create test image
img = np.random.randint(0, 255, (480, 640, 3), dtype=np.uint8)

# Test detection
detector = pysphorb.SPHORB()
keypoints, descriptors = detector.detectAndCompute(img)
print(f'Detected {len(keypoints)} keypoints')
"

deactivate
```

### Verify TestPyPI Installation

Check that:
- ✅ Package installs without errors
- ✅ Version is correct
- ✅ All dependencies install properly
- ✅ Import works
- ✅ Basic functionality works
- ✅ Data files are included (no segfault)

## Deploy to PyPI

Once TestPyPI testing succeeds, deploy to production PyPI.

### Upload to PyPI

```bash
python -m twine upload dist/*manylinux*.whl \
    --username __token__ \
    --password pypi-AgEIcHlwaS5vcmcCJDI2NTQ2NTBi...  # Your PyPI token
```

### Handle Existing Files

If some wheels already exist (e.g., you're adding new Python versions):

```bash
# Skip files that already exist
python -m twine upload dist/*manylinux*.whl \
    --username __token__ \
    --password pypi-AgEIcHlwaS5vcmcCJDI2NTQ2NTBi... \
    --skip-existing
```

## Verification

### Install from PyPI

Test installation for each Python version:

```bash
# Python 3.11
/path/to/python3.11 -m venv test_311
test_311/bin/pip install --no-cache-dir pysphorb
test_311/bin/python -c "import pysphorb; print(f'Version: {pysphorb.__version__}')"

# Python 3.12
/path/to/python3.12 -m venv test_312
test_312/bin/pip install --no-cache-dir pysphorb
test_312/bin/python -c "import pysphorb; print(f'Version: {pysphorb.__version__}')"

# Python 3.13
/path/to/python3.13 -m venv test_313
test_313/bin/pip install --no-cache-dir pysphorb
test_313/bin/python -c "import pysphorb; print(f'Version: {pysphorb.__version__}')"

# Python 3.14
/path/to/python3.14 -m venv test_314
test_314/bin/pip install --no-cache-dir pysphorb
test_314/bin/python -c "import pysphorb; print(f'Version: {pysphorb.__version__}')"
```

### Run Integration Test

```python
import pysphorb
import cv2
import numpy as np

# Load test images
img1 = cv2.imread('Image/1.jpg')
img2 = cv2.imread('Image/2.jpg')

# Initialize detector
detector = pysphorb.SPHORB(nfeatures=500)

# Detect and compute
kp1, desc1 = detector.detectAndCompute(img1)
kp2, desc2 = detector.detectAndCompute(img2)

print(f'Image 1: {len(kp1)} keypoints')
print(f'Image 2: {len(kp2)} keypoints')

# Match features
matches = pysphorb.ratioTest(desc1, desc2, ratio=0.8)
print(f'Matches: {len(matches)}')
```

Expected output:
```
Image 1: 509 keypoints
Image 2: 525 keypoints
Matches: 238
```

## Post-Deployment

### Update Repository

1. Commit all changes including version updates:

```bash
git add pyproject.toml pysphorb/__init__.py
git commit -m "Release v0.1.3"
git push origin main
```

2. Create a git tag:

```bash
git tag -a v0.1.3 -m "Release version 0.1.3"
git push origin v0.1.3
```

### Create GitHub Release

1. Go to repository releases page
2. Click "Create a new release"
3. Select tag `v0.1.3`
4. Add release notes describing changes
5. Publish release

### Update Documentation

1. Update README.md if needed
2. Add release notes to CHANGELOG.md (if exists)
3. Update version in any documentation

## Cleanup

Remove build artifacts (keep them locally for reference):

```bash
# Remove build directories
rm -rf build/ *.egg-info

# Optionally remove wheels (they're on PyPI now)
# rm -rf dist/

# Remove test virtual environments
rm -rf test_*/
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

## Version History

- **0.1.3** (2025-10-10): Added wheels for Python 3.11, 3.12, 3.13, 3.14
- **0.1.0**: Initial release (Python 3.12 only)
