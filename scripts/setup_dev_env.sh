#!/bin/bash
# Setup development environment for PySPHORB
# This script creates virtual environments for multiple Python versions

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "PySPHORB Development Environment Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo -e "${RED}Error: uv is not installed${NC}"
    echo "Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

echo -e "${GREEN}✓${NC} uv is installed"
echo ""

# Python versions to install
PYTHON_VERSIONS=("3.11" "3.12" "3.13" "3.14")

echo "Installing Python versions..."
for version in "${PYTHON_VERSIONS[@]}"; do
    echo -ne "  Installing Python ${version}... "
    if uv python install "$version" &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}Already installed${NC}"
    fi
done
echo ""

# List installed Python versions
echo "Installed Python versions:"
uv python list
echo ""

# Create virtual environments
cd "$PROJECT_ROOT"

echo "Creating virtual environments..."
for version in "${PYTHON_VERSIONS[@]}"; do
    venv_name=".venv-py${version//./}"

    if [ -d "$venv_name" ]; then
        echo -e "  ${YELLOW}!${NC} $venv_name already exists, skipping..."
        continue
    fi

    echo -ne "  Creating $venv_name... "
    if uv venv "$venv_name" --python "$version" &> /dev/null; then
        echo -e "${GREEN}✓${NC}"

        # Ensure pip is installed
        if [ ! -f "$venv_name/bin/pip" ]; then
            $venv_name/bin/python -m ensurepip --upgrade &> /dev/null
        fi

        # Install build dependencies
        $venv_name/bin/python -m pip install -q build scikit-build-core pybind11 twine auditwheel patchelf
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
done
echo ""

# Create main development venv (Python 3.12)
MAIN_VENV=".venv"
if [ ! -d "$MAIN_VENV" ]; then
    echo "Creating main development environment (.venv with Python 3.12)..."
    uv venv "$MAIN_VENV" --python 3.12

    # Ensure pip is installed
    if [ ! -f "$MAIN_VENV/bin/pip" ]; then
        $MAIN_VENV/bin/python -m ensurepip --upgrade &> /dev/null
    fi

    echo "Installing development dependencies..."
    $MAIN_VENV/bin/python -m pip install -q -e ".[dev]"

    echo -e "${GREEN}✓${NC} Main development environment ready"
else
    echo -e "${YELLOW}!${NC} Main development environment (.venv) already exists"
fi
echo ""

# Print usage instructions
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "To activate main development environment:"
echo "  source .venv/bin/activate"
echo ""
echo "To activate specific Python version:"
echo "  source .venv-py311/bin/activate  # Python 3.11"
echo "  source .venv-py312/bin/activate  # Python 3.12"
echo "  source .venv-py313/bin/activate  # Python 3.13"
echo "  source .venv-py314/bin/activate  # Python 3.14"
echo ""
echo "Next steps:"
echo "  1. Build wheels: ./scripts/build_wheels.sh"
echo "  2. Upload to TestPyPI: ./scripts/upload_testpypi.sh"
echo "  3. Upload to PyPI: ./scripts/upload_pypi.sh"
echo ""
