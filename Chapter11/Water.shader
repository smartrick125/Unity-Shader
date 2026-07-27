Shader "Unity Shaders Book/Chapter 11/Whater"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _Magnitude("Distortion Magnitude", Float) = 1
        _Frequency("Distortion Frequency", Float) = 1
        _InvWaveLength("Distortion Inverse Wave Length", Float) = 10
        _Speed("Speed", Float) = 0.5
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "DisableBatching" = "True" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

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
                float4 _MainTex_ST;
                half4 _Color;
                float _Magnitude;
                float _Frequency;
                float _InvWaveLength;
                float _Speed;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;

                float3 positionOS = input.positionOS.xyz;
                float wave = sin(
                _Frequency * _Time.y
                + positionOS.x * _InvWaveLength
                + positionOS.y * _InvWaveLength
                + positionOS.z * _InvWaveLength
                ) * _Magnitude;

                positionOS.x += wave;

                output.positionCS = TransformObjectToHClip(positionOS);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.uv += float2(0.0, _Time.y * _Speed);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                color.rgb *= _Color.rgb;
                color.a *= _Color.a;

                return color;
            }

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            float3 _LightDirection;

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;
                float _Magnitude;
                float _Frequency;
                float _InvWaveLength;
                float _Speed;
            CBUFFER_END

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;

                float3 positionOS = input.positionOS.xyz;

                float wave = sin(
                _Frequency * _Time.y
                + positionOS.x * _InvWaveLength
                + positionOS.y * _InvWaveLength
                + positionOS.z * _InvWaveLength
                ) * _Magnitude;
                
                positionOS.x += wave;

                float3 positionWS = TransformObjectToWorld(positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                
                #if UNITY_REVERSED_Z
                    output.positionCS.z = min(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    output.positionCS.z = max(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                return 0;
            }

            ENDHLSL
        }
    }
}
