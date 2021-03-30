Shader "Unlit/FirePit2"
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
                // float mask = 1.0f - pixel.uv.y; //vertical
                // mask -= abs(2.0f * (pixel.uv.x - 0.5f)); //horizontal
                // return fixed4(mask,mask,mask, 1.0f);

                float fireHeight = 0.5f;
                float flameFadeFactor = 2.0f;
                float mask = fireHeight - flameFadeFactor * pow(pixel.uv.y, 2);
                mask -= 3.0f * pow((abs(2.0f * (pixel.uv.x - 0.5f) )), 2) ;
                // return fixed4(mask,mask,mask, 1.0f);

                float noise = PerlinNoiseTilingFBM6(96, (pixel.uv + float2(0, -_Time.y)), 0.12f);//todo: tiling perlin noise
                mask += saturate(pixel.uv.y + 0.3f) * noise;//corrode edges
                // return fixed4(mask,mask,mask, 1.0f);

                // intensify
                mask *= 1.8f; //1.8x
                float detailMask = mask;
                float3 albedo = float3(1.8f, 1.5f, 1.0f) * float3(detailMask, pow(detailMask, 2), pow(detailMask, 3));//detail mask >1, the growth of pow() starts to domain
                float3 res = saturate(albedo) * saturate(mask * 5.0f);

                // float3 res = float3(0,0,0);
                return fixed4(res, 1.0f);
            }
            ENDCG
        }
    }
}
