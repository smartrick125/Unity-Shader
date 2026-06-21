Shader "Unity Shaders Book/Chapter 10/URPReflection"
{
    Properties
    {
        _ReflectColor("Reflection Color", Color) = (1, 1, 1, 1)
        _Cubemap("Reflection Cubemap", Cube) = "" {}
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
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 reflectionDirWS : TEXCOORD0;
            };

            TEXTURECUBE(_Cubemap);
            SAMPLER(sampler_Cubemap);

            CBUFFER_START(UnityPerMaterial)
                half4 _ReflectColor;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionInputs.positionWS);

                output.positionCS = positionInputs.positionCS;
                output.reflectionDirWS = reflect(-viewDirWS, normalInputs.normalWS);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half3 reflectionDirWS = normalize(input.reflectionDirWS);

                half3 reflection = SAMPLE_TEXTURECUBE(
                    _Cubemap,
                    sampler_Cubemap,
                    reflectionDirWS
                ).rgb * _ReflectColor.rgb;

                return half4(reflection, 1);
            }

            ENDHLSL
        }
    }
}
