Shader "Unity Shaders Book/Chapter 10/GlassRefraction"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _Cubemap("Environment Cubemap", Cube) = "" {}
        _Distortion("Distortion", Range(0, 100)) = 10
        _RefractAmount("Refract Amount", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float2 uvMain : TEXCOORD1;
                float2 uvBump : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                half3 normalWS : TEXCOORD4;
                half3 tangentWS : TEXCOORD5;
                half3 bitangentWS : TEXCOORD6;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURECUBE(_Cubemap);
            SAMPLER(sampler_Cubemap);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _BumpMap_ST;
                half _Distortion;
                half _RefractAmount;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                half3 normalWS = normalize(normalInputs.normalWS);
                half3 tangentWS = normalize(TransformObjectToWorldDir(input.tangentOS.xyz));
                half tangentSign = input.tangentOS.w * GetOddNegativeScale();
                half3 bitangentWS = normalize(cross(normalWS, tangentWS) * tangentSign);

                output.positionCS = positionInputs.positionCS;
                output.screenPos = ComputeScreenPos(positionInputs.positionCS);
                output.uvMain = TRANSFORM_TEX(input.uv, _MainTex);
                output.uvBump = TRANSFORM_TEX(input.uv, _BumpMap);
                output.positionWS = positionInputs.positionWS;
                output.normalWS = normalWS;
                output.tangentWS = tangentWS;
                output.bitangentWS = bitangentWS;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uvBump));

                float2 screenUV = input.screenPos.xy / input.screenPos.w;
                float2 offset = normalTS.xy * _Distortion * _CameraOpaqueTexture_TexelSize.xy;
                half3 refrCol = SampleSceneColor(screenUV + offset);

                half3 normalWS = normalize(input.normalWS);
                half3 tangentWS = normalize(input.tangentWS);
                half3 bitangentWS = normalize(input.bitangentWS);
                half3x3 tangentToWorld = half3x3(tangentWS, bitangentWS, normalWS);
                half3 bumpWS = normalize(mul(normalTS, tangentToWorld));

                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                half3 reflDirWS = reflect(-viewDirWS, bumpWS);
                half3 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uvMain).rgb;
                half3 reflCol = SAMPLE_TEXTURECUBE(_Cubemap, sampler_Cubemap, reflDirWS).rgb * texColor;

                half3 finalColor = lerp(reflCol, refrCol, _RefractAmount);

                return half4(finalColor, 1);
            }

            ENDHLSL
        }
    }
}
