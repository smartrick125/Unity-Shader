Shader "Custom/EdgeDetection"
{
    Properties
    {
        _EdgeOnly ("Edge Only", Range(0, 1)) = 1
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        _BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
    }

    HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        half _EdgeOnly;
        half4 _EdgeColor;
        half4 _BackgroundColor;

        half Luminance(half3 color)
        {
            return dot(color, half3(0.2125h, 0.7154h, 0.0721h));
        }

        half Sobel(float2 uv)
        {
            const half Gx[9] =
            {
                -1.0h,  0.0h,  1.0h,
                -2.0h,  0.0h,  2.0h,
                -1.0h,  0.0h,  1.0h
            };

            const half Gy[9] =
            {
                -1.0h, -2.0h, -1.0h,
                 0.0h,  0.0h,  0.0h,
                 1.0h,  2.0h,  1.0h
            };

            const float2 offsets[9] =
            {
                float2(-1.0, -1.0),
                float2( 0.0, -1.0),
                float2( 1.0, -1.0),
                float2(-1.0,  0.0),
                float2( 0.0,  0.0),
                float2( 1.0,  0.0),
                float2(-1.0,  1.0),
                float2( 0.0,  1.0),
                float2( 1.0,  1.0)
            };

            half edgeX = 0.0h;
            half edgeY = 0.0h;

            [unroll]
            for (int index = 0; index < 9; ++index)
            {
                float2 sampleUV = uv + offsets[index] * _BlitTexture_TexelSize.xy;
                half3 sampleColor = SAMPLE_TEXTURE2D(
                    _BlitTexture,
                    sampler_LinearClamp,
                    sampleUV).rgb;

                half sampleLuminance = Luminance(sampleColor);
                edgeX += sampleLuminance * Gx[index];
                edgeY += sampleLuminance * Gy[index];
            }

            // 0 means edge, 1 means non-edge. This matches the book's lerp logic.
            return saturate(1.0h - abs(edgeX) - abs(edgeY));
        }

        half4 FragEdgeDetection(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float2 uv = input.texcoord;
            half4 sourceColor = SAMPLE_TEXTURE2D(
                _BlitTexture,
                sampler_LinearClamp,
                uv);

            half edge = Sobel(uv);
            half4 sourceWithEdges = lerp(_EdgeColor, sourceColor, edge);
            half4 edgesOnly = lerp(_EdgeColor, _BackgroundColor, edge);

            return lerp(sourceWithEdges, edgesOnly, saturate(_EdgeOnly));
        }

        half4 FragCopy(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            return SAMPLE_TEXTURE2D(
                _BlitTexture,
                sampler_LinearClamp,
                input.texcoord);
        }

    ENDHLSL

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

        Pass
        {
            Name "EdgeDetection"

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragEdgeDetection
            ENDHLSL
        }

        Pass
        {
            Name "Copy"

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragCopy
            ENDHLSL
        }
    }

    FallBack Off
}
