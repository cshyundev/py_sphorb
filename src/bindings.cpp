#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <opencv2/opencv.hpp>
#include "SPHORB.h"

namespace py = pybind11;
using namespace cv;

PYBIND11_MODULE(sphorb_module, m) {
    py::class_<SPHORB, std::shared_ptr<SPHORB>>(m, "SPHORB")
        .def(py::init<int, int, int>(), py::arg("nfeatures") = 500, py::arg("nlevels") = 7, py::arg("b") = 20)
        .def("descriptorSize", &SPHORB::descriptorSize)
        .def("descriptorType", &SPHORB::descriptorType)
        .def("detectAndCompute", [](SPHORB& self, py::array image_array, py::object mask_obj = py::none(), bool use_provided_keypoints = false) {
            // 이미지 변환
            py::buffer_info image_info = image_array.request();

            int rows = image_info.shape[0];
            int cols = image_info.shape[1];
            int channels = 1;
            if (image_info.ndim == 3) {
                channels = image_info.shape[2];
            } else if (image_info.ndim != 2) {
                throw std::runtime_error("Input image must be 2D or 3D array");
            }

            int dtype;
            if (image_info.format == py::format_descriptor<uint8_t>::format()) {
                dtype = CV_8U;
            } else if (image_info.format == py::format_descriptor<int8_t>::format()) {
                dtype = CV_8S;
            } else if (image_info.format == py::format_descriptor<uint16_t>::format()) {
                dtype = CV_16U;
            } else if (image_info.format == py::format_descriptor<int16_t>::format()) {
                dtype = CV_16S;
            } else if (image_info.format == py::format_descriptor<int32_t>::format()) {
                dtype = CV_32S;
            } else if (image_info.format == py::format_descriptor<float>::format()) {
                dtype = CV_32F;
            } else if (image_info.format == py::format_descriptor<double>::format()) {
                dtype = CV_64F;
            } else {
                throw std::runtime_error("Unsupported image data type");
            }

            int type = CV_MAKETYPE(dtype, channels);

            // cv::Mat 생성 (데이터 복사 없이)
            cv::Mat image(rows, cols, type, image_info.ptr);

            // 마스크 처리
            cv::Mat mask;
            if (!mask_obj.is_none()) {
                py::array mask_array = mask_obj.cast<py::array>();
                py::buffer_info mask_info = mask_array.request();

                if (mask_info.ndim != 2) {
                    throw std::runtime_error("Mask must be a 2D array");
                }

                int mask_dtype;
                if (mask_info.format == py::format_descriptor<uint8_t>::format()) {
                    mask_dtype = CV_8U;
                } else {
                    throw std::runtime_error("Unsupported mask data type");
                }

                mask = cv::Mat(mask_info.shape[0], mask_info.shape[1], mask_dtype, mask_info.ptr);
            }

            // 특징점 검출
            std::vector<cv::KeyPoint> keypoints;
            cv::Mat descriptors;

            // 특징점 검출 함수 호출
            self(image, mask, keypoints, descriptors, use_provided_keypoints);

            // KeyPoint를 Python에서 사용할 수 있는 형식으로 변환
            py::list keypoints_list;
            for (const auto& kp : keypoints) {
                py::dict kp_dict;
                kp_dict["pt"] = py::make_tuple(kp.pt.x, kp.pt.y);
                kp_dict["size"] = kp.size;
                kp_dict["angle"] = kp.angle;
                kp_dict["response"] = kp.response;
                kp_dict["octave"] = kp.octave;
                kp_dict["class_id"] = kp.class_id;
                keypoints_list.append(kp_dict);
            }

            // 디스크립터를 NumPy 배열로 변환
            py::object descriptors_obj = py::none();
            if (!descriptors.empty()) {
                py::dtype dt = py::dtype::of<uint8_t>();

                std::vector<size_t> shape = {(size_t)descriptors.rows, (size_t)descriptors.cols};
                std::vector<size_t> strides = {(size_t)descriptors.step[0], (size_t)descriptors.elemSize()};

                descriptors_obj = py::array(dt, shape, strides, descriptors.data, py::cast(descriptors));
            }

            return py::make_tuple(keypoints_list, descriptors_obj);
        }, py::arg("image"), py::arg("mask") = py::none(), py::arg("use_provided_keypoints") = false);
}
