#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/features2d.hpp>
#include <iostream>
#include "SPHORB.h"

using namespace cv;
using namespace std;

int main(int argc, char** argv)
{
    if (argc != 2)
    {
        cout << "Usage: " << argv[0] << " <image_path>" << endl;
        return -1;
    }

    // Load the image
    Mat image = imread(argv[1], IMREAD_GRAYSCALE);
    if (image.empty())
    {
        cout << "Could not open or find the image!" << endl;
        return -1;
    }

    // Initialize the SPHORB feature detector
    cv::SPHORB sphorb(500,7,20);

    // Detect keypoints
    vector<cv::KeyPoint> keypoints;
    sphorb(image, noArray(), keypoints);

    printf("num of keypoints %ld\n",keypoints.size());

    // Draw the keypoints on the image
    Mat outputImage;
    drawKeypoints(image, keypoints, outputImage, Scalar::all(-1), DrawMatchesFlags::DEFAULT);

    // Show the output image with keypoints
    imshow("SPHORB Keypoints", outputImage);
    waitKey(0);

    return 0;
}
