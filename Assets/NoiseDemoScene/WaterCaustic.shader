Shader "Unlit/WaterCaustic"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "../Common/PerlinWorleyNoiseGenerator.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f pixel) : SV_Target
            {
                // float2 uv_offset = 0.07f * float2(PerlinNoise(32, pixel.uv, 0.1f), PerlinNoise(525, pixel.uv, 0.1f));
                // float2 uv_offset_temporal = float2(sin(_Time.x), cos(_Time.x));
                // float3 col = pow(WorleyNoise(42, pixel.uv + uv_offset + uv_offset_temporal, 0.1f), 5); 
                // float3 mask = saturate(0.7f + PerlinNoise(421, pixel.uv, 0.05f));
                // float3 baseColor = float3(0.3f, 0.7f, 1.0f);
                // return fixed4(baseColor + col * mask, 1.0f);
                float2 uv_offset = 0.07f * float2(PerlinNoise(32, pixel.uv, 0.1f), PerlinNoise(525, pixel.uv, 0.1f));
                float2 uv_offset_temporal = float2(sin(_Time.x), cos(_Time.x));
                float3 col = pow(WorleyNoise(42, pixel.uv + uv_offset + uv_offset_temporal, 0.1f), 5);
                float3 mask = saturate(0.7f + PerlinNoise(421, pixel.uv, 0.05f));
                float3 baseColor = float3(0.3f, 0.7f, 1.0f);
                return fixed4(baseColor + col * mask, 1.0f);
            }
            ENDCG
        }
    }
}
