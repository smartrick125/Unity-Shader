Shader "Custom/Billboard"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _VerticalBillboarding("Vertical Restraints", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "DisableBatching" = "True"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;
                half _VerticalBillboarding;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;

                float3 center = float3(0.0, 0.0, 0.0);
                float3 viewerOS = TransformWorldToObject(GetCameraPositionWS());

                float3 normalDir = viewerOS - center;
                normalDir.y *= _VerticalBillboarding;
                normalDir = normalize(normalDir);

                float3 upDir = abs(normalDir.y) > 0.999
                    ? float3(0.0, 0.0, 1.0)
                    : float3(0.0, 1.0, 0.0);

                float3 rightDir = normalize(cross(upDir, normalDir));
                upDir = normalize(cross(normalDir, rightDir));

                float3 centerOffset = input.positionOS.xyz - center;
                float3 localPos =
                    center
                    + rightDir * centerOffset.x
                    + upDir * centerOffset.y
                    + normalDir * centerOffset.z;

                output.positionCS = TransformObjectToHClip(localPos);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                color.rgb *= _Color.rgb;
                color.a *= _Color.a;

                return color;
            }

            ENDHLSL
        }
    }
}
