#!/bin/bash
# Upload PySPHORB to Production PyPI
# WARNING: This is irreversible! Test on TestPyPI first!

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Upload to Production PyPI"
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

# Safety checks
echo -e "${MAGENTA}=========================================="
echo "SAFETY CHECKS"
echo -e "==========================================${NC}"
echo ""

# Check 1: Version not already on PyPI
echo -n "Checking if version exists on PyPI... "
if pip index versions pysphorb 2>&1 | grep -q "$VERSION"; then
    echo -e "${RED}✗${NC}"
    echo ""
    echo -e "${RED}Error: Version $VERSION already exists on PyPI${NC}"
    echo "You cannot re-upload the same version."
    echo ""
    echo "Options:"
    echo "  1. Bump version in pyproject.toml and rebuild"
    echo "  2. Use --skip-existing flag (only for adding new wheels)"
    exit 1
else
    echo -e "${GREEN}✓${NC}"
fi

# Check 2: TestPyPI upload recommended
echo -n "Checking TestPyPI... "
if pip index versions pysphorb 2>&1 --index-url https://test.pypi.org/simple/ | grep -q "$VERSION"; then
    echo -e "${GREEN}✓ Found on TestPyPI${NC}"
else
    echo -e "${YELLOW}✗ Not found on TestPyPI${NC}"
    echo ""
    echo -e "${YELLOW}Warning: Version not tested on TestPyPI${NC}"
    echo "It's strongly recommended to test on TestPyPI first:"
    echo "  ./scripts/upload_testpypi.sh"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted${NC}"
        exit 0
    fi
    echo ""
fi

# Check 3: Git status
echo -n "Checking git status... "
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}✗ Uncommitted changes${NC}"
    echo ""
    git status --short
    echo ""
    echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted${NC}"
        exit 0
    fi
    echo ""
else
    echo -e "${GREEN}✓${NC}"
fi

# Check 4: Git tag
echo -n "Checking git tag... "
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Tag exists${NC}"
else
    echo -e "${YELLOW}✗ No tag${NC}"
    echo ""
    echo -e "${YELLOW}Warning: No git tag for v${VERSION}${NC}"
    echo "Create tag after successful upload:"
    echo "  git tag -a v${VERSION} -m 'Release version ${VERSION}'"
    echo "  git push origin v${VERSION}"
    echo ""
fi

echo ""
echo -e "${MAGENTA}==========================================${NC}"
echo ""

# Check for PyPI token
if [ -z "$PYPI_TOKEN" ]; then
    echo -e "${YELLOW}PyPI token not found in environment${NC}"
    echo ""
    echo "Enter your PyPI API token:"
    echo "(Get it from: https://pypi.org/manage/account/token/)"
    echo ""
    read -s -p "Token: " PYPI_TOKEN
    echo ""
    echo ""
fi

# Validate token format
if [[ ! "$PYPI_TOKEN" =~ ^pypi-AgEI ]]; then
    echo -e "${RED}Error: Invalid PyPI token format${NC}"
    echo "Production PyPI token should start with: pypi-AgEI..."
    echo "(TestPyPI tokens start with: pypi-AgEN...)"
    exit 1
fi

# FINAL WARNING (skip if -y flag or AUTO_CONFIRM set)
if [[ "$1" != "-y" && "$AUTO_CONFIRM" != "1" ]]; then
    echo -e "${RED}=========================================="
    echo "⚠️  FINAL WARNING ⚠️"
    echo "==========================================${NC}"
    echo ""
    echo -e "${RED}You are about to upload to PRODUCTION PyPI!${NC}"
    echo ""
    echo "This action is IRREVERSIBLE. Once uploaded:"
    echo "  • You CANNOT delete or modify the release"
    echo "  • You CANNOT re-upload the same version"
    echo "  • The package will be PUBLIC and available worldwide"
    echo ""
    echo -e "Version: ${BLUE}${VERSION}${NC}"
    echo "Package: pysphorb"
    echo ""
    read -p "Type 'yes' to confirm upload to PyPI: " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}Aborted${NC}"
        exit 0
    fi
fi

echo ""
echo "Uploading to PyPI..."
echo ""

# Upload to PyPI
python3 -m twine upload \
    dist/*manylinux*.whl \
    dist/*.tar.gz \
    --username __token__ \
    --password "$PYPI_TOKEN" \
    --skip-existing

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Upload successful!${NC}"
else
    echo ""
    echo -e "${RED}✗ Upload failed${NC}"
    echo ""
    echo "Common issues:"
    echo "  • Version already exists (bump version and rebuild)"
    echo "  • Invalid token (check token permissions)"
    echo "  • Network error (try again)"
    exit 1
fi

echo ""
echo "=========================================="
echo "Testing Installation from PyPI"
echo "=========================================="
echo ""

echo "Waiting 10 seconds for PyPI to process..."
sleep 10

# Test installation from PyPI
echo "Creating test environment..."
TEST_VENV="/tmp/test_pysphorb_pypi_$$"

# Use Python 3.13 from uv (package requires Python >= 3.11)
PYTHON_313="$HOME/.local/share/uv/python/cpython-3.13.4-linux-x86_64-gnu/bin/python3"
if [ ! -f "$PYTHON_313" ]; then
    echo -e "${YELLOW}Warning: Python 3.13 not found, installing...${NC}"
    uv python install 3.13
fi

"$PYTHON_313" -m venv "$TEST_VENV"
source "$TEST_VENV/bin/activate"

echo "Installing from PyPI..."
pip install -q --no-cache-dir "pysphorb==${VERSION}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Installation successful"
else
    echo -e "${RED}✗${NC} Installation failed"
    echo "Package might still be processing. Try again in a few minutes."
    deactivate
    rm -rf "$TEST_VENV"
    exit 1
fi

echo ""
echo "Testing import and functionality..."
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
echo "🎉 PyPI Upload Complete! 🎉"
echo "=========================================="
echo ""
echo "Package URL:"
echo "  https://pypi.org/project/pysphorb/${VERSION}/"
echo ""
echo "Install command:"
echo "  pip install pysphorb==${VERSION}"
echo ""
echo "Post-release checklist:"
echo "  ✓ Package uploaded and tested"
echo "  ☐ Create git tag: git tag -a v${VERSION} -m 'Release version ${VERSION}'"
echo "  ☐ Push tag: git push origin v${VERSION}"
echo "  ☐ Create GitHub release: https://github.com/cshyundev/py_sphorb/releases/new"
echo "  ☐ Update CHANGELOG.md (if exists)"
echo "  ☐ Announce release (if applicable)"
echo ""
