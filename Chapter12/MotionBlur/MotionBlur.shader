Shader "Custom/MotionBlur"
{
    Properties
    {
        _BlurAmount("Current Frame Weight", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
        }

        ZTest Always
        ZWrite Off
        Cull Off

        Pass
        {
            Name "MOTION_BLUR_ACCUMULATION"

            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment FragAccumulation

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _BlurAmount;
            CBUFFER_END

            half4 FragAccumulation(Varyings input) : SV_Target
            {
                half4 currentColor =
                    SAMPLE_TEXTURE2D_X_LOD(
                        _BlitTexture,
                        sampler_LinearClamp,
                        input.texcoord,
                        _BlitMipLevel);

                return half4(
                    currentColor.rgb,
                    _BlurAmount);
            }

            ENDHLSL
        }
    }

    FallBack Off
}