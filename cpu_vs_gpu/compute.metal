//
//  compute.metal
//  AddCompute
//
//  Created by Changmook Chun on 6/30/21.
//

#include <metal_stdlib>
using namespace metal;

kernel void uint16_to_float(constant uint*  src   [[ buffer(0) ]],
                            device   float* dst   [[ buffer(1) ]],
                            uint            index [[ thread_position_in_grid ]]
                            ) {
    dst[index] = float(src[index]);
}

kernel void addition_compute_function(constant float* arr1        [[ buffer(0) ]],
                                      constant float* arr2        [[ buffer(1) ]],
                                      device   float* resultArray [[ buffer(2) ]],
                                      uint            index       [[ thread_position_in_grid ]]
                                      ) {
    resultArray[index] = pow(arr1[index], sin(arr2[index]) + cos(arr1[index]));
}

kernel void accumulate_compute_function(constant float* arr1        [[ buffer(0) ]],
                                        device   float* arr2        [[ buffer(1) ]],
                                        uint            index       [[ thread_position_in_grid ]]
                                      ) {
    arr2[index] += arr1[index];
}

kernel void multiply_compute_function(device   float* arr1        [[ buffer(0) ]],
                                      constant float& factor      [[ buffer(1) ]],
                                      uint            index       [[ thread_position_in_grid ]]
                                      ) {
    arr1[index] *= factor;
}

kernel void average_compute_function(constant float* arr1        [[ buffer(0) ]],
                                     device   float* resultArray [[ buffer(1) ]],
                                     constant uint&  count       [[ buffer(2) ]],
                                     constant uint&  size        [[ buffer(3) ]],
                                     uint            index       [[ thread_position_in_grid ]]
                                     ) {
    for (uint i = 0; i < count; i++) {
        resultArray[index] += arr1[size * i + index] / float(count);
    }
}
