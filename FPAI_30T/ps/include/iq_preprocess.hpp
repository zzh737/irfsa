#pragma once
#include <array>
#include <algorithm>
#include <cmath>
#include <cstdint>

// Input I0,Q0,... in host int16. Output contiguous I[1024], Q[1024].
// Match py/signal_preprocess.py: sqrt(sum(I^2+Q^2)/(2*1024)), epsilon 1e-8.
inline std::array<float,2048> normalize_iq(const std::array<int16_t,2048>& iq) {
 std::array<float,2048> out{};float sum=0;
 for(size_t n=0;n<1024;++n){
   const float i=iq[2*n],q=iq[2*n+1];out[n]=i;out[1024+n]=q;
   sum+=i*i+q*q;
 }
 const float scale=std::max(std::sqrt(sum/2048.0f),1e-8f);
 for(auto& value:out)value/=scale;
 return out;
}
