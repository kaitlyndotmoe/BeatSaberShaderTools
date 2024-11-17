# Beat Saber Shader Tools
Various tools for helping create shaders that work *properly* inside Beat Saber. If you have any issues, please report them in this repo or DM me on Discord: `irl_bunny`

## BloomFog.cginc
Allows for easily mixing in the BloomFog from Beat Saber with the output of your shader, allowing objects to cleanly fade in without popping in (e.g. custom notes). Properly handles fog attenuation/offset, as well as height fog, works on PC and should work on Quest as well.

Unlit Shader Usage:
- Include the CGINC in your shader, example: `#include "BloomFog.cginc"`
- Add `#pragma multi_compile __ ENABLE_BLOOM_FOG` in your shader to also build for `ENABLE_BLOOM_FOG`.
- In your `v2f`, add `float3 worldPos`, aswell as `float4 customScreenPos` and make sure you assign both a texcoord.
- In your vertex function, add the following 2 lines, they are required and are not optional, do not forget them:
```
o.worldPos = mul(unity_ObjectToWorld, v.vertex);
o.customScreenPos = ComputeScreenPosCustom(o.vertex);
```
- In your fragment function, at the end of it, add `BLOOM_FOG_APPLY(color, i.customScreenPos, i.worldPos, 0, 5);` right before the return.
- Done, your shader should now handle Beat Saber's BloomFog correctly!

Shader Examples:
- Surface Note (recreation of 0.11.2's note shader, `Note.shader`)

# Various Infos
If you're using BloomFog/HeightFog in your custom notes, you should consider using the following values for BloomFog/HeightFog:
- `_FogHeightOffset`: 0
- `_FogHeightScale`: 2.5
- `_FogStartOffset`: 100
- `_FogScale`: 0.5

# Q&A
- Q: Why is the new CGINC more complicated to use than it was in the previous versions?
- A: It allows the creator to have more control over how the CGINC works, compared to previous versions.

- Q: Can I support you?
- A: Sure! https://www.patreon.com/join/whatdahopper
