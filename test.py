#!/usr/bin/env python3
import numpy as np
import cv2
import pysphorb

def main():
    ratio = 0.75

    # Initialize SPHORB detector (same as C++ example1.cpp line 28)
    sorb = pysphorb.SPHORB()

    # Load images (same as C++ example1.cpp lines 30-31)
    img1 = cv2.imread("Image/1_1.jpg")
    img2 = cv2.imread("Image/1_2.jpg")

    if img1 is None or img2 is None:
        print("Error: Could not load images")
        return

    # Detect and compute features (same as C++ example1.cpp lines 39-40)
    kPoint1, descriptors1 = sorb.detectAndCompute(img1)
    kPoint2, descriptors2 = sorb.detectAndCompute(img2)

    print(f"Keypoint1: {len(kPoint1)}, Keypoint2: {len(kPoint2)}")

    # Match descriptors using BFMatcher (same as C++ example1.cpp lines 44-49)
    matcher = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=False)

    # knnMatch (k=2 for ratio test)
    dupMatches = matcher.knnMatch(descriptors1, descriptors2, k=2)

    # Apply ratio test
    matches = []
    for m_n in dupMatches:
        if len(m_n) == 2:
            m, n = m_n
            if m.distance < ratio * n.distance:
                matches.append(m)

    print(f"Matches: {len(matches)}")

    # Convert keypoints from tuple format to cv2.KeyPoint
    cv_kp1 = [cv2.KeyPoint(x=kp[0], y=kp[1], size=kp[2], angle=kp[3],
                            response=kp[4], octave=kp[5]) for kp in kPoint1]
    cv_kp2 = [cv2.KeyPoint(x=kp[0], y=kp[1], size=kp[2], angle=kp[3],
                            response=kp[4], octave=kp[5]) for kp in kPoint2]

    # Draw matches (same as C++ example1.cpp lines 53-54)
    imgMatches = cv2.drawMatches(img1, cv_kp1, img2, cv_kp2, matches, None,
                                  flags=cv2.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS)

    # Save result (same as C++ example1.cpp line 56)
    cv2.imwrite("2_matches.jpg", imgMatches)
    print("Result saved to 1_matches.jpg")

if __name__ == "__main__":
    main()
