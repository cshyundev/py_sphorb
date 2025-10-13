#!/usr/bin/env python3
"""
Feature Visualization Script

This script reads image frames from a directory, extracts features using
SPHORBDetector or ORBDetector, and visualizes them using Rerun.

Usage:
    python scripts/visualize_features.py --path <image_directory> --detector sphorb
    python scripts/visualize_features.py --path <image_directory> --detector orb --num_features 2000
"""

import argparse
import sys
from pathlib import Path
from typing import List, Tuple

import cv2
import numpy as np
import rerun as rr
import pysphorb


class FeatureDetector:
    """Base class for feature detectors"""
    def detect_and_compute(self, image):
        raise NotImplementedError


class SPHORBDetector(FeatureDetector):
    """Wrapper for pysphorb.SPHORB"""
    def __init__(self, num_features=500):
        self.detector = pysphorb.SPHORB(nfeatures=num_features)

    def detect_and_compute(self, image):
        keypoints_raw, descriptors = self.detector.detectAndCompute(image)
        # Convert tuple keypoints to cv2.KeyPoint objects
        keypoints = [cv2.KeyPoint(x=kp[0], y=kp[1], size=kp[2], angle=kp[3],
                                   response=kp[4], octave=kp[5]) for kp in keypoints_raw]
        return keypoints, descriptors


class ORBDetector(FeatureDetector):
    """Wrapper for cv2.ORB"""
    def __init__(self, num_features=500):
        self.detector = cv2.ORB_create(nfeatures=num_features)

    def detect_and_compute(self, image):
        return self.detector.detectAndCompute(image, None)


def load_images_from_directory(image_dir: Path) -> List[Tuple[Path, np.ndarray]]:
    """
    Load all images from a directory.

    Args:
        image_dir: Path to directory containing images

    Returns:
        List of (path, image) tuples
    """
    # Support common image formats
    image_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif'}

    image_files = []
    for ext in image_extensions:
        image_files.extend(image_dir.glob(f'*{ext}'))
        image_files.extend(image_dir.glob(f'*{ext.upper()}'))

    # Sort by filename
    image_files = sorted(image_files)

    if not image_files:
        raise ValueError(f"No images found in directory: {image_dir}")

    print(f"Found {len(image_files)} images")

    # Load images
    images = []
    for img_path in image_files:
        img = cv2.imread(str(img_path))
        if img is None:
            print(f"Warning: Could not read {img_path}, skipping")
            continue
        images.append((img_path, img))

    print(f"Successfully loaded {len(images)} images")
    return images


def create_detector(detector_type: str, num_features: int) -> FeatureDetector:
    """
    Create a feature detector based on type.

    Args:
        detector_type: 'sphorb' or 'orb'
        num_features: Maximum number of features to detect

    Returns:
        FeatureDetector instance
    """
    if detector_type.lower() == 'sphorb':
        print(f"Using SPHORBDetector with {num_features} features")
        return SPHORBDetector(num_features=num_features)
    elif detector_type.lower() == 'orb':
        print(f"Using ORBDetector with {num_features} features")
        return ORBDetector(num_features=num_features)
    else:
        raise ValueError(f"Unknown detector type: {detector_type}. Use 'sphorb' or 'orb'")


def visualize_with_rerun(
    images: List[Tuple[Path, np.ndarray]],
    detector: FeatureDetector,
    recording_name: str = "feature_visualization",
    target_resolution: Tuple[int, int] = None
):
    """
    Visualize images and their features using Rerun.

    Args:
        images: List of (path, image) tuples
        detector: Feature detector to use
        recording_name: Name for the Rerun recording
        target_resolution: Optional (width, height) to resize images to
    """
    # Initialize Rerun
    rr.init(recording_name, spawn=True)

    print(f"\nProcessing {len(images)} images...")
    if target_resolution:
        print(f"Resizing all images to {target_resolution[0]}x{target_resolution[1]}")

    for idx, (img_path, img) in enumerate(images):
        print(f"Processing {idx + 1}/{len(images)}: {img_path.name}")

        # Resize if target resolution specified
        if target_resolution:
            original_size = f"{img.shape[1]}x{img.shape[0]}"
            img = cv2.resize(img, target_resolution, interpolation=cv2.INTER_AREA)
            print(f"  Resized from {original_size} to {target_resolution[0]}x{target_resolution[1]}")

        # Log the original image
        # Convert BGR to RGB for visualization
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        rr.log("image", rr.Image(img_rgb))

        # Detect features
        keypoints, descriptors = detector.detect_and_compute(img)

        print(f"  Detected {len(keypoints)} keypoints")

        if len(keypoints) == 0:
            continue

        # Extract keypoint positions and properties
        positions = np.array([[kp.pt[0], kp.pt[1]] for kp in keypoints], dtype=np.float32)
        sizes = np.array([kp.size for kp in keypoints], dtype=np.float32)
        responses = np.array([kp.response for kp in keypoints], dtype=np.float32)

        # Normalize responses for coloring (0-1 range)
        if responses.max() > responses.min():
            responses_norm = (responses - responses.min()) / (responses.max() - responses.min())
        else:
            responses_norm = np.ones_like(responses)

        # Create colors based on response strength (green to red gradient)
        # Low response = green (weak), high response = red (strong)
        colors = np.zeros((len(keypoints), 3), dtype=np.uint8)
        colors[:, 0] = (responses_norm * 255).astype(np.uint8)  # Red channel
        colors[:, 1] = ((1 - responses_norm) * 255).astype(np.uint8)  # Green channel
        colors[:, 2] = 0  # Blue channel

        # Log keypoints as 2D points
        rr.log(
            "keypoints",
            rr.Points2D(
                positions,
                radii=sizes / 2,  # Size is diameter, radius is half
                colors=colors,
                labels=[f"kp_{i}" for i in range(len(keypoints))]
            )
        )

        # Log statistics
        rr.log("stats/num_keypoints", rr.Scalars(len(keypoints)))
        rr.log("stats/mean_response", rr.Scalars(float(responses.mean())))
        rr.log("stats/max_response", rr.Scalars(float(responses.max())))
        rr.log("stats/mean_size", rr.Scalars(float(sizes.mean())))

        # Optionally draw keypoints on image for comparison
        img_with_keypoints = cv2.drawKeypoints(
            img,
            keypoints,
            None,
            flags=cv2.DRAW_MATCHES_FLAGS_DRAW_RICH_KEYPOINTS
        )
        img_with_keypoints_rgb = cv2.cvtColor(img_with_keypoints, cv2.COLOR_BGR2RGB)
        rr.log("image_with_keypoints", rr.Image(img_with_keypoints_rgb))

    print("\nVisualization complete!")
    print("Rerun viewer should be open. You can close the window when done.")


def main():
    parser = argparse.ArgumentParser(
        description="Visualize features extracted from image frames using Rerun"
    )

    parser.add_argument(
        "--path",
        type=str,
        required=True,
        help="Path to directory containing image frames"
    )

    parser.add_argument(
        "--detector",
        type=str,
        choices=['sphorb', 'orb'],
        default='sphorb',
        help="Feature detector to use: 'sphorb' or 'orb' (default: sphorb)"
    )

    parser.add_argument(
        "--num_features",
        type=int,
        default=1000,
        help="Maximum number of features to detect per image (default: 1000)"
    )

    parser.add_argument(
        "--recording_name",
        type=str,
        default="feature_visualization",
        help="Name for the Rerun recording (default: feature_visualization)"
    )

    parser.add_argument(
        "--target_resolution",
        type=str,
        default=None,
        help="Target resolution to resize images to, format: WIDTHxHEIGHT (e.g., 640x320). "
             "If not specified, original resolution is used."
    )

    args = parser.parse_args()

    # Parse target resolution
    target_resolution = None
    if args.target_resolution:
        try:
            width, height = map(int, args.target_resolution.lower().split('x'))
            if width <= 0 or height <= 0:
                raise ValueError("Resolution must be positive")
            target_resolution = (width, height)
        except ValueError as e:
            print(f"Error: Invalid resolution format '{args.target_resolution}'. "
                  f"Use format WIDTHxHEIGHT (e.g., 640x320)")
            sys.exit(1)

    # Validate path
    image_dir = Path(args.path)
    if not image_dir.exists():
        print(f"Error: Directory does not exist: {image_dir}")
        sys.exit(1)

    if not image_dir.is_dir():
        print(f"Error: Path is not a directory: {image_dir}")
        sys.exit(1)

    print("=" * 60)
    print("Feature Visualization Script")
    print("=" * 60)
    print(f"Image directory: {image_dir}")
    print(f"Detector: {args.detector}")
    print(f"Max features: {args.num_features}")
    print(f"Target resolution: {target_resolution[0]}x{target_resolution[1]}" if target_resolution else "Original")
    print(f"Recording name: {args.recording_name}")
    print("=" * 60 + "\n")

    try:
        # Load images
        images = load_images_from_directory(image_dir)

        # Create detector
        detector = create_detector(args.detector, args.num_features)

        # Visualize with Rerun
        visualize_with_rerun(images, detector, args.recording_name, target_resolution)

    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
