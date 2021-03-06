#
# Copyright (c) 2019, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# cython: profile=False
# distutils: language = c++
# cython: embedsignature = True
# cython: language_level = 3


import ctypes
import cudf
import numpy as np

import rmm

from libc.stdlib cimport malloc, free

from libcpp cimport bool
from libc.stdint cimport uintptr_t, uint32_t, uint64_t
from cython.operator cimport dereference as deref

from cuml.common.array import CumlArray
import cuml.common.opg_data_utils_mg as opg

from cuml.common.base import Base
from cuml.common.handle cimport cumlHandle
from cuml.decomposition.utils cimport *
from cuml.common import input_to_dev_array, zeros
from cuml.common.opg_data_utils_mg cimport *

from cuml.decomposition import PCA
from cuml.decomposition.base_mg import BaseDecompositionMG

cdef extern from "cumlprims/opg/pca.hpp" namespace "ML::PCA::opg":

    cdef void fit(cumlHandle& handle,
                  vector[floatData_t *] input_data,
                  PartDescriptor &input_desc,
                  float *components,
                  float *explained_var,
                  float *explained_var_ratio,
                  float *singular_vals,
                  float *mu,
                  float *noise_vars,
                  paramsPCA &prms,
                  bool verbose) except +

    cdef void fit(cumlHandle& handle,
                  vector[doubleData_t *] input_data,
                  PartDescriptor &input_desc,
                  double *components,
                  double *explained_var,
                  double *explained_var_ratio,
                  double *singular_vals,
                  double *mu,
                  double *noise_vars,
                  paramsPCA &prms,
                  bool verbose) except +


class PCAMG(BaseDecompositionMG, PCA):

    def __init__(self, **kwargs):
        super(PCAMG, self).__init__(**kwargs)

    def _call_fit(self, X, rank, part_desc, arg_params):

        cdef uintptr_t comp_ptr = self._components_.ptr
        cdef uintptr_t explained_var_ptr = self._explained_variance_.ptr
        cdef uintptr_t explained_var_ratio_ptr = \
            self._explained_variance_ratio_.ptr
        cdef uintptr_t singular_vals_ptr = self._singular_values_.ptr
        cdef uintptr_t mean_ptr = self._mean_.ptr
        cdef uintptr_t noise_vars_ptr = self._noise_variance_.ptr
        cdef cumlHandle* handle_ = <cumlHandle*><size_t>self.handle.getHandle()

        cdef paramsPCA *params = <paramsPCA*><size_t>arg_params

        if self.dtype == np.float32:

            fit(handle_[0],
                deref(<vector[floatData_t*]*><uintptr_t>X),
                deref(<PartDescriptor*><uintptr_t>part_desc),
                <float*> comp_ptr,
                <float*> explained_var_ptr,
                <float*> explained_var_ratio_ptr,
                <float*> singular_vals_ptr,
                <float*> mean_ptr,
                <float*> noise_vars_ptr,
                deref(params),
                False)
        else:

            fit(handle_[0],
                deref(<vector[doubleData_t*]*><uintptr_t>X),
                deref(<PartDescriptor*><uintptr_t>part_desc),
                <double*> comp_ptr,
                <double*> explained_var_ptr,
                <double*> explained_var_ratio_ptr,
                <double*> singular_vals_ptr,
                <double*> mean_ptr,
                <double*> noise_vars_ptr,
                deref(params),
                False)

        self.handle.sync()
