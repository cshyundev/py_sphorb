#!/bin/bash
# Upload PySPHORB to TestPyPI
# Use this to test the package before uploading to production PyPI

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Upload to TestPyPI"
echo "=========================================="
echo ""

cd "$PROJECT_ROOT"

# Get version
VERSION=$(grep '^version = ' pyproject.toml | sed 's/version = "\(.*\)"/\1/')
echo -e "${BLUE}Version: ${VERSION}${NC}"
echo ""

# Check if dist/ directory exists and has files
if [ ! -d "dist" ] || [ -z "$(ls -A dist/*.whl 2>/dev/null)" ]; then
    echo -e "${RED}Error: No wheels found in dist/${NC}"
    echo "Run ./scripts/build_wheels.sh first"
    exit 1
fi

# List files to upload
echo "Files to upload:"
ls -lh dist/*manylinux*.whl | awk '{printf "  %-50s %6s\n", $9, $5}'
if ls dist/*.tar.gz &> /dev/null; then
    ls -lh dist/*.tar.gz | awk '{printf "  %-50s %6s\n", $9, $5}'
fi
echo ""

# Check for TestPyPI token
if [ -z "$TESTPYPI_TOKEN" ]; then
    echo -e "${YELLOW}TestPyPI token not found in environment${NC}"
    echo ""
    echo "Enter your TestPyPI API token:"
    echo "(Get it from: https://test.pypi.org/manage/account/token/)"
    echo ""
    read -s -p "Token: " TESTPYPI_TOKEN
    echo ""
    echo ""
fi

# Validate token format
if [[ ! "$TESTPYPI_TOKEN" =~ ^pypi-AgEN ]]; then
    echo -e "${RED}Error: Invalid TestPyPI token format${NC}"
    echo "Token should start with: pypi-AgEN..."
    exit 1
fi

# Final confirmation (skip if -y flag or AUTO_CONFIRM set)
if [[ "$1" != "-y" && "$AUTO_CONFIRM" != "1" ]]; then
    echo -e "${YELLOW}WARNING: This will upload to TestPyPI${NC}"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted${NC}"
        exit 0
    fi
    echo ""
fi

# Upload to TestPyPI
echo "Uploading to TestPyPI..."
echo ""

python3 -m twine upload --repository testpypi \
    dist/*manylinux*.whl \
    dist/*.tar.gz \
    --username __token__ \
    --password "$TESTPYPI_TOKEN" \
    --skip-existing \
    --verbose

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Upload successful!${NC}"
else
    echo ""
    echo -e "${RED}✗ Upload failed${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo "Testing Installation"
echo "=========================================="
echo ""

# Test installation from TestPyPI
echo "Creating test environment..."
TEST_VENV="/tmp/test_pysphorb_testpypi_$$"

# Use Python 3.13 from uv (package requires Python >= 3.11)
PYTHON_313="$HOME/.local/share/uv/python/cpython-3.13.4-linux-x86_64-gnu/bin/python3"
if [ ! -f "$PYTHON_313" ]; then
    echo -e "${YELLOW}Warning: Python 3.13 not found, installing...${NC}"
    uv python install 3.13
fi

"$PYTHON_313" -m venv "$TEST_VENV"
source "$TEST_VENV/bin/activate"

echo "Installing from TestPyPI..."
pip install -q --index-url https://test.pypi.org/simple/ \
    --extra-index-url https://pypi.org/simple/ \
    "pysphorb==${VERSION}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Installation successful"
else
    echo -e "${RED}✗${NC} Installation failed"
    deactivate
    rm -rf "$TEST_VENV"
    exit 1
fi

echo ""
echo "Testing import and basic functionality..."
# Run from /tmp to avoid importing local source code
cd /tmp
python3 << 'EOF'
import sys
import pysphorb
import cv2
import numpy as np

print(f"✓ Import successful")
print(f"  Version: {pysphorb.__version__}")
print(f"  Python: {sys.version.split()[0]}")

# Test basic functionality
detector = pysphorb.SPHORB()
print(f"✓ Detector created")

# Test with dummy image
img = np.random.randint(0, 255, (480, 640, 3), dtype=np.uint8)
kp, desc = detector.detectAndCompute(img)
print(f"✓ Feature detection works ({len(kp)} keypoints)")
EOF
cd "$PROJECT_ROOT"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✓ All tests passed!${NC}"
else
    echo -e "\n${RED}✗ Tests failed${NC}"
    deactivate
    rm -rf "$TEST_VENV"
    exit 1
fi

deactivate
rm -rf "$TEST_VENV"

echo ""
echo "=========================================="
echo "TestPyPI Upload Complete!"
echo "=========================================="
echo ""
echo "Package URL:"
echo "  https://test.pypi.org/project/pysphorb/${VERSION}/"
echo ""
echo "Install command:"
echo "  pip install --index-url https://test.pypi.org/simple/ \\"
echo "      --extra-index-url https://pypi.org/simple/ \\"
echo "      pysphorb==${VERSION}"
echo ""
echo "Next steps:"
echo "  1. Test thoroughly on different systems"
echo "  2. If everything works, upload to production PyPI:"
echo "     ./scripts/upload_pypi.sh"
echo ""
