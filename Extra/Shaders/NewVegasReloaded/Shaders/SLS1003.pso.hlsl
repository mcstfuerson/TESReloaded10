//
// Generated by Microsoft (R) HLSL Shader Compiler 9.23.949.2378
//
// Parameters:

float4 TESR_ShadowData : register(c32);
float4 TESR_ShadowLightPosition[4] : register(c33);
float4 TESR_ShadowCubeMapBlend : register(c37);

sampler2D DiffuseMap : register(s0);
samplerCUBE TESR_ShadowCubeMapBuffer0 : register(s14) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; ADDRESSW = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };

// Registers:
//
//   Name         Reg   Size
//   ------------ ----- ----
//   DiffuseMap   texture_0       1
//


// Structures:

struct VS_INPUT {
    float2 DiffuseUV : TEXCOORD0;
	float4 texcoord_6 : TEXCOORD6;
};

struct VS_OUTPUT {
    float4 color_0 : COLOR0;
};

#include "Includes/ShadowCube.hlsl"

VS_OUTPUT main(VS_INPUT IN) {
    VS_OUTPUT OUT;

    float4 r0;
	float Shadow;
	
    r0 = tex2D(DiffuseMap, IN.DiffuseUV.xy);
	Shadow = GetLightAmount(TESR_ShadowCubeMapBuffer0, IN.texcoord_6, TESR_ShadowLightPosition[0], TESR_ShadowCubeMapBlend.x);
    OUT.color_0.a = r0.w;
    OUT.color_0.rgb = r0.xyz * Shadow;

    return OUT;
};

// approximately 2 instruction slots used (1 texture, 1 arithmetic)
