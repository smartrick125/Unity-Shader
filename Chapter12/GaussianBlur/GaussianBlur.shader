Shader "Custom/GaussianBlur"
{
    Properties
    {
        _BlurSpread("Blur Spread", Range(0.2, 3.0)) = 1.0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        ZTest Always
        ZWrite Off
        Cull Off

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float _BlurSpread;
        CBUFFER_END

        half4 SampleGaussianBlur(float2 uv, float2 direction)
        {
            float2 offset = _BlitTexture_TexelSize.xy * direction * _BlurSpread;

            half4 color =
                SAMPLE_TEXTURE2D_X_LOD(
                    _BlitTexture,
                    sampler_LinearClamp,
                    uv,
                    _BlitMipLevel) * 0.4026h;

            color +=
                SAMPLE_TEXTURE2D_X_LOD(
                    _BlitTexture,
                    sampler_LinearClamp,
                    uv + offset,
                    _BlitMipLevel) * 0.2442h;

            color +=
                SAMPLE_TEXTURE2D_X_LOD(
                    _BlitTexture,
                    sampler_LinearClamp,
                    uv - offset,
                    _BlitMipLevel) * 0.2442h;

            color +=
                SAMPLE_TEXTURE2D_X_LOD(
                    _BlitTexture,
                    sampler_LinearClamp,
                    uv + offset * 2.0,
                    _BlitMipLevel) * 0.0545h;

            color +=
                SAMPLE_TEXTURE2D_X_LOD(
                    _BlitTexture,
                    sampler_LinearClamp,
                    uv - offset * 2.0,
                    _BlitMipLevel) * 0.0545h;

            return half4(color.rgb, 1.0h);
        }

        half4 FragVertical(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            return SampleGaussianBlur(input.texcoord, float2(0.0, 1.0));
        }

        half4 FragHorizontal(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            return SampleGaussianBlur(input.texcoord, float2(1.0, 0.0));
        }

        ENDHLSL

        Pass
        {
            Name "GAUSSIAN_BLUR_VERTICAL"

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment FragVertical

            ENDHLSL
        }

        Pass
        {
            Name "GAUSSIAN_BLUR_HORIZONTAL"

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment FragHorizontal

            ENDHLSL
        }
    }

    FallBack Off
}
