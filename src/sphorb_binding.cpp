#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>
#include <opencv2/core.hpp>
#include <opencv2/core/mat.hpp>
#include <opencv2/imgcodecs.hpp>
#include "src/SPHORB.h"
#include "src/utility.h"

namespace py = pybind11;

// Convert numpy array to cv::Mat
cv::Mat numpy_to_mat(py::array_t<uint8_t> input) {
    py::buffer_info buf = input.request();

    if (buf.ndim == 2) {
        // Grayscale image
        cv::Mat mat(buf.shape[0], buf.shape[1], CV_8UC1, (void*)buf.ptr);
        return mat.clone();
    } else if (buf.ndim == 3 && buf.shape[2] == 3) {
        // Color image (BGR)
        cv::Mat mat(buf.shape[0], buf.shape[1], CV_8UC3, (void*)buf.ptr);
        return mat.clone();
    } else {
        throw std::runtime_error("Input array must be 2D (grayscale) or 3D with 3 channels (BGR)");
    }
}

// Convert cv::Mat to numpy array (for descriptors)
py::array_t<uint8_t> mat_to_numpy(const cv::Mat& mat) {
    if (mat.type() != CV_8UC1) {
        throw std::runtime_error("Only CV_8UC1 matrices are supported for descriptors");
    }

    return py::array_t<uint8_t>(
        {mat.rows, mat.cols},
        {sizeof(uint8_t) * mat.cols, sizeof(uint8_t)},
        reinterpret_cast<const uint8_t*>(mat.data)
    );
}

// Wrapper class for SPHORB
class PySPHORB {
private:
    cv::SPHORB sphorb;

public:
    PySPHORB(int nfeatures = 500, int nlevels = 7, int b = 20)
        : sphorb(nfeatures, nlevels, b) {}

    // Detect and compute keypoints and descriptors
    py::tuple detectAndCompute(py::array_t<uint8_t> image) {
        cv::Mat img = numpy_to_mat(image);
        std::vector<cv::KeyPoint> keypoints;
        cv::Mat descriptors;

        sphorb(img, cv::Mat(), keypoints, descriptors);

        // Convert keypoints to Python list of tuples (x, y, size, angle, response, octave)
        py::list kp_list;
        for (const auto& kp : keypoints) {
            kp_list.append(py::make_tuple(
                kp.pt.x, kp.pt.y, kp.size, kp.angle, kp.response, kp.octave
            ));
        }

        // Convert descriptors to numpy array
        py::array_t<uint8_t> desc_array = mat_to_numpy(descriptors);

        return py::make_tuple(kp_list, desc_array);
    }

    // Detect keypoints only
    py::list detect(py::array_t<uint8_t> image) {
        cv::Mat img = numpy_to_mat(image);
        std::vector<cv::KeyPoint> keypoints;

        sphorb(img, cv::Mat(), keypoints);

        // Convert keypoints to Python list
        py::list kp_list;
        for (const auto& kp : keypoints) {
            kp_list.append(py::make_tuple(
                kp.pt.x, kp.pt.y, kp.size, kp.angle, kp.response, kp.octave
            ));
        }

        return kp_list;
    }

    int descriptorSize() const {
        return sphorb.descriptorSize();
    }

    int descriptorType() const {
        return sphorb.descriptorType();
    }
};

// Utility function: ratioTest
py::list ratioTest(const py::list& knMatches, float maxRatio) {
    std::vector<Matches> dupMatches;

    // Convert Python list to C++ vector
    for (auto item : knMatches) {
        py::list match_list = item.cast<py::list>();
        Matches matches;
        for (auto m : match_list) {
            py::tuple match_tuple = m.cast<py::tuple>();
            cv::DMatch dm;
            dm.queryIdx = match_tuple[0].cast<int>();
            dm.trainIdx = match_tuple[1].cast<int>();
            dm.distance = match_tuple[2].cast<float>();
            matches.push_back(dm);
        }
        dupMatches.push_back(matches);
    }

    // Apply ratio test
    Matches goodMatches;
    ::ratioTest(dupMatches, maxRatio, goodMatches);

    // Convert back to Python list
    py::list result;
    for (const auto& dm : goodMatches) {
        result.append(py::make_tuple(dm.queryIdx, dm.trainIdx, dm.distance));
    }

    return result;
}

// pybind11 module definition
PYBIND11_MODULE(pysphorb, m) {
    m.doc() = "Python bindings for SPHORB feature detector";

    py::class_<PySPHORB>(m, "SPHORB")
        .def(py::init<int, int, int>(),
             py::arg("nfeatures") = 500,
             py::arg("nlevels") = 7,
             py::arg("b") = 20,
             "Initialize SPHORB detector\n\n"
             "Parameters:\n"
             "  nfeatures: Maximum number of features to detect (default: 500)\n"
             "  nlevels: Number of pyramid levels (default: 7)\n"
             "  b: Barrier threshold (default: 20)")
        .def("detectAndCompute", &PySPHORB::detectAndCompute,
             py::arg("image"),
             "Detect keypoints and compute descriptors\n\n"
             "Parameters:\n"
             "  image: Input image as numpy array (grayscale or BGR)\n\n"
             "Returns:\n"
             "  (keypoints, descriptors) tuple\n"
             "  keypoints: list of (x, y, size, angle, response, octave)\n"
             "  descriptors: numpy array of shape (N, 32)")
        .def("detect", &PySPHORB::detect,
             py::arg("image"),
             "Detect keypoints only\n\n"
             "Parameters:\n"
             "  image: Input image as numpy array (grayscale or BGR)\n\n"
             "Returns:\n"
             "  keypoints: list of (x, y, size, angle, response, octave)")
        .def("descriptorSize", &PySPHORB::descriptorSize,
             "Get descriptor size in bytes")
        .def("descriptorType", &PySPHORB::descriptorType,
             "Get descriptor type");

    m.def("ratioTest",
          static_cast<py::list (*)(const py::list&, float)>(&ratioTest),
          py::arg("knMatches"),
          py::arg("maxRatio"),
          "Apply ratio test to filter matches\n\n"
          "Parameters:\n"
          "  knMatches: List of k-nearest matches\n"
          "  maxRatio: Maximum ratio for the test\n\n"
          "Returns:\n"
          "  Filtered matches");
}
