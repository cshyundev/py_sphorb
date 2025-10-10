#include "SPHORB.h"

extern "C" {
    cv::SPHORB* SPHORB_create(int nfeatures, int nlevels, int b) {
        return new cv::SPHORB(nfeatures, nlevels, b);
    }

    void SPHORB_detect(cv::SPHORB* sphorb, cv::Mat* image, std::vector<cv::KeyPoint>* keypoints) {
        sphorb->detect(*image, *keypoints);
    }

    void SPHORB_compute(cv::SPHORB* sphorb, cv::Mat* image, std::vector<cv::KeyPoint>* keypoints, cv::Mat* descriptors) {
        sphorb->compute(*image, *keypoints, *descriptors);
    }

    void SPHORB_destroy(cv::SPHORB* sphorb) {
        delete sphorb;
    }
}
