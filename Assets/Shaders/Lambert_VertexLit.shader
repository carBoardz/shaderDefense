Shader "Custom/Lambert_VertexLit"
{
    Properties
    {
        _Diffuse ("Diffuse Color", Color) = (1, 1, 1, 1)
        _MainTex ("Main Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            
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
                fixed4 color : TEXCOORD1;
            };
            
            fixed4 _Diffuse;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                // ===== 逐顶点计算光照 =====
                // 世界空间法线
                float3 worldNormal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
                
                // 主光源方向
                float3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                // Lambert 漫反射：max(0, N·L)
                fixed diffuse = max(0, dot(worldNormal, worldLightDir));
                
                // 光照颜色
                fixed3 lightColor = _LightColor0.rgb * _Diffuse.rgb * diffuse;
                
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * _Diffuse.rgb;
                
                // 保存到 color 变量，传递给片元着色器
                o.color = fixed4(ambient + lightColor, 1.0);
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // 片元着色器只需采样纹理并与顶点计算的颜色相乘
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;
                return fixed4(i.color.rgb * albedo, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}