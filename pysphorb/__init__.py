"""
PySPHORB - Python bindings for SPHORB feature detector

SPHORB is a fast and robust binary feature detector optimized for spherical
and panoramic images.
"""

import os
import sys
from pathlib import Path
from .pysphorb import SPHORB as _SPHORB, ratioTest

__version__ = "0.1.5"

# Get the package directory
_package_dir = Path(__file__).parent

class SPHORB:
    """Wrapper for SPHORB that handles data file paths"""

    def __init__(self, nfeatures=500, nlevels=7, b=20):
        """Initialize SPHORB detector

        Parameters:
          nfeatures: Maximum number of features to detect (default: 500)
          nlevels: Number of pyramid levels (default: 7)
          b: Barrier threshold (default: 20)
        """
        # Save current directory and change to package directory
        self._orig_cwd = os.getcwd()
        os.chdir(_package_dir)
        try:
            self._sphorb = _SPHORB(nfeatures, nlevels, b)
        finally:
            os.chdir(self._orig_cwd)

    def detectAndCompute(self, image):
        """Detect keypoints and compute descriptors"""
        os.chdir(_package_dir)
        try:
            return self._sphorb.detectAndCompute(image)
        finally:
            os.chdir(self._orig_cwd)

    def detect(self, image):
        """Detect keypoints only"""
        os.chdir(_package_dir)
        try:
            return self._sphorb.detect(image)
        finally:
            os.chdir(self._orig_cwd)

    def descriptorSize(self):
        """Get descriptor size in bytes"""
        return self._sphorb.descriptorSize()

    def descriptorType(self):
        """Get descriptor type"""
        return self._sphorb.descriptorType()

__all__ = ["SPHORB", "ratioTest"]
