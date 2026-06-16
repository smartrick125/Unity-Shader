Shader "Unity Shaders Book/Chapter 9/AcceptShadow_cascade"
{
	Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Tags
		{ 
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue" = "Geometry"
		}
		
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
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				float3 positionWS : TEXCOORD1;
				//Simple lit
                //float4 shadowCoord : TEXCOORD2;
				//Shadow Cascade
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord : TEXCOORD2;
                #endif
            };

			CBUFFER_START(UnityPerMaterial)
				half4 _Diffuse;
				half4 _Specular;
				float _Gloss;
			CBUFFER_END
			
			Varyings vert(Attributes IN)
			{
				Varyings OUT;
                VertexPositionInputs pos = GetVertexPositionInputs(IN.positionOS.xyz);
                
				OUT.positionCS = pos.positionCS;
				OUT.positionWS = pos.positionWS;
                VertexNormalInputs nor = GetVertexNormalInputs(IN.normalOS);

				OUT.normalWS = nor.normalWS;
				//Simple lit
                //OUT.shadowCoord = GetShadowCoord(pos);
				//Shadow Cascade
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                OUT.shadowCoord = GetShadowCoord(pos);
                #endif

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

                float3 surfaceColor = float3(1, 1, 1);
                float3 lighting = MyLightLoop(surfaceColor, inputData);

				half4 finalColor = half4(lighting, 1);  
                return finalColor;

			}
			ENDHLSL
		}
	}
}
