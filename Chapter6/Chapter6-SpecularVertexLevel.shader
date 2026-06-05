Shader "Unity Shaders Book/Chapter 6/Specular Vertex-Level"
{
    Properties
    {
        [MainColor] _Diffuse("Base Color", Color) = (1, 1, 1, 1)
        _Specular("Specular Color", color) = (1, 1, 1, 1)
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
                float4 positionHCS : SV_POSITION;
                // 存储计算好的顶点光照颜色
                half3 color : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _Diffuse;
                half4 _Specular;
                float _Gloss;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                float3 normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                Light light = GetMainLight();
                float3 lightDir = normalize(light.direction);
                //Diffuse
                half NdotL = max(0.0, dot(normalWS, lightDir));
                half3 diffuse = light.color * _Diffuse.rgb * NdotL;
                //Specular
                    //lightDir一般获取的是从物体指向光源的方向
                float3 reflectDir = normalize(reflect(-lightDir, normalWS));
                    //获取一个指向摄像机的向量
                float3 viewDir = normalize(_WorldSpaceCameraPos - positionWS);

                half3 specular = light.color * _Specular.rgb 
                * pow(max(0.0, dot(viewDir, reflectDir)), _Gloss) * step(0.0, NdotL);

                OUT.color = diffuse + specular;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                return half4(IN.color, _Diffuse.a);
            }
            ENDHLSL
        }
    }
}
