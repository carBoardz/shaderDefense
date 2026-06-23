Shader "Custom/URPToonShader"
{
    Properties
    {
        [Header(Base Textures and Tint Colors)]
        _BaseMap("Base Map", 2D) = "white" {}
        [HDR] _BaseColor("Base Color (Bright)", Color) = (1, 1, 1, 1)
        [HDR] _ShadeColor1("Shade Color 1 (Mid)", Color) = (0.7, 0.7, 0.7, 1)
        [HDR] _ShadeColor2("Shade Color 2 (Dark)", Color) = (0.4, 0.4, 0.4, 1)

        [Header(Cel Shading Settings)]
        _Threshold1("Threshold 1 (Mid/Bright)", Range(0, 1)) = 0.5
        _Threshold2("Threshold 2 (Dark/Mid)", Range(0, 1)) = 0.2
        _Feather("Threshold Feathering", Range(0.001, 0.1)) = 0.01

        [Header(Specular Settings)]
        [Toggle(_SPECULAR_ON)] _SpecularOn("Enable Specular", Float) = 1
        [HDR] _SpecColor("Specular Color", Color) = (1, 1, 1, 1)
        _SpecularThreshold("Specular Threshold", Range(0, 1)) = 0.5
        _SpecularGloss("Specular Glossiness (Power)", Range(1, 256)) = 32
        _SpecularFeather("Specular Feathering", Range(0.001, 0.1)) = 0.01

        [Header(Shadow Settings)]
        _ShadowStrength("Shadow Strength", Range(0, 1)) = 1.0

        [Header(Rim Light Settings)]
        [Toggle(_RIM_LIGHT_ON)] _RimLightOn("Enable Rim Light", Float) = 0
        [HDR] _RimColor("Rim Color", Color) = (1, 1, 1, 1)
        _RimPower("Rim Power", Range(0.1, 10)) = 3
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.5
        _RimFeather("Rim Feathering", Range(0.001, 0.1)) = 0.01
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Geometry"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _SPECULAR_ON
            #pragma shader_feature_local _RIM_LIGHT_ON
            
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_FILTERING
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 viewDirWS    : TEXCOORD3;
                float3 positionWS   : TEXCOORD4;
                float4 shadowCoord  : TEXCOORD5;
                float  fogFactor    : TEXCOORD6;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half4 _ShadeColor1;
                half4 _ShadeColor2;
                half _Threshold1;
                half _Threshold2;
                half _Feather;
                half4 _SpecColor;
                half _SpecularThreshold;
                half _SpecularGloss;
                half _SpecularFeather;
                half _ShadowStrength;
                half4 _RimColor;
                half _RimPower;
                half _RimThreshold;
                half _RimFeather;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

                // Setup shadow coord in vertex shader
                output.shadowCoord = TransformWorldToShadowCoord(vertexInput.positionWS);

                // Setup fog factor using URP standard functions
                output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // Retrieve textures
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);

                // Get main light (supports screen-space shadow maps via positionWS)
                half4 shadowMask = half4(1.0, 1.0, 1.0, 1.0);
                Light mainLight = GetMainLight(input.shadowCoord, input.positionWS, shadowMask);

                // Normal and light directions
                float3 normal = normalize(input.normalWS);
                float3 lightDir = normalize(mainLight.direction);
                float3 viewDir = normalize(input.viewDirWS);

                // Diffuse lighting
                float NdotL = dot(normal, lightDir);
                float halfLambert = NdotL * 0.5 + 0.5;

                // Adjust shadow attenuation with shadow strength
                float shadowAtten = lerp(1.0, mainLight.shadowAttenuation, _ShadowStrength);
                float lightInfluence = halfLambert * shadowAtten;

                // 3-Color stepped diffuse ramp with feathering for anti-aliasing
                half feather = max(0.0001, _Feather);
                half mask1 = smoothstep(_Threshold1 - feather, _Threshold1 + feather, lightInfluence);
                half mask2 = smoothstep(_Threshold2 - feather, _Threshold2 + feather, lightInfluence);

                half3 colBase = albedo.rgb * _BaseColor.rgb;
                half3 colShade1 = albedo.rgb * _ShadeColor1.rgb;
                half3 colShade2 = albedo.rgb * _ShadeColor2.rgb;

                // Blend colors: colShade2 (dark) -> colShade1 (mid) -> colBase (bright)
                half3 toonDiffuse = lerp(colShade2, colShade1, mask2);
                toonDiffuse = lerp(toonDiffuse, colBase, mask1);

                // Multiply by main light color and intensity
                half3 finalDiffuse = toonDiffuse * (mainLight.color * mainLight.distanceAttenuation);

                // Ambient environment light
                half3 ambient = SampleSH(normal) * colShade2;

                // Specular highlight
                half3 specularColor = float3(0, 0, 0);
                #if defined(_SPECULAR_ON)
                half3 halfDir = normalize(lightDir + viewDir);
                float NdotH = max(0.0, dot(normal, halfDir));
                float specPower = pow(NdotH, _SpecularGloss);
                half specFeather = max(0.0001, _SpecularFeather);
                float specMask = smoothstep(_SpecularThreshold - specFeather, _SpecularThreshold + specFeather, specPower);
                
                // Highlight masked by shadow to avoid glowing in the shadow
                specularColor = _SpecColor.rgb * specMask * mainLight.shadowAttenuation * mainLight.color;
                #endif

                // Rim light
                half3 rimColor = float3(0, 0, 0);
                #if defined(_RIM_LIGHT_ON)
                float VdotN = max(0.0, dot(viewDir, normal));
                float rimPower = pow(1.0 - VdotN, _RimPower);
                half rimFeather = max(0.0001, _RimFeather);
                float rimMask = smoothstep(_RimThreshold - rimFeather, _RimThreshold + rimFeather, rimPower);
                
                // Rim light is also attenuated by shadow and main light
                rimColor = _RimColor.rgb * rimMask * mainLight.shadowAttenuation * mainLight.color;
                #endif

                // Additional Lights Support
                half3 additionalLightColor = float3(0, 0, 0);
                #if defined(_ADDITIONAL_LIGHTS)
                int additionalLightsCount = GetAdditionalLightsCount();
                for (int i = 0; i < additionalLightsCount; ++i)
                {
                    Light light = GetAdditionalLight(i, input.positionWS, half4(1, 1, 1, 1));
                    
                    float3 addLightDir = normalize(light.direction);
                    float addNdotL = dot(normal, addLightDir);
                    float addHalfLambert = addNdotL * 0.5 + 0.5;
                    
                    float addLightInfluence = addHalfLambert * light.distanceAttenuation * light.shadowAttenuation;
                    
                    half addMask1 = smoothstep(_Threshold1 - feather, _Threshold1 + feather, addLightInfluence);
                    half addMask2 = smoothstep(_Threshold2 - feather, _Threshold2 + feather, addLightInfluence);
                    
                    half3 addDiffuse = lerp(colShade2, colShade1, addMask2);
                    addDiffuse = lerp(addDiffuse, colBase, addMask1);
                    
                    half3 addSpec = float3(0, 0, 0);
                    #if defined(_SPECULAR_ON)
                    half3 addHalfDir = normalize(addLightDir + viewDir);
                    float addNdotH = max(0.0, dot(normal, addHalfDir));
                    float addSpecPower = pow(addNdotH, _SpecularGloss);
                    float addSpecMask = smoothstep(_SpecularThreshold - specFeather, _SpecularThreshold + specFeather, addSpecPower);
                    addSpec = _SpecColor.rgb * addSpecMask * light.shadowAttenuation;
                    #endif

                    additionalLightColor += (addDiffuse + addSpec) * light.color;
                }
                #endif

                // Combine all lighting passes
                half3 finalColor = ambient + finalDiffuse + specularColor + rimColor + additionalLightColor;
                
                // Apply Fog using URP standard MixFog function
                finalColor = MixFog(finalColor, input.fogFactor);
                
                return half4(finalColor, albedo.a * _BaseColor.a);
            }
            ENDHLSL
        }

        // Shadow Caster Pass
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
            };

            float3 _LightDirection;
            float3 _LightPosition;

            Varyings vert(Attributes input)
            {
                Varyings output;

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                float3 lightDirectionWS = _LightDirection;
                #endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

                #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                output.positionCS = positionCS;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

        // Depth Only Pass
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

        // Depth Normals Pass
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormals" }

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float3 normalWS     : TEXCOORD0;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                return float4(normalize(input.normalWS), 0.0);
            }
            ENDHLSL
        }
    }
    FallBack "UniversalRenderPipeline/Lit"
}
