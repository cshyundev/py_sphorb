# Troubleshooting Guide

This document covers common issues encountered during building, testing, and deploying PySPHORB.

## Table of Contents

1. [Build Issues](#build-issues)
2. [Wheel Issues](#wheel-issues)
3. [PyPI Upload Issues](#pypi-upload-issues)
4. [Installation Issues](#installation-issues)
5. [Runtime Issues](#runtime-issues)

## Build Issues

### Issue: CMake cannot find OpenCV

**Error:**
```
CMake Error at CMakeLists.txt:X:
  Could not find a package configuration file provided by "OpenCV"
```

**Solution:**

Install OpenCV development files:

```bash
# Ubuntu/Debian
sudo apt install libopencv-dev pkg-config

# Verify installation
pkg-config --modversion opencv4
pkg-config --cflags --libs opencv4
```

If OpenCV is installed but not found, set `OpenCV_DIR`:

```bash
export OpenCV_DIR=/usr/lib/x86_64-linux-gnu/cmake/opencv4
python -m build --wheel
```

---

### Issue: pybind11 not found

**Error:**
```
CMake Error: Could not find pybind11
```

**Solution:**

```bash
pip install pybind11
```

Or install system package:

```bash
sudo apt install pybind11-dev
```

---

### Issue: Python.h not found

**Error:**
```
fatal error: Python.h: No such file or directory
```

**Solution:**

Install Python development headers:

```bash
# For Python 3.11
sudo apt install python3.11-dev

# For Python 3.12
sudo apt install python3.12-dev

# Verify
python3-config --includes
```

---

### Issue: Build fails with "No space left on device"

**Error:**
```
OSError: [Errno 28] No space left on device
```

**Solution:**

Check disk space:

```bash
df -h

# Clean build artifacts
rm -rf build/ dist/ *.egg-info _skbuild/

# Clean pip cache
pip cache purge

# Clean old wheels
rm dist/*-linux_x86_64.whl  # Keep manylinux wheels only
```

---

## Wheel Issues

### Issue: Platform tag 'linux_x86_64' not accepted by PyPI

**Error:**
```
HTTPError: 400 Bad Request from https://upload.pypi.org/legacy/
Binary wheel has an unsupported platform tag 'linux_x86_64'
```

**Solution:**

Convert wheels to manylinux format:

```bash
pip install auditwheel

auditwheel repair dist/pysphorb-*-linux_x86_64.whl -w dist/
```

Then upload the `manylinux` wheels.

---

### Issue: auditwheel fails with "cannot repair"

**Error:**
```
ValueError: Cannot repair wheel, because required library could not be located
```

**Solution:**

This usually means a dependency is not available as a shared library. Check:

```bash
ldd _skbuild/*/cmake-build/pysphorb*.so
```

If critical libraries are missing:
1. Install missing system libraries
2. Rebuild wheel
3. Run auditwheel again

For PySPHORB, ensure OpenCV is properly installed.

---

### Issue: Wheel is too large (>100 MB)

**Error:**
```
HTTPError: 400 Bad Request
File too large. Maximum file size is 100 MB
```

**Solution:**

Check what's included in the wheel:

```bash
unzip -l dist/pysphorb-*.whl | head -50
```

Common causes:
1. Debug symbols not stripped (add `-s` to linker flags)
2. Unnecessary data files included
3. Duplicate libraries bundled

For PySPHORB, wheels should be ~85 MB (manylinux) or ~22 MB (linux_x86_64).

---

## PyPI Upload Issues

### Issue: Invalid API token

**Error:**
```
HTTPError: 403 Forbidden
Invalid or non-existent authentication information
```

**Solution:**

1. Verify token format:
   - TestPyPI: `pypi-AgENdGVzdC5weXBpLm9yZw...`
   - PyPI: `pypi-AgEIcHlwaS5vcmcC...`

2. Check token hasn't expired on PyPI/TestPyPI account settings

3. Ensure using `__token__` as username:

```bash
python -m twine upload dist/*.whl \
    --username __token__ \
    --password pypi-YOUR_TOKEN_HERE
```

---

### Issue: File already exists on PyPI

**Error:**
```
HTTPError: 400 Bad Request
File already exists
```

**Solution:**

PyPI doesn't allow re-uploading the same filename. Options:

1. **Skip existing files** (when adding new wheels to existing version):
```bash
twine upload dist/*.whl --skip-existing
```

2. **Bump version** (for new release):
```bash
# Update version in pyproject.toml
version = "0.1.4"

# Rebuild and upload
python -m build --wheel
auditwheel repair dist/*-linux_x86_64.whl -w dist/
twine upload dist/*manylinux*.whl
```

3. **Delete from PyPI** (not recommended):
   - Go to PyPI project page
   - Delete specific files (can't re-upload same version)

---

### Issue: README not rendering on PyPI

**Error:**
README shows as plain text instead of formatted markdown.

**Solution:**

Ensure `pyproject.toml` specifies README:

```toml
[project]
readme = "README.md"
```

Check README syntax:

```bash
# Install readme_renderer
pip install readme-renderer

# Check README
python -m readme_renderer README.md
```

---

## Installation Issues

### Issue: ModuleNotFoundError when testing locally

**Error:**
```
ModuleNotFoundError: No module named 'pysphorb.pysphorb'
```

**Solution:**

This happens when testing in the source directory. Python tries to import the local `pysphorb/` folder instead of the installed package.

```bash
# Test in different directory
cd /tmp
python -c "import pysphorb; print(pysphorb.__version__)"
```

Or remove local package:

```bash
cd /path/to/pysphorb
rm -rf pysphorb/__pycache__
python -c "import pysphorb"
```

---

### Issue: pip cannot find package on PyPI

**Error:**
```
ERROR: Could not find a version that satisfies the requirement pysphorb
```

**Solution:**

1. **Check package name**: Ensure correct spelling
   ```bash
   pip search pysphorb  # May not work on newer pip
   # Or visit: https://pypi.org/project/pysphorb/
   ```

2. **Check Python version**: Package requires Python >= 3.11
   ```bash
   python --version
   pip install pysphorb  # Should work on 3.11+
   ```

3. **Clear pip cache**:
   ```bash
   pip cache purge
   pip install --no-cache-dir pysphorb
   ```

4. **Try with explicit version**:
   ```bash
   pip install pysphorb==0.1.3
   ```

---

### Issue: No matching distribution found

**Error:**
```
ERROR: Could not find a version that satisfies the requirement pysphorb
ERROR: No matching distribution found for pysphorb
```

**Solution:**

Check platform and Python version:

```bash
python -c "import sys; print(sys.version); import platform; print(platform.platform())"
```

PySPHORB supports:
- Python: 3.11, 3.12, 3.13, 3.14
- Platform: Linux x86_64

For unsupported platforms, install from source:

```bash
pip install git+https://github.com/cshyundev/py_sphorb.git
```

---

## Runtime Issues

### Issue: Segmentation fault on import or initialization

**Error:**
```python
import pysphorb
detector = pysphorb.SPHORB()
Segmentation fault (core dumped)
```

**Solution:**

This typically means data files are missing. Verify installation:

```bash
python -c "
import pysphorb
from pathlib import Path

pkg_dir = Path(pysphorb.__file__).parent
data_dir = pkg_dir / 'src' / 'Data'

print(f'Package dir: {pkg_dir}')
print(f'Data dir exists: {data_dir.exists()}')

if data_dir.exists():
    files = list(data_dir.glob('*.pfm'))
    print(f'Found {len(files)} .pfm files')
"
```

Expected output:
```
Package dir: /path/to/site-packages/pysphorb
Data dir exists: True
Found 14 .pfm files
```

If data files are missing:
1. Reinstall package: `pip install --force-reinstall pysphorb`
2. If building from source, check `CMakeLists.txt` has data installation:
   ```cmake
   install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/Data DESTINATION src)
   ```

---

### Issue: FileNotFoundError for data files

**Error:**
```
FileNotFoundError: [Errno 2] No such file or directory: 'src/Data/imginfo256_0.pfm'
```

**Solution:**

The Python wrapper should handle this by changing to package directory. Verify `pysphorb/__init__.py` has the wrapper class:

```python
class SPHORB:
    def __init__(self, nfeatures=500, nlevels=7, b=20):
        self._orig_cwd = os.getcwd()
        os.chdir(_package_dir)
        try:
            self._sphorb = _SPHORB(nfeatures, nlevels, b)
        finally:
            os.chdir(self._orig_cwd)
```

If using old version without wrapper, upgrade:

```bash
pip install --upgrade pysphorb
```

---

### Issue: Feature detection returns no keypoints

**Error:**
No error, but `detectAndCompute()` returns empty keypoints list.

**Solution:**

1. **Check image format**: Must be BGR format (OpenCV default)
   ```python
   import cv2
   img = cv2.imread('image.jpg')  # Correct
   # Not: img = Image.open('image.jpg')  # Wrong
   ```

2. **Check image size**: Image should be reasonable size
   ```python
   print(f'Image shape: {img.shape}')  # Should be (height, width, 3)
   ```

3. **Adjust parameters**:
   ```python
   detector = pysphorb.SPHORB(nfeatures=1000)  # Increase max features
   ```

4. **Check image is not blank**:
   ```python
   import numpy as np
   print(f'Image mean: {np.mean(img)}')  # Should be > 0
   print(f'Image std: {np.std(img)}')    # Should be > 0
   ```

---

### Issue: TypeError: descriptors are None

**Error:**
```python
matches = pysphorb.ratioTest(desc1, desc2)
TypeError: Expected array, got None
```

**Solution:**

Descriptors are `None` when no keypoints detected:

```python
kp, desc = detector.detectAndCompute(img)

if desc is None:
    print("No features detected!")
    # Check image quality, try different parameters
else:
    print(f"Found {len(kp)} keypoints")
    matches = pysphorb.ratioTest(desc1, desc2)
```

---

## Performance Issues

### Issue: Feature detection is very slow

**Problem:**
Detection takes several seconds per image.

**Solution:**

1. **Reduce number of features**:
   ```python
   detector = pysphorb.SPHORB(nfeatures=250)  # Default is 500
   ```

2. **Reduce pyramid levels**:
   ```python
   detector = pysphorb.SPHORB(nlevels=5)  # Default is 7
   ```

3. **Resize large images**:
   ```python
   import cv2

   # Resize to max dimension 1024
   h, w = img.shape[:2]
   if max(h, w) > 1024:
       scale = 1024 / max(h, w)
       img = cv2.resize(img, None, fx=scale, fy=scale)
   ```

4. **Use multiple cores** (if processing multiple images):
   ```python
   from multiprocessing import Pool

   def detect_features(img_path):
       detector = pysphorb.SPHORB()
       img = cv2.imread(img_path)
       return detector.detectAndCompute(img)

   with Pool(4) as p:
       results = p.map(detect_features, image_paths)
   ```

---

## Getting Help

If you encounter an issue not covered here:

1. **Check existing issues**: https://github.com/cshyundev/py_sphorb/issues
2. **Create new issue** with:
   - Python version: `python --version`
   - Platform: `uname -a` (Linux) or `ver` (Windows)
   - PySPHORB version: `pip show pysphorb`
   - Full error traceback
   - Minimal code to reproduce

3. **Contact**:
   - GitHub Issues: https://github.com/cshyundev/py_sphorb/issues
   - Email: cshyundev@gmail.com
