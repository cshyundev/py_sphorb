/*
	AUTHOR:
	Qiang Zhao, email: qiangzhao@tju.edu.cn
	Copyright (C) 2014 Tianjin University
	School of Computer Software
	School of Computer Science and Technology

	LICENSE:
	SPHORB is distributed under the GNU General Public License.  For information on 
	commercial licensing, please contact the authors at the contact address below.

	REFERENCE:
	Qiang Zhao, Wei Feng, Liang Wan and Jiawan Zhang. SPHORB: A Fast and Robust Binary 
	Feature on the Sphere. International Journal of Computer Vision, preprint, 2014.
*/

#ifndef _DETECTOR_H
#define _DETECTOR_H

#include <opencv2/opencv.hpp>
#include <vector>

using namespace std;
using namespace cv;

typedef cv::Point xy;
typedef unsigned char sphorb_byte;

xy* sfast_corner_detect(const sphorb_byte* im, const sphorb_byte* mask, int xsize, int xstride, int ysize, int barrier, int* num);

int sfast_corner_score(const sphorb_byte* im, const int pixel[], int bstart);

int* sfastScore(const unsigned char* i, int stride, xy* corners, int num_corners, int b);

void sfastNonmaxSuppression(const xy* corners, const int* scores, int num_corners, vector<KeyPoint>& kps, int partIndex);

#endif