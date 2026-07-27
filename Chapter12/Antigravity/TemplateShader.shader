Shader "Hidden/Custom/TemplateShader"
{
    SubShader
    {
        // 标记为不透明渲染，且属于 URP 管线
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        
        // 写入深度关掉，剔除关掉（后处理全屏绘制标配）
        ZWrite Off
        Cull Off

        HLSLINCLUDE
        // 引入 URP 核心库与后处理 Blit 库
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        // 声明 C# 传递过来的常量参数
        float _Intensity;
        float4 _TintColor;

        // ----------------------------------------------------
        // Pass 0: 核心图像特效计算逻辑
        // ----------------------------------------------------
        float4 FragDraw(Varyings input) : SV_Target
        {
            // 初始化立体渲染眼睛索引（支持 VR 等）
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            // 采样摄像机输入颜色。_BlitTexture 和 sampler_LinearClamp 是 Blit.hlsl 中定义的
            float4 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord);

            // 特效计算：例如根据强度进行简单的颜色混合
            float3 finalColor = lerp(color.rgb, color.rgb * _TintColor.rgb, _Intensity);

            return float4(finalColor, color.a);
        }

        // ----------------------------------------------------
        // Pass 1: 简单拷贝 Pass（用于把临时纹理无损画回屏幕）
        // ----------------------------------------------------
        float4 FragCopy(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            return SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord);
        }
        ENDHLSL

        // Pass 0
        Pass
        {
            Name "TemplateDraw"
            
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragDraw
            ENDHLSL
        }

        // Pass 1
        Pass
        {
            Name "TemplateCopy"
            
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragCopy
            ENDHLSL
        }
    }
}
