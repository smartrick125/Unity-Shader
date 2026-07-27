using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class EdgeDetection_RenderPass : ScriptableRenderPass
{
    private static readonly int edgesOnlyId = Shader.PropertyToID("_EdgeOnly");
    private static readonly int edgeColorId = Shader.PropertyToID("_EdgeColor");
    private static readonly int backgroundColorId = Shader.PropertyToID("_BackgroundColor");
    private const string k_EdgeTextureName = "_BlurTexture";
    private const string k_PassName = "EdgeDetectionPass";
    private const string k_CopyPassName = "ED_CopyPass";

    private EdgeDetectionSettings defaultSettings;
    private Material material;
    private RenderTextureDescriptor edgeDetection_Descriptor;

    public EdgeDetection_RenderPass(Material material, EdgeDetectionSettings defaultSettings)
    {

        this.material = material;
        this.defaultSettings = defaultSettings;

        edgeDetection_Descriptor = new RenderTextureDescriptor(Screen.width, Screen.height, RenderTextureFormat.Default, 0);
    }
    private void UpdateMaterialSettings()
    {
        if (material == null) return;

        var volumeComponent = VolumeManager.instance.stack.GetComponent<EdgeDetection_CustomVolumeComponent>();

        float edgesOnly = defaultSettings != null ? defaultSettings.edgesOnly : 0f;
        Color edgeColor = defaultSettings != null ? defaultSettings.edgeColor : Color.black;
        Color backgroundColor = defaultSettings != null ? defaultSettings.backgroundColor : Color.white;

        if (volumeComponent != null)
        {
            edgesOnly = volumeComponent.edgesOnly.overrideState ?
                volumeComponent.edgesOnly.value : edgesOnly;
            edgeColor = volumeComponent.edgeColor.overrideState ?
                volumeComponent.edgeColor.value : edgeColor;
            backgroundColor = volumeComponent.backgroundColor.overrideState ?
                volumeComponent.backgroundColor.value : backgroundColor;
        }

        material.SetFloat(edgesOnlyId, edgesOnly);
        material.SetColor(edgeColorId, edgeColor);
        material.SetColor(backgroundColorId, backgroundColor);

    }
    public override void RecordRenderGraph(RenderGraph renderGraph,
    ContextContainer frameData)
    {
        UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
        UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

        if (resourceData.isActiveTargetBackBuffer)
            return;

        edgeDetection_Descriptor.width = cameraData.cameraTargetDescriptor.width;
        edgeDetection_Descriptor.height = cameraData.cameraTargetDescriptor.height;
        edgeDetection_Descriptor.depthBufferBits = 0;

        TextureHandle srcCamColor = resourceData.activeColorTexture;
        TextureHandle dst = UniversalRenderer.CreateRenderGraphTexture(renderGraph, edgeDetection_Descriptor, k_EdgeTextureName, false);

        UpdateMaterialSettings();

        if (!srcCamColor.IsValid() || !dst.IsValid())
            return;

        RenderGraphUtils.BlitMaterialParameters blitToTemp = new(srcCamColor, dst, material, 0);
        renderGraph.AddBlitPass(blitToTemp, k_PassName);
        RenderGraphUtils.BlitMaterialParameters blitBack = new(dst, srcCamColor, material, 1);
        renderGraph.AddBlitPass(blitBack, k_CopyPassName);
    }
}
