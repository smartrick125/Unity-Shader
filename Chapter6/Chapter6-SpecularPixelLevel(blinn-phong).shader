Shader "Unity Shaders Book/Chapter 6/Specular Pixel-Level(blinn-phong)"
{
    Properties
    {
        _Diffuse("Base Color", Color) = (1, 1, 1, 1)
        _Specular("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Tags {"LightMode" = "UniversalForward"}

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
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _Diffuse;
                float4 _Specular;
                float _Gloss;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                Light light = GetMainLight();
                float3 lightDir = normalize(light.direction);

                float3 normalWS = normalize(IN.normalWS);
                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.positionWS.xyz);

                half NdotL = max(0.0, dot(normalWS, lightDir));

                half3 diffuse = light.color * _Diffuse.rgb * NdotL;


                float3 h = normalize(viewDir + lightDir);

                half3 specular = light.color * _Specular.rgb
                * pow(max(0.0, dot(normalWS, h)), _Gloss) * step(0.0, NdotL);

                half3 finalRGB = (diffuse + specular);

                return float4(finalRGB, _Diffuse.a);
            }
            ENDHLSL
        }
    }
}
