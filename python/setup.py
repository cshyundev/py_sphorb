from setuptools import setup, Extension, find_packages
from setuptools.command.build_ext import build_ext
import os
import subprocess
import sys
import shutil

class CMakeExtension(Extension):
    def __init__(self, name, sourcedir=''):
        Extension.__init__(self, name, sources=[])
        self.sourcedir = os.path.abspath(sourcedir)

class CMakeBuild(build_ext):
    def run(self):
        try:
            subprocess.check_output(['cmake', '--version'])
        except OSError:
            raise RuntimeError("CMake must be installed to build the following extensions: " +
                               ", ".join(e.name for e in self.extensions))

        for ext in self.extensions:
            self.build_extension(ext)

    def build_extension(self, ext):
        extdir = os.path.abspath(os.path.dirname(self.get_ext_fullpath(ext.name)))
        cmake_args = [
            '-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=' + extdir,
            '-DPYTHON_EXECUTABLE=' + sys.executable
        ]

        build_temp = self.build_temp
        if not os.path.exists(build_temp):
            os.makedirs(build_temp)

        # 빌드 실행
        subprocess.check_call(['cmake', ext.sourcedir] + cmake_args, cwd=build_temp)
        subprocess.check_call(['cmake', '--build', '.'], cwd=build_temp)

        # 실제 .so 파일이 빌드된 경로에서 찾기
        so_file = os.path.join(build_temp, '../lib.linux-x86_64-cpython-310/sphorb_bindings.cpython-310-x86_64-linux-gnu.so')
        if not os.path.exists(so_file):
            raise RuntimeError(f".so file not found at {so_file}")

        target_dir = os.path.join(self.build_lib, 'py_sphorb')
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)
        shutil.copy(so_file, target_dir)

setup(
    name='py_sphorb',
    version='0.1.0',
    author='Your Name',
    author_email='your.email@example.com',
    description='A Python binding for the SPHORB feature extraction library',
    long_description='A Python package for extracting spherical image features using SPHORB.',
    ext_modules=[CMakeExtension('sphorb_bindings', sourcedir='../')],  # CMake 소스 경로 설정
    cmdclass={'build_ext': CMakeBuild},
    packages=find_packages(),
    include_package_data=True,  # 패키지에 데이터 파일 포함
    zip_safe=False,
    install_requires=[
        'pybind11>=2.5.0',
        'opencv-python>=4.8.0'
    ],
    python_requires='>=3.6',
)
