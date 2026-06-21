Shader "Unity Shaders Book/Chapter 10/RealtimeCubemapCapture"
{
    Properties
    {
        _EnvironmentCube("Environment Cube", Cube) = "" {}
        _EnvironmentIntensity("Environment Intensity", Range(0, 2)) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "ForwardLit"
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
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };

            TEXTURECUBE(_EnvironmentCube);
            SAMPLER(sampler_EnvironmentCube);

            CBUFFER_START(UnityPerMaterial)
                float _EnvironmentIntensity;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS);

                OUT.positionHCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;
                OUT.normalWS = normalInputs.normalWS;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 normalWS = NormalizeNormalPerPixel(IN.normalWS);

                // GetWorldSpaceNormalizeViewDir returns the direction from the surface to the camera.
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);

                // The incident view ray points from the camera to the surface, so use -viewDirWS.
                float3 reflectionDirWS = reflect(-viewDirWS, normalWS);

                half3 environmentColor = SAMPLE_TEXTURECUBE(
                    _EnvironmentCube,
                    sampler_EnvironmentCube,
                    reflectionDirWS
                ).rgb;

                environmentColor *= _EnvironmentIntensity;

                return half4(environmentColor, 1);
            }

            ENDHLSL
        }
    }
}
