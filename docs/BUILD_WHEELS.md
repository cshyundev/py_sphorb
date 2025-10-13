# Building Wheels for Multiple Python Versions

This document describes how to build PySPHORB wheels for multiple Python versions.

## Table of Contents

1. [Overview](#overview)
2. [Python Version Management](#python-version-management)
3. [Building Process](#building-process)
4. [Converting to manylinux](#converting-to-manylinux)
5. [Local Development Build](#local-development-build)

## Overview

PySPHORB uses:
- **Build System**: scikit-build-core + CMake
- **Bindings**: pybind11
- **Supported Python**: 3.11, 3.12, 3.13, 3.14
- **Platform**: Linux x86_64

Each Python version requires a separate wheel build because the package contains compiled C++ extensions.

## Python Version Management

### Using uv (Recommended)

`uv` is a fast Python version manager and virtual environment tool.

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Python versions
uv python install 3.11
uv python install 3.12
uv python install 3.13
uv python install 3.14

# List installed versions
uv python list

# Find installation paths
ls ~/.local/share/uv/python/
```

Example output:
```
cpython-3.11.13-linux-x86_64-gnu
cpython-3.12.7-linux-x86_64-gnu
cpython-3.13.4-linux-x86_64-gnu
cpython-3.14.0b1-linux-x86_64-gnu
```

### Alternative: System Package Manager

For Ubuntu/Debian:

```bash
# Add deadsnakes PPA
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update

# Install Python versions
sudo apt install python3.11 python3.11-dev python3.11-venv
sudo apt install python3.12 python3.12-dev python3.12-venv
sudo apt install python3.13 python3.13-dev python3.13-venv
```

### Alternative: pyenv

```bash
# Install pyenv
curl https://pyenv.run | bash

# Install Python versions
pyenv install 3.11.7
pyenv install 3.12.1
pyenv install 3.13.0
pyenv install 3.14.0
```

## Building Process

### Prerequisites

Install build dependencies in your base environment:

```bash
pip install build scikit-build-core pybind11
```

System dependencies:

```bash
sudo apt install cmake g++ pkg-config libopencv-dev
```

### Build All Wheels

#### Method 1: Using uv (Recommended)

```bash
# Clean previous builds
rm -rf dist/*.whl build/

# Build for each Python version
for ver in 311 312 313 314; do
    echo "Building for Python 3.${ver#3*}..."

    # Create virtual environment
    uv venv .venv-py${ver} --python 3.${ver#3*}

    # Activate and build
    source .venv-py${ver}/bin/activate
    pip install build
    python -m build --wheel
    deactivate
done

# Check built wheels
ls -lh dist/*-linux_x86_64.whl
```

#### Method 2: Direct Python Paths

If you know exact Python paths:

```bash
# Python 3.11
~/.local/share/uv/python/cpython-3.11.13-linux-x86_64-gnu/bin/python3 -m venv .venv-py311
source .venv-py311/bin/activate
pip install build
python -m build --wheel
deactivate

# Python 3.12
~/.local/share/uv/python/cpython-3.12.7-linux-x86_64-gnu/bin/python3 -m venv .venv-py312
source .venv-py312/bin/activate
pip install build
python -m build --wheel
deactivate

# Python 3.13
~/.local/share/uv/python/cpython-3.13.4-linux-x86_64-gnu/bin/python3 -m venv .venv-py313
source .venv-py313/bin/activate
pip install build
python -m build --wheel
deactivate

# Python 3.14
~/.local/share/uv/python/cpython-3.14.0b1-linux-x86_64-gnu/bin/python3 -m venv .venv-py314
source .venv-py314/bin/activate
pip install build
python -m build --wheel
deactivate
```

### Build Output

After building, you should see wheels in `dist/`:

```
dist/
├── pysphorb-0.1.3-cp311-cp311-linux_x86_64.whl  (~22 MB)
├── pysphorb-0.1.3-cp312-cp312-linux_x86_64.whl  (~22 MB)
├── pysphorb-0.1.3-cp313-cp313-linux_x86_64.whl  (~22 MB)
├── pysphorb-0.1.3-cp314-cp314-linux_x86_64.whl  (~22 MB)
└── pysphorb-0.1.3.tar.gz                        (~22 MB)
```

## Converting to manylinux

PyPI requires manylinux wheels instead of `linux_x86_64` for Linux packages.

### Install auditwheel

```bash
pip install auditwheel
```

### Repair Wheels

```bash
# Convert each wheel
auditwheel repair dist/pysphorb-0.1.3-cp311-cp311-linux_x86_64.whl -w dist/
auditwheel repair dist/pysphorb-0.1.3-cp312-cp312-linux_x86_64.whl -w dist/
auditwheel repair dist/pysphorb-0.1.3-cp313-cp313-linux_x86_64.whl -w dist/
auditwheel repair dist/pysphorb-0.1.3-cp314-cp314-linux_x86_64.whl -w dist/
```

Or in a loop:

```bash
for wheel in dist/*-linux_x86_64.whl; do
    echo "Converting $wheel..."
    auditwheel repair "$wheel" -w dist/
done
```

### Verify manylinux Wheels

```bash
ls -lh dist/*manylinux*.whl
```

Expected output:
```
dist/pysphorb-0.1.3-cp311-cp311-manylinux_2_35_x86_64.whl  (~85 MB)
dist/pysphorb-0.1.3-cp312-cp312-manylinux_2_35_x86_64.whl  (~85 MB)
dist/pysphorb-0.1.3-cp313-cp313-manylinux_2_35_x86_64.whl  (~85 MB)
dist/pysphorb-0.1.3-cp314-cp314-manylinux_2_35_x86_64.whl  (~85 MB)
```

Note: Wheels grow from ~22 MB to ~85 MB because `auditwheel` bundles required shared libraries (OpenCV, etc.) into the wheel for broader compatibility.

### What does auditwheel do?

1. **Analyzes dependencies**: Checks which shared libraries the wheel depends on
2. **Bundles libraries**: Copies external libraries into the wheel
3. **Repairs RPATH**: Adjusts library paths to load from wheel
4. **Updates tags**: Changes platform tag from `linux_x86_64` to `manylinux_2_35_x86_64`

The `manylinux_2_35` tag indicates the wheel is compatible with systems having glibc 2.35 or newer (Ubuntu 22.04+, Debian 12+, etc.).

## Local Development Build

For development and testing, you don't need to build wheels for all Python versions.

### Quick Development Build

```bash
# Install in editable mode (recommended for development)
pip install -e .

# Test changes immediately
python -c "import pysphorb; print(pysphorb.__version__)"
```

### In-place Build

```bash
# Build extension in-place
python -m build --wheel

# Install locally
pip install dist/pysphorb-*.whl --force-reinstall
```

### Clean Build

```bash
# Remove all build artifacts
rm -rf build/ dist/ *.egg-info _skbuild/

# Clean pycache
find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null

# Rebuild
python -m build --wheel
```

## Build Troubleshooting

### CMake not found

```bash
sudo apt install cmake
# or
pip install cmake
```

### OpenCV not found

```bash
# Install system OpenCV
sudo apt install libopencv-dev

# Or verify pkg-config can find it
pkg-config --cflags --libs opencv4
```

### Python.h not found

```bash
# Install Python development headers
sudo apt install python3.11-dev  # Adjust version
```

### pybind11 not found

```bash
pip install pybind11
```

### Build fails with "No module named skbuild"

```bash
pip install scikit-build-core
```

## Verifying Built Wheels

### Inspect Wheel Contents

```bash
# Extract wheel
unzip -l dist/pysphorb-0.1.3-cp312-cp312-manylinux_2_35_x86_64.whl

# Or use wheel tool
pip install wheel
wheel unpack dist/pysphorb-0.1.3-cp312-cp312-manylinux_2_35_x86_64.whl
```

### Check Metadata

```bash
# View wheel metadata
unzip -p dist/pysphorb-*.whl '*/METADATA'
```

### Test Installation

```bash
# Create fresh environment
python -m venv test_wheel
source test_wheel/bin/activate

# Install built wheel
pip install dist/pysphorb-0.1.3-cp312-cp312-manylinux_2_35_x86_64.whl

# Test
python -c "
import pysphorb
print(f'Version: {pysphorb.__version__}')
detector = pysphorb.SPHORB()
print('Detector created successfully')
"

deactivate
rm -rf test_wheel
```

## File Structure in Wheel

A properly built wheel should contain:

```
pysphorb-0.1.3-cp312-cp312-manylinux_2_35_x86_64.whl
├── pysphorb/
│   ├── __init__.py              # Python wrapper
│   ├── pysphorb.cpython-312-x86_64-linux-gnu.so  # C++ extension
│   └── src/
│       └── Data/                # SPHORB data files
│           ├── imginfo256_0.pfm
│           ├── imginfo256_1.pfm
│           ├── ... (more .pfm files)
│           └── orb_pattern.bmp
└── pysphorb-0.1.3.dist-info/
    ├── METADATA
    ├── WHEEL
    └── RECORD
```

The `src/Data/` directory is crucial - it contains precomputed spherical grid data that SPHORB needs at runtime.

## Automation Script

Create `build_all_wheels.sh`:

```bash
#!/bin/bash
set -e

echo "Building PySPHORB wheels for all Python versions..."

# Clean previous builds
rm -rf dist/*.whl build/

# Python versions to build
VERSIONS="311 312 313 314"

for ver in $VERSIONS; do
    py_ver="3.${ver#3*}"
    echo "Building for Python $py_ver..."

    # Create venv
    uv venv .venv-py${ver} --python $py_ver
    source .venv-py${ver}/bin/activate

    # Install build tools
    pip install -q build

    # Build wheel
    python -m build --wheel

    deactivate
done

echo "Converting to manylinux..."
for wheel in dist/*-linux_x86_64.whl; do
    auditwheel repair "$wheel" -w dist/
done

echo "Build complete!"
ls -lh dist/*manylinux*.whl
```

Make executable and run:

```bash
chmod +x build_all_wheels.sh
./build_all_wheels.sh
```
