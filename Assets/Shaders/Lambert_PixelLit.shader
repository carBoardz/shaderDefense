Shader "Custom/Lambert_PixelLit"
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
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };
            
            fixed4 _Diffuse;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                // 顶点着色器仅做坐标与法线传递
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // ===== 逐像素计算光照 =====
                // 采样纹理
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;
                
                // 世界空间法线（片元级归一化）
                fixed3 worldNormal = normalize(i.worldNormal);
                
                // 主光源方向
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                // Lambert 漫反射：max(0, N·L)
                fixed diffuse = max(0, dot(worldNormal, worldLightDir));
                
                // 光照颜色
                fixed3 lightColor = _LightColor0.rgb * _Diffuse.rgb * diffuse * albedo;
                
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * _Diffuse.rgb * albedo;
                
                return fixed4(ambient + lightColor, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}