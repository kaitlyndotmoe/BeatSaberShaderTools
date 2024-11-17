#ifndef BLOOM_FOG_CG_INCLUDED
#define BLOOM_FOG_CG_INCLUDED

float _StereoCameraEyeOffset;

// These are the global variable names the game uses by default,
// certain mods might want to use their own attenuation/offset variable names.
#ifndef CUSTOM_FOG_ATTENUATION_NAME
#define CUSTOM_FOG_ATTENUATION_NAME _CustomFogAttenuation
#endif
#ifndef CUSTOM_FOG_OFFSET_NAME
#define CUSTOM_FOG_OFFSET_NAME _CustomFogOffset
#endif

float CUSTOM_FOG_ATTENUATION_NAME;
float CUSTOM_FOG_OFFSET_NAME;

#ifndef CUSTOM_FOG_COMPUTE_FACTOR
#define CUSTOM_FOG_COMPUTE_FACTOR(distance, fogStartOffset, fogScale) \
  float customFogFactor = max(dot(distance, distance) + -fogStartOffset, 0); \
  customFogFactor = max(customFogFactor * fogScale + -CUSTOM_FOG_OFFSET_NAME, 0); \
  customFogFactor = 1 / (customFogFactor * CUSTOM_FOG_ATTENUATION_NAME + 1)
#endif

#ifndef CUSTOM_FOG_HEIGHT_FOG_START_Y_NAME
#define CUSTOM_FOG_HEIGHT_FOG_START_Y_NAME _CustomFogHeightFogStartY
#endif
#ifndef CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME
#define CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME _CustomFogHeightFogHeight
#endif

float CUSTOM_FOG_HEIGHT_FOG_START_Y_NAME;
float CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME;

#ifndef CUSTOM_FOG_HEIGHT_FOG_COMPUTE_FACTOR
#define CUSTOM_FOG_HEIGHT_FOG_COMPUTE_FACTOR(worldPos, fogHeightOffset, fogHeightScale) \
  float customFogHeightFogFactor = CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME + CUSTOM_FOG_HEIGHT_FOG_START_Y_NAME; \
  customFogHeightFogFactor = ((worldPos.y * fogHeightScale) + fogHeightOffset) + -customFogHeightFogFactor; \
  customFogHeightFogFactor = clamp(customFogHeightFogFactor / CUSTOM_FOG_HEIGHT_FOG_HEIGHT_NAME, 0, 1); \
  customFogHeightFogFactor = (-customFogHeightFogFactor * 2 + 3) * (customFogHeightFogFactor * customFogHeightFogFactor)
#endif

inline float4 ComputeScreenPosCustom(float4 pos) {
  float4 screenPos = ComputeNonStereoScreenPos(pos);
#if defined(UNITY_SINGLE_PASS_STEREO) || defined(STEREO_INSTANCING_ON) || defined(STEREO_MULTIVIEW_ON)
  float eyeOffset = (unity_StereoEyeIndex * (_StereoCameraEyeOffset + _StereoCameraEyeOffset)) + -_StereoCameraEyeOffset;
  screenPos.x = pos.w * eyeOffset + screenPos.x;
#if !UNITY_UV_STARTS_AT_TOP
  screenPos.y = -screenPos.y + pos.w;
#endif
#endif
  return screenPos;
}

#ifdef ENABLE_BLOOM_FOG

float2 _CustomFogTextureToScreenRatio;
sampler2D _BloomPrePassTexture;

#define CUSTOM_FOG_COMPUTE_UV(screenPos) \
  float2 customFogUV = screenPos.xy / screenPos.w; \
  customFogUV = (customFogUV + -0.5) * _CustomFogTextureToScreenRatio + 0.5

#define BLOOM_PREPASS_SAMPLE(screenPos) \
  CUSTOM_FOG_COMPUTE_UV(screenPos); \
  float4 bloomPrepassCol = float4(tex2D(_BloomPrePassTexture, customFogUV).rgb, 0)

#else

#define BLOOM_PREPASS_SAMPLE(screenPos) \
  float4 bloomPrepassCol = float4(0,0,0,0)

#endif

#define BLOOM_FOG_APPLY(col, screenPos, worldPos, fogStartOffset, fogScale) \
  float3 bloomFogDistance = worldPos - _WorldSpaceCameraPos; \
  CUSTOM_FOG_COMPUTE_FACTOR(bloomFogDistance, fogStartOffset, fogScale); \
  BLOOM_PREPASS_SAMPLE(screenPos); \
  col = (-customFogFactor + 1) * (-col + bloomPrepassCol) + col

#define BLOOM_FOG_HEIGHT_FOG_APPLY(col, screenPos, worldPos, fogStartOffset, fogScale, fogHeightOffset, fogHeightScale) \
  float3 bloomFogDistance = worldPos - _WorldSpaceCameraPos; \
  CUSTOM_FOG_HEIGHT_FOG_COMPUTE_FACTOR(worldPos, fogHeightOffset, fogHeightScale); \
  CUSTOM_FOG_COMPUTE_FACTOR(bloomFogDistance, fogStartOffset, fogScale); \
  BLOOM_PREPASS_SAMPLE(screenPos); \
  col = (customFogHeightFogFactor * -customFogFactor + 1) * (-col + bloomPrepassCol) + col

#define BLOOM_FOG_APPLY_TRANSPARENT(col, worldPos, fogStartOffset, fogScale) \
  float3 bloomFogDistance = worldPos - _WorldSpaceCameraPos; \
  CUSTOM_FOG_COMPUTE_FACTOR(bloomFogDistance, fogStartOffset, fogScale); \
  customFogFactor = customFogFactor * col.a; \
  col = float4(customFogFactor * col.rgb, customFogFactor)

#endif // BLOOM_FOG_CG_INCLUDED
