import cv2
import numpy as np
import sphorb

# 이미지 로드
image = cv2.imread('Images/1_1.jpg', cv2.IMREAD_GRAYSCALE)
# 이미지가 정상적으로 로드되었는지 확인
if image is None:
    raise FileNotFoundError('1_1.jpg 파일을 찾을 수 없습니다.')

# SPHORB 객체 생성
sphorb_instance = sphorb.SPHORB()


# # 특징점 검출
keypoints, descriptors = sphorb_instance.detectAndCompute(image)

# # 특징점 그리기
output_image = cv2.drawKeypoints(image, keypoints, None, color=(0, 255, 0))

# 결과 표시
cv2.imshow('SPHORB Keypoints', output_image)
cv2.waitKey(0)
cv2.destroyAllWindows()
