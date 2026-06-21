Shader "Unity Shaders Book/Chapter 10/URPRefraction"
{
    Properties
    {
        _RefractColor("Refraction Color", Color) = (1, 1, 1, 1)
        _RefractRatio("Refraction Ratio", Range(0.1, 1)) = 0.67
        _Cubemap("Refraction Cubemap", Cube) = "" {}
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
                float3 refractionDirWS : TEXCOORD0;
            };

            TEXTURECUBE(_Cubemap);
            SAMPLER(sampler_Cubemap);

            CBUFFER_START(UnityPerMaterial)
                half4 _RefractColor;
                half _RefractRatio;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionInputs.positionWS);

                output.positionCS = positionInputs.positionCS;
                output.refractionDirWS = refract(-viewDirWS, normalInputs.normalWS, _RefractRatio);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half3 refractionDirWS = normalize(input.refractionDirWS);

                half3 refraction = SAMPLE_TEXTURECUBE(
                    _Cubemap,
                    sampler_Cubemap,
                    refractionDirWS
                ).rgb * _RefractColor.rgb;

                return half4(refraction, 1);
            }

            ENDHLSL
        }
    }
}
