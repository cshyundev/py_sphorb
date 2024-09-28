import cv2
from .sphorb_module import SPHORB

class SPHORBWrapper:
    def __init__(self, nfeatures=500, nlevels=7, b=20):
        self.sphorb = SPHORB(nfeatures, nlevels, b)

    def detectAndCompute(self, image, mask=None, use_provided_keypoints=False):
        keypoints, descriptors = self.sphorb.detectAndCompute(image, mask, use_provided_keypoints)
        
        return keypoints, descriptors