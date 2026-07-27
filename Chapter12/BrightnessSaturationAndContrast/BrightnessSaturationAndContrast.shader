Shader "Custom/BrightnessSaturationAndContrast"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        ZWrite Off
        Cull Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        float _Brightness;
        float _Saturation;
        float _Contrast;

        // Pass 0: 亮度和饱和度对比度调整
        float4 FragBSC(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            // _BlitTexture 是 Blit.hlsl 中定义的用于后处理采样的纹理
            float4 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord);

            // 1. 调整亮度
            float3 finalColor = color.rgb * _Brightness;

            // 2. 调整饱和度
            float luminance = 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
            float3 luminanceColor = float3(luminance, luminance, luminance);
            finalColor = lerp(luminanceColor, finalColor, _Saturation);

            // 3. 调整对比度
            float3 avgColor = float3(0.5, 0.5, 0.5);
            finalColor = lerp(avgColor, finalColor, _Contrast);

            return float4(finalColor, color.a);
        }

        // Pass 1: 简单拷贝（无任何处理，仅用于把临时渲染纹理画回主屏幕/相机纹理）
        float4 FragCopy(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            return SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord);
        }
        ENDHLSL

        Pass
        {
            Name "BrightnessSaturationAndContrast"
            
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragBSC
            ENDHLSL
        }

        Pass
        {
            Name "BSCCopy"
            
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragCopy
            ENDHLSL
        }
    }
}
