/*
    AUTHOR:
    Qiang Zhao, email: qiangzhao@tju.edu.cn
    Copyright (C) 2015 Tianjin University
    School of Computer Software
    School of Computer Science and Technology

    LICENSE:
    SPHORB is distributed under the GNU General Public License. 
    For information on commercial licensing, please contact the authors.

    REFERENCE:
    @article{zhao-SPHORB,
    author   = {Qiang Zhao and Wei Feng and Liang Wan and Jiawan Zhang},
    title    = {SPHORB: A Fast and Robust Binary Feature on the Sphere},
    journal  = {International Journal of Computer Vision},
    year     = {2015},
    volume   = {113},
    number   = {2},
    pages    = {143-159},
    }
*/

#ifndef SPHORB_DETECTOR_H
#define SPHORB_DETECTOR_H

#include <opencv2/opencv.hpp>
#include <vector>

typedef cv::Point xy; // 2D point type using OpenCV's Point
typedef unsigned char byte; // Alias for unsigned char

/**
 * Detects corners in an image using FAST algorithm.
 * @param im Image data pointer.
 * @param mask Mask data pointer.
 * @param xsize Image width.
 * @param xstride Stride (bytes per row) of the image.
 * @param ysize Image height.
 * @param barrier Threshold for corner detection.
 * @param num Output parameter for number of detected corners.
 * @return Array of detected corner points.
 */
xy* sfast_corner_detect(const byte* im, const byte* mask, int xsize, int xstride, int ysize, int barrier, int* num);

/**
 * Computes the corner score for a given position in the image.
 * @param im Image data pointer.
 * @param pixel Pixel pattern for corner score computation.
 * @param bstart Initial score value.
 * @return Corner score.
 */
int sfast_corner_score(const byte* im, const int pixel[], int bstart);

/**
 * Computes the scores for all detected corners in the image.
 * @param i Image data pointer.
 * @param stride Stride (bytes per row) of the image.
 * @param corners Detected corner points.
 * @param num_corners Number of detected corners.
 * @param b Threshold for corner detection.
 * @return Array of corner scores.
 */
int* sfastScore(const byte* i, int stride, xy* corners, int num_corners, int b);

/**
 * Applies non-maximum suppression to eliminate weaker corners.
 * @param corners Detected corner points.
 * @param scores Corner scores.
 * @param num_corners Number of detected corners.
 * @param kps Output vector of keypoints after non-maximum suppression.
 * @param partIndex Index of the current image part.
 */
void sfastNonmaxSuppression(const xy* corners, const int* scores, int num_corners, std::vector<cv::KeyPoint>& kps, int partIndex);

#endif // SPHORB_DETECTOR_H
