Shader "Unity Shaders Book/Chapter 8/Alpha Blend ZWrite"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap("Base Map", 2D) = "white" {}
        _AlphaScale("Alpha Scale", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent" 
            }
        Pass
        {
            Tags{"LightMode" = "DepthOnly"}
            ZWrite On
            ColorMask 0
        }
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
             
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half _AlphaScale;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv;
                return OUT;
            }
            
            half4 frag(Varyings IN) : SV_Target
            {   
                Light light = GetMainLight();
                float3 normalWS = normalize(IN.normalWS);
                float3 lightDir = normalize(light.direction);

                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);

                float3 albedo = texColor.rgb * _BaseColor.rgb;
                float3 diffuse = light.color.rgb * albedo * max(0, dot(normalWS, lightDir));

                return float4(diffuse, texColor.a * _BaseColor.a * _AlphaScale);
            }
            ENDHLSL
        }
    }
}
