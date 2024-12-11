
#include <metal_stdlib>
using namespace metal;
/// This is a Metal Shading Language (MSL) function equivalent to the add_arrays() C function, used to perform the calculation on a GPU.

kernel void update_acceleration(const device float3* pos [[buffer(0)]],
                                 const device float* mass [[buffer(1)]],
                                 device float3* acc [[buffer(2)]],
                                 constant float& GRAVITY [[buffer(3)]],
                                 constant float& epsilon [[buffer(4)]],
                                 constant uint& bodyCount [[buffer(5)]],
                                 uint index [[thread_position_in_grid]]) {
    float3 force = float3(0.0);
    
    for (uint j = 0; j < bodyCount; ++j) {
        if (index != j) {
            float3 rij = pos[j] - pos[index];
            
            float rtSq = rij.x * rij.x + rij.y * rij.y + rij.z * rij.z;
            float r = sqrt(rtSq + epsilon * epsilon);
            
            float num = (GRAVITY * mass[index] * mass[j]);
            float den = pow(r,3);
            float f = num / den;
            
            force += f * rij;
        }
    }
    acc[index] = force / mass[index];
}


kernel void update_velocity(device float3* vel [[buffer(0)]],
                            device float3* acc [[buffer(1)]],
                            constant float& dt [[buffer(2)]],
                            uint index [[thread_position_in_grid]]) {
    vel[index] += acc[index] * dt;
}


kernel void update_position(device float3* pos [[buffer(0)]],
                            device float3* vel [[buffer(1)]],
                            constant float& dt [[buffer(2)]],
                            uint index [[thread_position_in_grid]]) {
    pos[index] += vel[index] * dt;
}
