//
// Generated by Microsoft (R) D3DX9 Shader Compiler 9.08.299.0000
//
// Parameters:
//
float4 EyePos : register(c1);
float4 SunDir : register(c2);
float4 SunColor : register(c3);
float4 ShallowColor : register(c5);
float4 DeepColor : register(c6);
float4 ReflectionColor : register(c7);
float4 VarAmounts : register(c8);
float4 FogParam : register(c9);
float4 FogColor : register(c10);
float4 FresnelRI : register(c11);
float4 TESR_SunColor : register(c13);
float4 TESR_WaterCoefficients : register(c14);
float4 TESR_WaveParams : register(c15);
float4 TESR_ReciprocalResolution : register(c17);
float4x4 TESR_ViewTransform : register(c19);
float4x4 TESR_ProjectionTransform : register(c23);

sampler2D ReflectionMap : register(s0);
sampler2D TESR_WaterHeightMapBuffer : register(s1); // samplerState1 { ADDRESSU = WRAP; ADDRESSV = WRAP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; }

static const float4x4 ditherMat = { 0.0588, 0.5294, 0.1765, 0.6471,
									0.7647, 0.2941, 0.8824, 0.4118,
									0.2353, 0.7059, 0.1176, 0.5882,
									0.9412, 0.4706, 0.8235, 0.3259 };

//
//
// Registers:
//
//   Name            Reg   Size
//   --------------- ----- ----
//   EyePos          const_1       1
//   SunDir          const_2       1
//   SunColor        const_3       1
//   ShallowColor    const_5       1
//   DeepColor       const_6       1
//   ReflectionColor const_7       1
//   VarAmounts      const_8       1
//   FogParam        const_9       1
//   FogColor        const_10      1
//   FresnelRI       const_11      1
//   ReflectionMap   texture_0       1
//


// Structures:

struct VS_OUTPUT {
    float4 texcoord_0 : TEXCOORD0;
    float4 texcoord_1 : TEXCOORD1_centroid;
    float4 texcoord_2 : TEXCOORD2_centroid;
};

struct PS_OUTPUT {
    float4 color_0 : COLOR0;
};

// Code:
float3 toWorld(float2 tex) {
	
    float3 v = float3(TESR_ViewTransform[2][0], TESR_ViewTransform[2][1], TESR_ViewTransform[2][2]);
    v += (1/TESR_ProjectionTransform[0][0] * (2*tex.x-1)).xxx * float3(TESR_ViewTransform[0][0], TESR_ViewTransform[0][1], TESR_ViewTransform[0][2]);
    v += (-1/TESR_ProjectionTransform[1][1] * (2*tex.y-1)).xxx * float3(TESR_ViewTransform[1][0], TESR_ViewTransform[1][1], TESR_ViewTransform[1][2]);
    return v;
	
}

float3 getWaterNorm(float2 pos, float dist, float camera_vector_z) {
	
	float choppiness = TESR_WaveParams.x;
	float waveWidth = TESR_WaveParams.y;
	float lod = max(saturate(camera_vector_z * 50 * TESR_ProjectionTransform[0][0] / (TESR_ReciprocalResolution.x * dist)), 0.25);
	
	float4 sampledResult = tex2D(TESR_WaterHeightMapBuffer, pos.xy / (1248 * waveWidth));
	float2 temp_norm = sampledResult.rg * 2 - 1;
	float3 norm = normalize(float3(temp_norm * choppiness * lod, 1));
	return norm;
	
}

float getFresnelAboveWater( float3 ray, float3 norm ) {
	
	float temp_cos = dot(-ray, norm);
	float2 vec = float2(temp_cos, sqrt(1 - temp_cos * temp_cos));
	float fresnel = vec.x - 1.33 * sqrt(1 - 0.565 * vec.y * vec.y);
	
	fresnel /= vec.x + 1.33 * sqrt(1 - 0.565 * vec.y * vec.y);
	fresnel = saturate(fresnel * fresnel);
	return fresnel;
	
}


PS_OUTPUT main(VS_OUTPUT IN, float2 PixelPos : VPOS) {
    PS_OUTPUT OUT;

	float2 UVCoord = (PixelPos + 0.5) * TESR_ReciprocalResolution.xy;
	float3 eyepos = IN.texcoord_2.xyz;
	eyepos.z = -IN.texcoord_1.z;

    float3 camera_vector = toWorld(UVCoord);
	float3 norm_camera_vector = normalize(camera_vector);

	float3 extCoeff = TESR_WaterCoefficients.xyz;
	float scattCoeff = TESR_WaterCoefficients.w;
	float reflectivity = TESR_WaveParams.w;
	float waveWidth = TESR_WaveParams.y;

	float dist = eyepos.z / -camera_vector.z;
	float2 surfPos = eyepos.xy + camera_vector.xy * dist;
	float3 normal = getWaterNorm(surfPos, dist, -camera_vector.z);

	//Refraction
	float SinBoverSinA = -norm_camera_vector.z;
	float3 waterVolColor = scattCoeff * FogColor.xyz / (extCoeff * (1 + SinBoverSinA));
	float4 refract_color = float4(waterVolColor.rgb, 1);

	//Reflection
	float2 refPos = UVCoord + 0.05 * normal.yx;
	float4 reflection = tex2D(ReflectionMap, float2(refPos.x, 1 - refPos.y));
	
	//Fresnel
	float fresnel = saturate(getFresnelAboveWater(norm_camera_vector, normal) * reflectivity);
	float4 water_result = lerp(refract_color, reflection, fresnel);
	
	//Specular
	float specular = saturate(dot(norm_camera_vector, reflect(SunDir.xyz, normal)));
	water_result.xyz += (1 - TESR_SunColor.a) * pow(specular, dist * 0.3) * TESR_SunColor.rgb;
	
	//Fog
    float fog = 1 - saturate((FogParam.x - length(IN.texcoord_1.xyz)) / FogParam.y);
	water_result.rgb = (fog * (FogColor.rgb - water_result.rgb)) + water_result.rgb;

	water_result.rgb += ditherMat[ PixelPos.x%4 ][ PixelPos.y%4 ] / 255;

	OUT.color_0.rgb = water_result.rgb;
	OUT.color_0.a = 1;
    return OUT;
	
};

// approximately 84 instruction slots used (4 texture, 80 arithmetic)
