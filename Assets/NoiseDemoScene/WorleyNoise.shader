Shader "Unlit/WorleyNoise"
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
                float3 col = WorleyNoiseFBM4(23, pixel.uv, 0.1f);
                // float2 distorted_uv = float2(WorleyNoiseFBM4(123, pixel.uv, 0.2f), WorleyNoiseFBM4(425, pixel.uv, 0.2f));
                // float3 col = WorleyNoise(42, distorted_uv, 0.5f);
                return fixed4(col, 1.0f);
            }
            ENDCG
        }
    }
}
