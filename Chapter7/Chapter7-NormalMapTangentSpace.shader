Shader "Unity Shaders Book/Chapter 7/Normal Map Tangent Space"
{
    Properties
    {
        _BaseMap("BaseMap",2D)="white"{}
        _BaseColor("Color",Color)=(1,1,1,1)

        _NormalMap("NormalMap",2D)="bump"{}
        _NormalScale("Bump Scale",Range(-2,2))=1

        _SpecularColor("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",Range(8.0,256))=32
    }

    SubShader
    {
        Tags{ "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            Tags{ "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS:POSITION;
                float3 normalOS:NORMAL;
                float4 tangentOS:TANGENT;
                float4 uv:TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS:SV_POSITION;
                float4 uv:TEXCOORD0;

                float3 lightDirTS:TEXCOORD1;
                float3 viewDirTS:TEXCOORD2;
            };

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _SpecularColor;
                
                float4 _BaseMap_ST;
                float4 _NormalMap_ST;
                
                float _Gloss;
                float _NormalScale;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o;

                VertexPositionInputs pos = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs norm = GetVertexNormalInputs(v.normalOS, v.tangentOS);

                o.positionCS = pos.positionCS;
                o.uv.xy = TRANSFORM_TEX(v.uv,_BaseMap);
                o.uv.zw = TRANSFORM_TEX(v.uv,_NormalMap);

                float3x3 TBN = float3x3(
                    norm.tangentWS,
                    norm.bitangentWS,
                    norm.normalWS
                );

                Light light = GetMainLight();

                float3 lightDirWS = light.direction;
                float3 viewDirWS = GetWorldSpaceViewDir(pos.positionWS);

                // 世界 → 切线空间
                o.lightDirTS = mul(TBN, lightDirWS);
                o.viewDirTS  = mul(TBN, viewDirWS);

                return o;
            }

            half4 frag(Varyings i):SV_Target
            { 

                float3 lightDir = normalize(i.lightDirTS);
                float3 viewDir  = normalize(i.viewDirTS);

                float4 packed = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv.zw);
                
                float3 normalTS;
                normalTS.xy = (packed.xy * 2 - 1) * _NormalScale;//解码回真实法线范围
                normalTS.z = sqrt(1 - saturate(dot(normalTS.xy, normalTS.xy)));
                
                //内置函数直接解码 手动在normalMap设置为法线贴图时计算结果不正确
                //float3 normalTS = UnpackNormal(packed) * _NormalScale;
                
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv.xy)* _BaseColor;

                float NdotL = saturate(dot(normalTS,lightDir));

                Light light = GetMainLight();
                
                float3 diffuse = albedo.rgb * light.color * NdotL;

                float3 halfDir = normalize(lightDir + viewDir);
                float spec = pow(saturate(dot(normalTS,halfDir)),_Gloss);
                float3 specular = light.color * _SpecularColor.rgb * spec;

                return float4(diffuse + specular,1);
            }
            ENDHLSL
        }
    }
}