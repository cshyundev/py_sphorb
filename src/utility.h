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

#ifndef _UTILITY_H
#define _UTILITY_H

#include <vector>
#include <opencv2/opencv.hpp>
using namespace cv;
using namespace std;

typedef vector<DMatch> Matches;
void ratioTest(const std::vector<Matches>& knMatches, float maxRatio, Matches& goodMatches);

void drawMatches(const Mat& img1, const vector<KeyPoint>& keypoints1,
	const Mat& img2, const vector<KeyPoint>& keypoints2,
	const vector<DMatch>& matches1to2, Mat& outImg, const Scalar& matchColor, const Scalar& singlePointColor,
	const vector<char>& matchesMask, cv::DrawMatchesFlags flags , bool vertical);

#endif