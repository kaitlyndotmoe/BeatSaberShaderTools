Shader "Custom/BeatSaberShaderTools/Note" {
  Properties {
    _Glossiness ("Smoothness", Range(0, 1)) = 0.5
    _Metallic ("Metallic", Range(0, 1)) = 0
    [Space] [Toggle(_ENABLE_HEIGHT_FOG)] _EnableHeightFog ("Enable Height Fog", Float) = 0
    _FogHeightOffset ("Fog Height Offset", Float) = 0
    _FogHeightScale ("Fog Height Scale", Float) = 1
    [Space] _FogStartOffset ("Fog Start Offset", Float) = 0
    _FogScale ("Fog Scale", Float) = 1
    [Toggle(_COLOR_INSTANCING)] _ColorInstancing ("Color Instancing", Float) = 0
    _Color ("Color", Vector) = (1,1,1,1)
    _FinalColorMul ("Color Multiplier", Float) = 1
    [Space] [Toggle(_ENABLE_CUTOUT)] _EnableCutout ("Enable Cutout", Float) = 0
    _CutoutTexScale ("Cutout Texture Scale", Float) = 1
    [Space] [Toggle(_ENABLE_PLANE_CUT)] _EnablePlaneCut ("Enable Plane Cut", Float) = 0
    _CutPlaneEdgeGlowWidth ("Plane Edge Glow Width", Float) = 0.01
    [PerRendererData] _CutPlane ("Cut Plane", Vector) = (1,0,0,0)
    [Space] [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 0
    [Space] [Toggle(_ENABLE_RIM_DIM)] _EnableRimDim ("Enable Rim Dim", Float) = 0
    _RimScale ("Rim Scale", Float) = 1
    _RimOffset ("Rim Offset", Float) = 1
  }
  SubShader {
    Tags { "Queue"="Geometry" "RenderType"="Opaque" }
    Cull [_CullMode]

    CGPROGRAM
    #pragma multi_compile __ ENABLE_BLOOM_FOG
    #pragma multi_compile __ MAIN_EFFECT_ENABLED
    #pragma shader_feature _ENABLE_HEIGHT_FOG
    #pragma shader_feature _COLOR_INSTANCING
    #pragma shader_feature _ENABLE_CUTOUT
    #pragma shader_feature _ENABLE_PLANE_CUT
    #pragma shader_feature _ENABLE_RIM_DIM
    #pragma surface surf Standard vertex:vert noshadow addshadow nofog noforwardadd nolppv keepalpha finalcolor:mycolor
    #pragma target 3.0
    
    #include "BloomFog.cginc"

    struct Input {
      float3 worldPos;
      float3 worldNormal; INTERNAL_DATA
      float4 customScreenPos;
      float4 vertex;
    };

    float _Glossiness;
    float _Metallic;
    float _FogHeightOffset;
    float _FogHeightScale;
    float _FogStartOffset;
    float _FogScale;
    float _FinalColorMul;
    float _RimScale;
    float _RimOffset;
    float _CutoutTexScale;
    sampler3D _CutoutTex;
    float _CutPlaneEdgeGlowWidth;

    UNITY_INSTANCING_BUFFER_START(Props)
      UNITY_DEFINE_INSTANCED_PROP(float4, _CutoutTexOffset)
      UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
      UNITY_DEFINE_INSTANCED_PROP(float4, _CutoutEdgeColor)
      UNITY_DEFINE_INSTANCED_PROP(float4, _CutPlane)
      UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
    UNITY_INSTANCING_BUFFER_END(Props)

    void vert(inout appdata_full v, out Input o) {
      UNITY_INITIALIZE_OUTPUT(Input, o);
      float4 pos = UnityObjectToClipPos(v.vertex);
      o.customScreenPos = ComputeScreenPosCustom(pos);
      o.vertex = v.vertex;
    }

    void mycolor(Input IN, SurfaceOutputStandard o, inout float4 color) {
#ifndef MAIN_EFFECT_ENABLED
      color.rgb = color.rgb - o.Emission;
#else
      color.rgb = color.rgb;
#endif
      color.rgb *= _FinalColorMul * UNITY_ACCESS_INSTANCED_PROP(Props, _Color).rgb;
#ifndef MAIN_EFFECT_ENABLED
      color.rgb += o.Emission;
#endif
#ifndef _ENABLE_HEIGHT_FOG
      BLOOM_FOG_APPLY(color, IN.customScreenPos, IN.worldPos, _FogStartOffset, _FogScale);
#else
      BLOOM_FOG_HEIGHT_FOG_APPLY(color, IN.customScreenPos, IN.worldPos, _FogStartOffset, _FogScale, _FogHeightOffset, _FogHeightScale);
#endif
    }

    void surf(Input IN, inout SurfaceOutputStandard o) {
      float3 distance = normalize(-IN.worldPos.xyz + _WorldSpaceCameraPos.xyz);
      float3 lightDistance = normalize(distance + _WorldSpaceLightPos0.xyz);

#ifdef _ENABLE_CUTOUT
      float cutoutProp = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
      float4 cutoutTexOffsetProp = UNITY_ACCESS_INSTANCED_PROP(Props, _CutoutTexOffset);
      float3 cutoutUV = (IN.worldPos.xyz + -mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz + cutoutTexOffsetProp.xyz) * _CutoutTexScale;
      float cutout = (-cutoutProp * 1.10000002 + tex3D(_CutoutTex, cutoutUV).w) + 0.100000001;
      clip(cutout);
      float cutoutStep = max(-round(abs(cutout) + 0.449999988) + 1, 0);
#else
      float cutoutStep = 0;
#endif

#ifdef _ENABLE_PLANE_CUT
      float4 cutPlaneProp = UNITY_ACCESS_INSTANCED_PROP(Props, _CutPlane);
      float cutPlane = dot(IN.vertex.xyz, cutPlaneProp.xyz) + cutPlaneProp.w;
      clip(cutPlane);
      float cutPlaneStep = step(cutPlane, _CutPlaneEdgeGlowWidth);
#else
      float cutPlaneStep = 0;
#endif

      float cutStep = min(cutPlaneStep + cutoutStep, 1);
#ifndef MAIN_EFFECT_ENABLED
      o.Emission = cutStep;
#else
      o.Emission = UNITY_ACCESS_INSTANCED_PROP(Props, _Color) * cutStep;
#endif
      o.Metallic = _Metallic;
#ifdef _ENABLE_RIM_DIM
      o.Smoothness = _Glossiness * (-clamp(_RimOffset + 1 + -dot(lightDistance, IN.worldNormal.xyz) * _RimScale, 0, 1) + 1);
#else
      o.Smoothness = _Glossiness;
#endif
      o.Alpha = cutStep;
    }
    ENDCG
  }
  FallBack "Diffuse"
}
