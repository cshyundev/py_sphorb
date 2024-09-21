#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/numpy.h>
#include <opencv2/core.hpp>
#include <opencv2/features2d.hpp>
#include <opencv2/imgproc.hpp>
#include "SPHORB.h"
#include "detector.h"
#include "pfm.h"

namespace py = pybind11;
using namespace cv;

PYBIND11_MODULE(py_sphorb, m) {
    // Bind SPHORB class
    py::class_<SPHORB, Feature2D>(m, "SPHORB")
        .def(py::init<int, int, int>(), py::arg("nfeatures") = 500, py::arg("nlevels") = 7, py::arg("b") = 20)
        .def("descriptorSize", &SPHORB::descriptorSize)
        .def("descriptorType", &SPHORB::descriptorType)
        
        // Binding the first operator() overload
        .def("__call__",
             static_cast<void (SPHORB::*)(InputArray, InputArray, std::vector<cv::KeyPoint>&) const>(
                 &SPHORB::operator()),
             py::arg("image"), py::arg("mask"), py::arg("keypoints"))
        
        // Binding the second operator() overload
        .def("__call__",
             static_cast<void (SPHORB::*)(InputArray, InputArray, std::vector<cv::KeyPoint>&, OutputArray, bool) const>(
                 &SPHORB::operator()),
             py::arg("image"), py::arg("mask"), py::arg("keypoints"), py::arg("descriptors"), py::arg("useProvidedKeypoints") = false)
        
        // You can also add more bindings as needed for other SPHORB methods
        .def("detectAndCompute",
             [](SPHORB &self, py::array_t<uint8_t> image, py::array_t<uint8_t> mask, std::vector<KeyPoint>& keypoints) {
                 cv::Mat img(Size(image.shape(1), image.shape(0)), CV_8UC3, (uint8_t*)image.data());
                 cv::Mat msk(Size(mask.shape(1), mask.shape(0)), CV_8UC1, (uint8_t*)mask.data());
                 cv::Mat descriptors;
                 self(img, msk, keypoints, descriptors);
                 return descriptors;
             });
}
