/*
	AUTHOR:
	Qiang Zhao, email: qiangzhao@tju.edu.cn
	Copyright (C) 2015 Tianjin University
	School of Computer Software
	School of Computer Science and Technology

	LICENSE:
	SPHORB is distributed under the GNU General Public License. For information on 
	commercial licensing, please contact the authors at the contact address below.

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

	UPDATE:
	OpenCV version updated to ensure compatibility with modern libraries and optimizations.
	Changes made to maintain original functionality while upgrading to the latest stable 
	OpenCV version (version 4.3).
	Modifications performed by Sehyun Cha, email: cshyundev@gmail.com, 2024.
*/

#ifndef _SPHORB_H
#define _SPHORB_H

#include <opencv2/core.hpp>       
#include <opencv2/features2d.hpp> 
#include <opencv2/imgproc.hpp>    
#include <vector>
#include <stdio.h>

using namespace cv;

namespace cv
{
	class CV_EXPORTS SPHORB : public cv::Feature2D
	{
	public:
		enum { kBytes = 32, SFAST_EDGE = 3, SPHORB_EDGE = 15};

		explicit SPHORB(int nfeatures = 500, int nlevels = 7, int b=20);
		~SPHORB();

		// returns the descriptor size in bytes
		int descriptorSize() const override;  
		// returns the descriptor type
		int descriptorType() const override;  

		// Compute the ORB features and descriptors on an image 
		void operator()(InputArray image, InputArray mask, std::vector<cv::KeyPoint>& keypoints) const;  
		void operator()(InputArray image, InputArray mask, std::vector<cv::KeyPoint>& keypoints,
                     OutputArray descriptors, bool useProvidedKeypoints=false ) const;  

	protected:
		int barrier;
		int nfeatures;
		int nlevels;

		void computeImpl( const Mat& image, std::vector<cv::KeyPoint>& keypoints, Mat& descriptors ) const;  
		void detectImpl( const Mat& image, std::vector<cv::KeyPoint>& keypoints, const Mat& mask=Mat() ) const;  
	};
}

#endif
