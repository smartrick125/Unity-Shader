Shader "Unity Shaders Book/Chapter 9/AlphaTestWithSbadow"
{
    Properties {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20

        _Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
        _MainTex("Base Map", 2D) = "white" {}

    }
    SubShader {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="TransparentCutout" "Queue" = "AlphaTest" }
        
        Cull Off
        ZWrite On
        Pass {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            //_MAIN_LIGHT_SHADOWS主光阴影 _MAIN_LIGHT_SHADOWS_CASCADE主光级联阴影 _MAIN_LIGHT_SHADOWS_SCREEN主光屏幕空间阴影
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            //_ADDITIONAL_LIGHT_SHADOWS额外光阴影
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            //_SHADOWS_SOFT软阴影
            //#pragma multi_compile_fragment _ _SHADOWS_SOFT
            // This multi_compile declaration is required for the Forward rendering path
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            // This multi_compile declaration is required for the Forward+ rendering path
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
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
                float3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                //Shadow Cascade
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord : TEXCOORD2;
                #endif
                float2 uv : TEXCOORD3;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _Diffuse;
                half4 _Specular;
                float _Gloss;
                float _Cutoff;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                VertexPositionInputs pos = GetVertexPositionInputs(IN.positionOS.xyz);
                
                OUT.positionCS = pos.positionCS;
                OUT.positionWS = pos.positionWS;
                VertexNormalInputs nor = GetVertexNormalInputs(IN.normalOS);

                OUT.normalWS = nor.normalWS;
                //Shadow Cascade
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    OUT.shadowCoord = GetShadowCoord(pos);
                #endif
                OUT.uv = IN.uv;
                return OUT;
            }

            float3 MyLightingFunction(
            float3 normalWS,
            float3 positionWS,//
            float3 viewDirectionWS,
            Light light
            )
            {
                float3 lightDir = normalize(light.direction);
                float3 halfDir = normalize(lightDir + viewDirectionWS);
                normalWS = normalize(normalWS);

                float NdotL = max(0, dot(normalWS, lightDir));
                float NdotH = max(0, dot(normalWS, halfDir));

                float3 diffuse = light.color * _Diffuse.rgb * NdotL;
                float3 specular = light.color * _Specular.rgb * pow(NdotH, _Gloss);

                return (diffuse + specular) * light.distanceAttenuation * light.shadowAttenuation;
            }

            float3 MyLightLoop(float3 color, InputData inputData)
            {
                float3 lighting = 0;
                
                // Get the main light
                Light mainLight = GetMainLight(inputData.shadowCoord);
                lighting += MyLightingFunction(inputData.normalWS, inputData.positionWS, inputData.viewDirectionWS, mainLight);
                // Get additional lights
                #if defined(_ADDITIONAL_LIGHTS)

                    #if USE_CLUSTER_LIGHT_LOOP
                        UNITY_LOOP for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
                        {
                            Light additionalLight = GetAdditionalLight(lightIndex, inputData.positionWS, half4(1,1,1,1));
                            lighting += MyLightingFunction(inputData.normalWS, inputData.positionWS, inputData.viewDirectionWS, additionalLight);
                        }
                    #endif
                    
                    // Additional light loop.
                    uint pixelLightCount = GetAdditionalLightsCount();
                    LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light additionalLight = GetAdditionalLight(lightIndex, inputData.positionWS, half4(1,1,1,1));
                    lighting += MyLightingFunction(inputData.normalWS, inputData.positionWS, inputData.viewDirectionWS, additionalLight);
                    LIGHT_LOOP_END
                    
                #endif
                
                return color * lighting;

            }

            half4 frag(Varyings input) : SV_Target
            {
                InputData inputData = (InputData)0;

                inputData.positionWS = input.positionWS;
                inputData.normalWS = input.normalWS;
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                //Simple lit
                //inputData.shadowCoord = input.shadowCoord;
                //Shadow Cascade
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif
                
                half4 surfaceColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                clip(surfaceColor.a < _Cutoff ? -1:1 );

                float3 lighting = MyLightLoop(surfaceColor, inputData);

                half4 finalColor = half4(lighting, 1);
                return finalColor;

            }
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv : TEXCOORD0;
                
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float _Cutoff;
                float3 _LightDirection;
            CBUFFER_END


            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

                #if UNITY_REVERSED_Z
                    output.positionCS.z = min(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    output.positionCS.z = max(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                output.uv = input.uv;
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                half alpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).a;
                clip(alpha < _Cutoff ? -1:1 );
                return 0;
            }

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }

            ZWrite On
            ZTest LEqual
            Cull Off

            HLSLPROGRAM
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _Diffuse;
                half4 _Specular;
                float _Gloss;
                float _Cutoff;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            Varyings DepthNormalsVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;
                return output;
            }

            half4 DepthNormalsFragment(Varyings input) : SV_Target
            {
                half alpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).a;
                clip(alpha - _Cutoff);

                float3 normalWS = NormalizeNormalPerPixel(input.normalWS);
                return half4(normalWS, 0);
            }
            ENDHLSL
        }
    }
}
