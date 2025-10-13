#!/bin/bash
# Build wheels and source distribution for PySPHORB
# Builds for Python 3.11, 3.12, 3.13, 3.14

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
echo "PySPHORB Wheel Builder"
echo "=========================================="
echo ""

cd "$PROJECT_ROOT"

# Check version in pyproject.toml
VERSION=$(grep '^version = ' pyproject.toml | sed 's/version = "\(.*\)"/\1/')
echo -e "${BLUE}Building version: ${VERSION}${NC}"
echo ""

# Ask for confirmation (skip if -y flag or AUTO_CONFIRM set)
if [[ "$1" != "-y" && "$AUTO_CONFIRM" != "1" ]]; then
    read -p "Is this version correct? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Aborted.${NC} Update version in pyproject.toml"
        exit 1
    fi
    echo ""
fi

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build/ dist/*.whl dist/*.tar.gz *.egg-info _skbuild/
echo -e "${GREEN}✓${NC} Cleaned build artifacts"
echo ""

# Build source distribution first
echo "Building source distribution..."
python3 -m build --sdist
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Source distribution built"
else
    echo -e "${RED}✗${NC} Failed to build source distribution"
    exit 1
fi
echo ""

# Python versions to build
PYTHON_VERSIONS=("311" "312" "313" "314")
VENV_NAMES=(".venv-py311" ".venv-py312" ".venv-py313" ".venv-py314")

echo "Building wheels for Python 3.11, 3.12, 3.13, 3.14..."
echo ""

# Build wheels for each Python version
for i in "${!PYTHON_VERSIONS[@]}"; do
    version="${PYTHON_VERSIONS[$i]}"
    venv="${VENV_NAMES[$i]}"
    py_version="3.${version#3}"

    echo -e "${BLUE}Building for Python ${py_version}...${NC}"

    # Check if venv exists
    if [ ! -d "$venv" ]; then
        echo -e "${RED}✗${NC} Virtual environment $venv not found"
        echo "   Run ./scripts/setup_dev_env.sh first"
        exit 1
    fi

    # Activate venv and build
    source "$venv/bin/activate"

    # Ensure build tools are installed
    pip install -q --upgrade build scikit-build-core pybind11

    # Build wheel
    if python -m build --wheel; then
        echo -e "${GREEN}✓${NC} Python ${py_version} wheel built"
    else
        echo -e "${RED}✗${NC} Failed to build Python ${py_version} wheel"
        deactivate
        exit 1
    fi

    deactivate
    echo ""
done

# List built wheels
echo "Built wheels (linux_x86_64):"
ls -lh dist/*-linux_x86_64.whl 2>/dev/null || echo "  None found"
echo ""

# Convert to manylinux
echo "Converting to manylinux format..."
echo ""

# Check if auditwheel is available
if ! command -v auditwheel &> /dev/null; then
    echo -e "${RED}Error: auditwheel not installed${NC}"
    echo "Install with: pip install auditwheel"
    exit 1
fi

# Repair each wheel
for wheel in dist/*-linux_x86_64.whl; do
    if [ -f "$wheel" ]; then
        echo -ne "  Converting $(basename "$wheel")... "
        if auditwheel repair "$wheel" -w dist/ &> /tmp/auditwheel.log; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗ Failed${NC}"
            echo "    Check /tmp/auditwheel.log for details"
            exit 1
        fi
    fi
done
echo ""

# Clean up linux_x86_64 wheels (keep only manylinux)
echo "Cleaning up linux_x86_64 wheels..."
rm -f dist/*-linux_x86_64.whl
echo -e "${GREEN}✓${NC} Removed non-manylinux wheels"
echo ""

# Show final build results
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Built packages:"
echo ""

# Source distribution
if ls dist/*.tar.gz &> /dev/null; then
    echo "Source distribution:"
    ls -lh dist/*.tar.gz | awk '{printf "  %-50s %6s\n", $9, $5}'
    echo ""
fi

# Wheels
if ls dist/*manylinux*.whl &> /dev/null; then
    echo "Wheels (manylinux):"
    ls -lh dist/*manylinux*.whl | awk '{printf "  %-50s %6s\n", $9, $5}'
    echo ""
else
    echo -e "${RED}No manylinux wheels found!${NC}"
    exit 1
fi

# Calculate total size
TOTAL_SIZE=$(du -sh dist/ | cut -f1)
echo "Total size: $TOTAL_SIZE"
echo ""

# Verify all wheels present
EXPECTED_COUNT=4  # 4 Python versions
ACTUAL_COUNT=$(ls dist/*manylinux*.whl 2>/dev/null | wc -l)

if [ "$ACTUAL_COUNT" -ne "$EXPECTED_COUNT" ]; then
    echo -e "${YELLOW}Warning: Expected $EXPECTED_COUNT wheels, found $ACTUAL_COUNT${NC}"
else
    echo -e "${GREEN}✓${NC} All $EXPECTED_COUNT wheels built successfully"
fi
echo ""

echo "Next steps:"
echo "  Test locally:  pip install dist/pysphorb-${VERSION}-cp312-cp312-manylinux*.whl"
echo "  Upload to TestPyPI: ./scripts/upload_testpypi.sh"
echo "  Upload to PyPI:     ./scripts/upload_pypi.sh"
echo ""
