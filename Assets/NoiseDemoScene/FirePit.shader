Shader "Unlit/FirePit"
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
                float fireHeight = 0.5f;
                float flameFadeFactor = 2.0f;
                float mask = fireHeight - flameFadeFactor * pow(pixel.uv.y, 3);//saturate(fireHeight - (1.0f - pixel.uv.y)) * 2.0f * (fireWidth - abs(pixel.uv.x - 0.5f));
                mask -= 3.0f * pow((abs(2.0f * (pixel.uv.x - 0.5f) )), 2) ;

                // return fixed4(mask,mask,mask, 1.0f);

                float noise = PerlinNoiseFBM6(96, pixel.uv + float2(0, -_Time.y), 0.12f);
                mask += saturate(pixel.uv.y + 0.3f) * noise;//corrode edges

                // return fixed4(mask,mask,mask, 1.0f);

                // // intensity
                mask *= 1.3f;
                

                //
                float detailMask = 0.6f + PerlinNoiseFBM6(123, pixel.uv + float2(0, -_Time.y), 0.2f);
                float3 albedo = float3(1.5f, 1.5f, 1.0f) * float3(detailMask, pow(detailMask, 3), pow(detailMask, 6));

                float3 res = saturate(mask * 5.0f) * albedo;

                return fixed4(res, 1.0f);
            }
            ENDCG
        }
    }
}
