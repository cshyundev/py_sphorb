from setuptools import setup, Extension, find_packages
from setuptools.command.build_ext import build_ext
import sys
import os

class CMakeExtension(Extension):
    def __init__(self, name, sourcedir="", library_output_dir=""):
        super().__init__(name, sources=[])
        self.sourcedir = os.path.abspath(sourcedir)
        self.library_output_dir = os.path.abspath(library_output_dir)

class CMakeBuild(build_ext):
    def build_extension(self, ext):
        import subprocess

        extdir = os.path.abspath(os.path.dirname(self.get_ext_fullpath(ext.name)))
        cfg = 'Release'

        cmake_args = [
            f'-DCMAKE_LIBRARY_OUTPUT_DIRECTORY={ext.library_output_dir}',
            f'-DPYTHON_EXECUTABLE={sys.executable}',
            f'-DCMAKE_BUILD_TYPE={cfg}',
        ]

        build_args = ['--config', cfg]

        if not os.path.exists(self.build_temp):
            os.makedirs(self.build_temp)

        subprocess.check_call(['cmake', ext.sourcedir] + cmake_args, cwd=self.build_temp)
        subprocess.check_call(['cmake', '--build', '.'] + build_args, cwd=self.build_temp)

setup(
    name='sphorb',
    version='0.1',
    author='Your Name',
    description='Python binding for SPHORB feature extractor',
    packages=find_packages(),
    ext_modules=[CMakeExtension('sphorb.sphorb_module', sourcedir='.', library_output_dir='sphorb')],
    cmdclass={'build_ext': CMakeBuild},
    zip_safe=False,
    include_package_data=True,
    classifiers=[
        'Programming Language :: Python :: 3',
        'Programming Language :: C++',
        'Operating System :: OS Independent',
    ],
)
