Shader "Custom/Bloom"
{
    Properties
    {
        _BlurSpread("Blur Spread", Range(0.2, 3.0)) = 1.0
        _LuminanceThreshlod("Luminance Threshlod", Range(0, 4.0)) = 0.6
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        ZTest Always
        ZWrite Off
        Cull Off

        HLSLINCLUDE


        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        TEXTURE2D(_BloomTex);
        SAMPLER(sampler_BloomTex);

        CBUFFER_START(UnityPerMaterial)
            float _BlurSpread;
            float _LuminanceThreshlod;
        CBUFFER_END

        half luminance(half3 c) { return dot(c, half3(0.2125, 0.7154, 0.0721)); }


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

        half4 FragExtractBright(Varyings input) : SV_Target
        {
            half4 c = SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearClamp,
            input.texcoord, _BlitMipLevel);
            half val = clamp(luminance(c.rgb) - _LuminanceThreshlod, 0.0, 1.0);
            return c * val;
        }

        half4 FragVertical(Varyings input) : SV_Target
        {
            return SampleGaussianBlur(input.texcoord, float2(0.0, 1.0));
        }

        half4 FragHorizontal(Varyings input) : SV_Target
        {
            return SampleGaussianBlur(input.texcoord, float2(1.0, 0.0));
        }

        half4 FragCombine(Varyings input) : SV_Target
        {
            /*half4 scene = SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearClamp,
            input.texcoord, _BlitMipLevel);
            half4 bloom = SAMPLE_TEXTURE2D(_BloomTex, sampler_LinearClamp, input.texcoord);
            return scene + bloom;*/
            return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearClamp,
            input.texcoord, _BlitMipLevel);
        }

        /*half4 FragPassThrough(Varyings input) : SV_Target
        {
            return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearClamp,
            input.texcoord, _BlitMipLevel);
            //return half4(1, 0, 0, 1);
        }*/

        ENDHLSL

        Pass
        {
            Name "BLOOM_EXTRACT_BRIGHT"

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment FragExtractBright

            ENDHLSL
        }
        Pass
        {
            Name "BLOOM_BLUR_VERTICAL"

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment FragVertical

            ENDHLSL
        }
        Pass
        {
            Name "BLOOM_BLUR_FragHorizontal"

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment FragHorizontal

            ENDHLSL
        }
        Pass
        {
            Name "BLOOM_COMBINE"

            Blend One One

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment FragCombine

            ENDHLSL
        }

        /*Pass
        {
            Name "BLOOM_COPY_BACK"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragPassThrough
            ENDHLSL
        }*/
    }
}
