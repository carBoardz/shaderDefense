Shader "Custom/ForwardRendering_Phong"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Specular ("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8, 256)) = 64
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        
        // ForwardBase Pass：处理主光源 + 环境光 + 阴影
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
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Specular;
            float _Gloss;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_SHADOW(o);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // 采样主纹理
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;
                
                // 世界空间法线（归一化）
                fixed3 worldNormal = normalize(i.worldNormal);
                
                // 主光源方向
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                // 视角方向
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                
                // ===== Phong 高光模型 =====
                // R = reflect(-L, N)，计算反射向量
                fixed3 reflectDir = reflect(-worldLightDir, worldNormal);
                
                // 高光 = pow(max(0, dot(V, R)), gloss)
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * 
                                  pow(max(0, dot(viewDir, reflectDir)), _Gloss);
                
                // ===== 漫反射 =====
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                
                // ===== 阴影 =====
                fixed shadow = SHADOW_ATTENUATION(i);
                
                // ===== 环境光 =====
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
                
                // ===== 最终颜色 = 主光源 + 环境光 =====
                fixed3 color = ambient + (diffuse + specular) * shadow;
                
                return fixed4(color, 1.0);
            }
            ENDCG
        }
        
        // ForwardAdd Pass：处理附加光源（叠加）
        Pass
        {
            Tags { "LightMode"="ForwardAdd" }
            // 使用 One One 混合模式，实现光源叠加
            Blend One One
            // 关闭深度写入，避免遮挡主光源
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // 使用 fullshadows 支持点光源和聚光灯的阴影
            #pragma multi_compile_fwdadd_fullshadows
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                LIGHTING_COORDS(3, 4)
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Specular;
            float _Gloss;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // 采样主纹理
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;
                
                // 世界空间法线
                fixed3 worldNormal = normalize(i.worldNormal);
                
                // ===== 处理不同类型的光源（点光源、聚光灯） =====
                // _WorldSpaceLightPos0 对于点光源是位置，对于平行光是方向
                #if defined (POINT) || defined (SPOT)
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #endif
                
                // 视角方向
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                
                // ===== Phong 高光模型 =====
                fixed3 reflectDir = reflect(-worldLightDir, worldNormal);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * 
                                  pow(max(0, dot(viewDir, reflectDir)), _Gloss);
                
                // 漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                
                // ===== 光照衰减 =====
                fixed attenuation = LIGHT_ATTENUATION(i);
                
                // ===== 最终颜色 = 附加光源 * 衰减 =====
                fixed3 color = (diffuse + specular) * attenuation;
                
                return fixed4(color, 1.0);
            }
            ENDCG
        }
        
        // 使用内置阴影 Pass
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
    FallBack "Diffuse"
}