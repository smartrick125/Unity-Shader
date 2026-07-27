Shader "CustomEffects/Blur"
{
    HLSLINCLUDE
    
        // 引入 URP 核心着色器库
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        // 引入后处理 Blit 库：提供顶点着色器 Vert、输入结构体 Attributes、输出结构体 Varyings
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        // C# 脚本传入的横向和纵向模糊强度参数
        float _VerticalBlur;
        float _HorizontalBlur;
    
        // Pass 0：纵向模糊（垂直方向采样）
        float4 BlurVertical (Varyings input) : SV_Target
        {
            const float BLUR_SAMPLES = 64;              // 总采样次数
            const float BLUR_SAMPLES_RANGE = BLUR_SAMPLES / 2; // 采样范围（中心向两侧各 32 个点）
            
            float3 color = 0;
            // 根据纵向模糊强度和屏幕高度，计算实际偏移的像素数
            float blurPixels = _VerticalBlur * _ScreenParams.y;
            
            // 从中心向上下两侧逐个采样，累加颜色值
            for(float i = -BLUR_SAMPLES_RANGE; i <= BLUR_SAMPLES_RANGE; i++)
            {
                // 计算纵向偏移量（仅 Y 方向有偏移，X 方向为 0）
                float2 sampleOffset = float2 (0, (blurPixels / _BlitTexture_TexelSize.w) * (i / BLUR_SAMPLES_RANGE));
                // 在偏移位置采样屏幕颜色并累加
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord + sampleOffset).rgb;
            }
            
            // 将累加的颜色除以总采样数，得到均值模糊结果
            return float4(color.rgb / (BLUR_SAMPLES + 1), 1);
        }

        // Pass 1：横向模糊（水平方向采样）
        float4 BlurHorizontal (Varyings input) : SV_Target
        {
            const float BLUR_SAMPLES = 64;              // 总采样次数
            const float BLUR_SAMPLES_RANGE = BLUR_SAMPLES / 2; // 采样范围
            
            // 初始化 VR 立体渲染的眼睛索引（支持 VR 设备）
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float3 color = 0;
            // 根据横向模糊强度和屏幕宽度，计算实际偏移的像素数
            float blurPixels = _HorizontalBlur * _ScreenParams.x;

            // 从中心向左右两侧逐个采样，累加颜色值
            for(float i = -BLUR_SAMPLES_RANGE; i <= BLUR_SAMPLES_RANGE; i++)
            {
                // 计算横向偏移量（仅 X 方向有偏移，Y 方向为 0）
                float2 sampleOffset =
                    float2 ((blurPixels / _BlitTexture_TexelSize.z) * (i / BLUR_SAMPLES_RANGE), 0);
                // 在偏移位置采样屏幕颜色并累加
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord + sampleOffset).rgb;
            }
            // 将累加的颜色除以总采样数，得到均值模糊结果
            return float4(color / (BLUR_SAMPLES + 1), 1);
        }
    
    ENDHLSL
    
    SubShader
    {
        // 标记为不透明渲染，属于 URP 管线
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        // 后处理全屏绘制标配：关闭深度写入，关闭面剔除
        ZWrite Off Cull Off

        // Pass 0：纵向模糊
        Pass
        {
            Name "BlurPassVertical"

            HLSLPROGRAM
            
            #pragma vertex Vert          // 使用 Blit.hlsl 内置的顶点着色器
            #pragma fragment BlurVertical // 使用上方定义的纵向模糊片元着色器
            
            ENDHLSL
        }
        
        // Pass 1：横向模糊
        Pass
        {
            Name "BlurPassHorizontal"

            HLSLPROGRAM
            
            #pragma vertex Vert            // 使用 Blit.hlsl 内置的顶点着色器
            #pragma fragment BlurHorizontal // 使用上方定义的横向模糊片元着色器
            
            ENDHLSL
        }
    }
}
