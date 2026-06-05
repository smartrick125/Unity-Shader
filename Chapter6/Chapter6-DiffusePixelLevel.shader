Shader "Unity Shaders Book/Chapter 6/Diffuse Vertex-Level"
{
    Properties
    {
        [MainColor] _Diffuse("Base Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

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
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _Diffuse;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                
                return OUT;
            }
            
            half4 frag(Varyings IN) : SV_Target
            {
                
                Light light = GetMainLight();

                float3 normalWS = IN.normalWS;
    
                float3 LightDir = normalize(light.direction);
    
                half NdotL = max(0.0, dot(normalWS, LightDir));
    
                half3 finalRGB = light.color * _Diffuse.rgb * NdotL;

                return half4(finalRGB, _Diffuse.a);
            }
            ENDHLSL
        }
    }
}
