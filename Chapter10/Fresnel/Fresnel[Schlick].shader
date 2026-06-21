Shader "Unity Shaders Book/Chapter 10/Fresnel[Schlick]"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _FresnelScale("Fresnel Scale", Range(0, 1)) = 0.5
        _Cubemap("Reflection Cubemap", Cube) = "" {}
        _FresnelPower("Fresnel Power", Range(0.1, 8)) = 1
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/BSDF.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float3 reflectionDirWS : TEXCOORD3;
            };

            TEXTURECUBE(_Cubemap);
            SAMPLER(sampler_Cubemap);

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half _FresnelScale;
                half _FresnelPower;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                float3 normalWS = normalize(normalInputs.normalWS);
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionInputs.positionWS);

                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.normalWS = normalWS;
                output.viewDirWS = viewDirWS;
                output.reflectionDirWS = reflect(-viewDirWS, normalWS);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half3 normalWS = normalize(input.normalWS);
                half3 viewDirWS = normalize(input.viewDirWS);
                half3 reflectionDirWS = normalize(input.reflectionDirWS);

                Light mainLight = GetMainLight();
                half3 lightDirWS = normalize(mainLight.direction);
                half NdotL = saturate(dot(normalWS, lightDirWS));
                half3 diffuse = mainLight.color * _Color.rgb * NdotL;
                //half3 diffuse =_Color.rgb;

                half3 reflection = SAMPLE_TEXTURECUBE(
                    _Cubemap,
                    sampler_Cubemap,
                    reflectionDirWS
                ).rgb;

                half NdotV = saturate(dot(normalWS, viewDirWS));
                half fresnel = F_Schlick(_FresnelScale, 1.0, NdotV);
                fresnel = pow(saturate(fresnel), _FresnelPower);
                half3 color = lerp(diffuse, reflection, saturate(fresnel));

                return half4(color, 1);
            }

            ENDHLSL
        }
    }
}
