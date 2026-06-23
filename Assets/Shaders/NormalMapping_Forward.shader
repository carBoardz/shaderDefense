Shader "Custom/NormalMapping_Forward"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Float) = 1.0
        _Specular ("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8, 256)) = 64
        _Metallic ("Metallic", Range(0, 1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS(4)
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            float4 _Specular;
            float _Gloss;
            float _Metallic;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _BumpMap);
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                
                TRANSFER_SHADOW(o);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb;
                
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                
                fixed3 worldNormal = normalize(float3(
                    dot(i.TtoW0.xyz, tangentNormal),
                    dot(i.TtoW1.xyz, tangentNormal),
                    dot(i.TtoW2.xyz, tangentNormal)
                ));
                
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                
                fixed3 specularColor = lerp(_Specular.rgb, albedo, _Metallic);
                fixed3 specular = _LightColor0.rgb * specularColor * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
                
                fixed shadow = SHADOW_ATTENUATION(i);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
                
                fixed3 color = ambient + (diffuse + specular) * shadow;
                
                return fixed4(color, 1.0);
            }
            ENDCG
        }
        
        Pass
        {
            Tags { "LightMode"="ForwardAdd" }
            Blend One One
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                LIGHTING_COORDS(4, 5)
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            float4 _Specular;
            float _Gloss;
            float _Metallic;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _BumpMap);
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb;
                
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                
                fixed3 worldNormal = normalize(float3(
                    dot(i.TtoW0.xyz, tangentNormal),
                    dot(i.TtoW1.xyz, tangentNormal),
                    dot(i.TtoW2.xyz, tangentNormal)
                ));
                
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                
                fixed3 specularColor = lerp(_Specular.rgb, albedo, _Metallic);
                fixed3 specular = _LightColor0.rgb * specularColor * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
                
                fixed attenuation = LIGHT_ATTENUATION(i);
                fixed3 color = (diffuse + specular) * attenuation;
                
                return fixed4(color, 1.0);
            }
            ENDCG
        }
        
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
    FallBack "Diffuse"
}