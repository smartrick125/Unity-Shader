Shader "Unity Shaders Book/Chapter 11/ImageSequenceAnimation"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex("Image Sequence", 2D) = "white" {}
        _HorizontalAmount("Horizontal Amount", Float) = 4
        _VerticalAmount("Vertical Amount", Float) = 4
        _Speed("Speed", Range(1, 100)) = 30
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

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
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                float4 _MainTex_ST;
                float _HorizontalAmount;
                float _VerticalAmount;
                float _Speed;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float frameCount = _HorizontalAmount * _VerticalAmount;
                float currentFrame = floor(_Time.y * _Speed);
                currentFrame = fmod(currentFrame, frameCount);

                float row = floor(currentFrame / _HorizontalAmount);
                float column = currentFrame - row * _HorizontalAmount;

                float2 sequenceUV = input.uv + float2(column, -row);
                sequenceUV.x /= _HorizontalAmount;
                sequenceUV.y /= _VerticalAmount;

                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, sequenceUV);
                color.rgb *= _Color.rgb;
                color.a *= _Color.a;

                return color;
            }

            ENDHLSL
        }
    }
}
