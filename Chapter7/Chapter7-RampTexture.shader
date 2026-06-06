Shader "Unity Shaders Book/Chapter 7/Ramp Texture"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _RampTex("Ramp Tex", 2D) = "white" {}
        _SpecularColor("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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

            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _SpecularColor;
                float _Gloss;
            CBUFFER_END

            Varyings vert(Attributes i)
            {
                Varyings v;
                VertexPositionInputs posInputs = GetVertexPositionInputs(i.positionOS.xyz);
                VertexNormalInputs normInputs = GetVertexNormalInputs(i.normalOS);

                v.normalWS = normInputs.normalWS;
                v.positionWS = posInputs.positionWS;
                v.positionCS = posInputs.positionCS;

                return v;
            }

            half4 frag(Varyings v) : SV_Target
            {
                float3 normalWS = normalize(v.normalWS);

                Light light = GetMainLight();
                float3 lightDir = normalize(light.direction);
                
                float NdotL = dot(lightDir, normalWS);
                float halfLambert = (NdotL * 0.5) + 0.5;

                half3 rampColor = SAMPLE_TEXTURE2D(
                    _RampTex
                    , sampler_RampTex
                    , float2(halfLambert, 0.5)
                ).rgb;
                
                half3 diffuse = rampColor * _BaseColor.rgb * light.color;

                float3 viewDir = normalize(GetWorldSpaceViewDir(v.positionWS));
                float3 halfDir = normalize(lightDir + viewDir);
                
                float spec = pow(saturate(dot(normalWS, halfDir)), _Gloss);
                float3 specular = light.color * _SpecularColor.rgb * spec;

                return float4(diffuse + specular, 1.0);
            }
            ENDHLSL
        }
    }
}
