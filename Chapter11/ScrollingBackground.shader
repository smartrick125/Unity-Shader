Shader "Unity Shaders Book/Chapter 11/ScrollingBackground"
{
    Properties
    {
        _MainTex("Base Layer (RGB)", 2D) = "white" {}
        _DetailTex("2nd Layer (RGB)", 2D) = "white" {}
        _ScrollX("Base layer Scroll Speed", Float) = 1.0
        _Scroll2X("2nd layer Scroll Speed", Float) = 1.0
        _Multiplier("Layer Multiplier", Float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_DetailTex);
            SAMPLER(sampler_DetailTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _DetailTex_ST;
                float _ScrollX;
                float _Scroll2X;
                half _Multiplier;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv.xy = TRANSFORM_TEX(input.uv, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
                output.uv.zw = TRANSFORM_TEX(input.uv, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 firstLayer = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy);
                half4 secondLayer = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, input.uv.zw);

                half4 color = lerp(firstLayer, secondLayer, secondLayer.a);
                color.rgb *= _Multiplier;

                return color;
            }

            ENDHLSL
        }
    }
}
