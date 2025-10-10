# PySPHORB

Python bindings for SPHORB (Spherical ORB), a fast and robust binary feature detector optimized for spherical and panoramic images.

## About

SPHORB is a feature detection and description method designed specifically for 360° panoramic images using a geodesic grid representation. It provides scale and rotation invariance while avoiding expensive spherical harmonics calculations.

This package provides Python bindings for the original C++ implementation, enabling easy integration with modern computer vision workflows using NumPy and OpenCV.

## Installation

### Requirements

- Python >= 3.11
- NumPy >= 2.0
- OpenCV >= 4.0
- CMake >= 3.15
- C++17 compatible compiler

### From Source

```bash
pip install git+https://github.com/cshyundev/py_sphorb.git
```

Or clone and install locally:

```bash
git clone https://github.com/cshyundev/py_sphorb.git
cd py_sphorb
pip install .
```

## Quick Start

```python
import cv2
import pysphorb

# Initialize detector
detector = pysphorb.SPHORB()

# Load panoramic image
img = cv2.imread("panorama.jpg")

# Detect keypoints and compute descriptors
keypoints, descriptors = detector.detectAndCompute(img)

print(f"Detected {len(keypoints)} keypoints")
print(f"Descriptor shape: {descriptors.shape}")  # (N, 32)
```

## Usage Example

### Feature Matching

```python
import cv2
import pysphorb

# Initialize detector with custom parameters
detector = pysphorb.SPHORB(nfeatures=500, nlevels=7, b=20)

# Load two panoramic images
img1 = cv2.imread("pano1.jpg")
img2 = cv2.imread("pano2.jpg")

# Detect and compute descriptors
kp1, desc1 = detector.detectAndCompute(img1)
kp2, desc2 = detector.detectAndCompute(img2)

# Match using BFMatcher with Hamming distance
matcher = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=False)
matches = matcher.knnMatch(desc1, desc2, k=2)

# Apply Lowe's ratio test
good_matches = []
for m_n in matches:
    if len(m_n) == 2:
        m, n = m_n
        if m.distance < 0.75 * n.distance:
            good_matches.append(m)

print(f"Found {len(good_matches)} good matches")
```

### Visualization

```python
# Convert keypoints to cv2.KeyPoint format for visualization
cv_kp1 = [cv2.KeyPoint(x=kp[0], y=kp[1], size=kp[2], angle=kp[3],
                        response=kp[4], octave=kp[5]) for kp in kp1]
cv_kp2 = [cv2.KeyPoint(x=kp[0], y=kp[1], size=kp[2], angle=kp[3],
                        response=kp[4], octave=kp[5]) for kp in kp2]

# Draw matches
result = cv2.drawMatches(img1, cv_kp1, img2, cv_kp2, good_matches, None,
                         flags=cv2.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS)
cv2.imwrite("matches.jpg", result)
```

## API Reference

### `SPHORB(nfeatures=500, nlevels=7, b=20)`

Initialize SPHORB detector.

**Parameters:**
- `nfeatures` (int): Maximum number of features to detect (default: 500)
- `nlevels` (int): Number of pyramid levels (default: 7)
- `b` (int): Barrier threshold for feature detection (default: 20)

### `detectAndCompute(image)`

Detect keypoints and compute descriptors.

**Parameters:**
- `image` (numpy.ndarray): Input image (grayscale or BGR)

**Returns:**
- `keypoints` (list): List of tuples `(x, y, size, angle, response, octave)`
- `descriptors` (numpy.ndarray): Binary descriptors of shape `(N, 32)`

### `detect(image)`

Detect keypoints only (no descriptors).

**Parameters:**
- `image` (numpy.ndarray): Input image (grayscale or BGR)

**Returns:**
- `keypoints` (list): List of tuples `(x, y, size, angle, response, octave)`

### `descriptorSize()`

Returns the descriptor size in bytes (always 32 for SPHORB).

### `descriptorType()`

Returns the OpenCV descriptor type code.

## Original Paper

This implementation is based on the following paper:

**SPHORB: A Fast and Robust Binary Feature on the Sphere**
Qiang Zhao, Wei Feng, Liang Wan, Jiawan Zhang
*International Journal of Computer Vision*, Volume 113, Number 2, Pages 143-159, June 2015

**Links:**
- Paper: https://cic.tju.edu.cn/faculty/lwan/paper/SPHORB/SPHORB.html
- Original C++ Code: Copyright (C) 2015 Tianjin University

### Citation

If you use this code in your research, please cite:

```bibtex
@article{zhao2015sphorb,
  title={SPHORB: A Fast and Robust Binary Feature on the Sphere},
  author={Zhao, Qiang and Feng, Wei and Wan, Liang and Zhang, Jiawan},
  journal={International Journal of Computer Vision},
  volume={113},
  number={2},
  pages={143--159},
  year={2015},
  publisher={Springer}
}
```

## License

This project inherits the GNU General Public License from the original SPHORB implementation.
For commercial licensing inquiries, please contact the original authors.

## Credits

- **Original Algorithm & C++ Implementation**: Qiang Zhao (qiangzhao@tju.edu.cn), Tianjin University
- **Python Bindings**: Created using [pybind11](https://github.com/pybind/pybind11)
- **Contributors**: [Your contributions are welcome!](https://github.com/cshyundev/py_sphorb/issues)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
