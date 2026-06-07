Shader "Unity Shaders Book/Chapter 7/Mask Texture"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap("Base Map", 2D) = "white" {}

        _NormalMap("Normal Map", 2D) = "bump"{}
        _NormalScale("Bump Scale", Float) = 1.0

        _SpecularMask("Specular Mask", 2D) = "white"{}
        _SpecularScale("Specular Scale", Float) = 1.0

        _Specular("Specular", Color) = (1, 1, 1, 1)
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
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            TEXTURE2D(_SpecularMask);
            SAMPLER(sampler_SpecularMask);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _NormalScale;
                float _SpecularScale;
                half4 _Specular;
                float _Gloss;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o;

                VertexPositionInputs pos = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs norm = GetVertexNormalInputs(v.normalOS, v.tangentOS);

                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.positionCS = pos.positionCS;
                
                float3 lightDirWS = GetMainLight().direction;
                float3 viewDirWS = GetWorldSpaceViewDir(pos.positionWS);

                float3x3 TBN = float3x3(
                   normalize(norm.tangentWS),
                    normalize(norm.bitangentWS),
                    normalize(norm.normalWS)
                );

                o.lightDir = mul(TBN, lightDirWS);
                o.viewDir = mul(TBN, viewDirWS);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float3 LightDirTS = normalize(i.lightDir);
                float3 ViewDirTS = normalize(i.viewDir);
                
                float4 packedNormal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv);
                float3 normalTS = UnpackNormalScale(packedNormal, _NormalScale);
                //手动实现
                //normalTS.xy *= _NormalScale;
                //normalTS.z = sqry(1.0 - saturate(dot(normalTS, normalTS)))
                Light light = GetMainLight();

                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _BaseColor;
                float diffuseTerm = saturate(dot(normalTS, LightDirTS));
                float3 diffuse = light.color * albedo.rgb * diffuseTerm;

                float3 halfDir = normalize(LightDirTS + ViewDirTS);
                
                float specularMask = SAMPLE_TEXTURE2D(_SpecularMask, sampler_SpecularMask, i.uv).r * _SpecularScale;
                
                float specRaw = pow(saturate(dot(normalTS, halfDir)), _Gloss);

                float3 specular = light.color * _Specular.rgb * specRaw * specularMask;

                return float4(diffuse + specular, 1.0);
            }
            ENDHLSL
        }
    }
}
