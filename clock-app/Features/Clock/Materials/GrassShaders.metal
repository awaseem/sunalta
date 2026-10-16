#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

[[visible]] void grassBreeze(realitykit::geometry_parameters params) {
    float2 uv = params.geometry().uv0();
    float3 position = params.geometry().model_position();
    float time = params.uniforms().custom_parameter().x;
    float wave = sin(time * 1.5 + position.x * 1.7 + position.y * 0.8);
    float flutter = sin(time * 2.3 + uv.x * 12.0) * 0.25;
    float bend = uv.y * uv.y;
    params.geometry().set_model_position_offset(float3((wave + flutter) * 0.025, 0,
                                                       wave * 0.012) * bend);
}

[[visible]] void grassSurface(realitykit::surface_parameters params) {
    float2 uv = params.geometry().uv0();
    half variation = half(uv.x);
    half tip = half(uv.y);
    half3 rootColor = mix(half3(0.025, 0.095, 0.009), half3(0.075, 0.19, 0.018), variation);
    half3 tipColor = mix(half3(0.12, 0.37, 0.025), half3(0.25, 0.48, 0.055), variation);
    params.surface().set_base_color(mix(rootColor, tipColor, tip));
    params.surface().set_roughness(0.9h);
    params.surface().set_specular(0.15h);
    params.surface().set_opacity(half(params.uniforms().custom_parameter().y));
}
