//
//  Mixer.metal
//  MultiCamera
//
//  Created by Shingai Yoshimi on 2019/11/21.
//

#include <metal_stdlib>
using namespace metal;

kernel void mix(texture2d<half, access::read> mainTexture [[ texture(0) ]],
                texture2d<half, access::sample> subTexture [[ texture(1) ]],
                texture2d<half, access::write> outputTexture [[ texture(2) ]],
                uint2 id [[thread_position_in_grid]]) {
    float scale = 0.25;
    float2 origin = float2(50, 100);
    float2 size = float2(mainTexture.get_width(), mainTexture.get_height()) * scale;

    half4 output;

    if ((id.x >= origin.x && id.x <= origin.x + size.x) &&
        (id.y >= origin.y && id.y <= origin.y + size.y)) {
        constexpr sampler textureSampler (filter::linear, coord::pixel);
        float2 sampleCoord = (float2(id) - origin)/scale;
        output = subTexture.sample(textureSampler, sampleCoord);
    } else {
        output = mainTexture.read(id);
    }

    outputTexture.write(output, id);
}
