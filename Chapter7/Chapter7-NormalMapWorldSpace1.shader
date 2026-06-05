Shader "Unity Shaders Book/Chapter 7/Normal Map World Space1"
{
    Properties
    {
        _BaseMap("BaseMap",2D)="white"{}
        _BaseColor("Color",Color)=(1,1,1,1)

        _NormalMap("NormalMap",2D)="bump"{}
        _NormalScale("Bump Scale",Range(-2,2))=1

        _SpecularColor("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",Range(8,256))=32
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
                float2 uv:TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS:SV_POSITION;
                float4 uv:TEXCOORD0;

                float4 normalWS:TEXCOORD1;
                float4 tangentWS:TEXCOORD2;
                float4 bitangentWS:TEXCOORD3;
            };

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _NormalMap_ST;

                half4 _BaseColor;
                half4 _SpecularColor;

                float _Gloss;
                float _NormalScale;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o;

                VertexPositionInputs pos = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs norm = GetVertexNormalInputs(v.normalOS, v.tangentOS);

                o.positionCS = pos.positionCS;
                float3 positionWS = pos.positionWS;

                o.uv.xy = TRANSFORM_TEX(v.uv,_BaseMap);
                o.uv.zw = TRANSFORM_TEX(v.uv,_NormalMap);

                o.normalWS = float4(norm.normalWS.xyz, positionWS.x);
                o.tangentWS = float4(norm.tangentWS.xyz, positionWS.y);
                o.bitangentWS = float4(norm.bitangentWS.xyz, positionWS.z);

                return o;
            }

            half4 frag(Varyings i):SV_Target
            {
                
                float4 packed = SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,i.uv.zw);
                
                float3 normalTS;
                normalTS.xy = (packed.xy * 2 - 1) * _NormalScale;
                normalTS.z = sqrt(1 - saturate(dot(normalTS.xy,normalTS.xy)));
                
                float3x3 TBN = float3x3(
                    normalize(i.tangentWS.xyz),
                    normalize(i.bitangentWS.xyz),
                    normalize(i.normalWS.xyz)
                    );
                    
                float3 normalWS = normalize(mul(TBN, normalTS));
                
                Light light = GetMainLight();
                float3 lightDir = normalize(light.direction);
                
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv.xy)*_BaseColor;
                float NdotL = saturate(dot(normalWS,lightDir));
                float3 diffuse = albedo.rgb * light.color * NdotL;
                
                float3 positionWS = float3(i.normalWS.w, i.tangentWS.w, i.bitangentWS.w);
                float3 viewDir = normalize(GetWorldSpaceViewDir(positionWS));
                float3 halfDir = normalize(lightDir + viewDir);
                    
                float spec = pow(saturate(dot(normalWS,halfDir)),_Gloss);
                float3 specular = light.color * _SpecularColor.rgb * spec;
                    
                return float4(diffuse + specular,1);
                }
            ENDHLSL
        }
    }
}