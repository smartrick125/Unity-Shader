using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class GaussianBlurRenderPass : ScriptableRenderPass
{
    private static readonly int iterationsId = Shader.PropertyToID("_Iterations");
    private static readonly int blurSpreadId = Shader.PropertyToID("_BlurSpread");
    private static readonly int downSampleId = Shader.PropertyToID("_DownSample");

    private const string k_GaussianBlurTextureName = "_GaussianBlurTexture";
    private const string k_VerticalPassName = "VerticalGaussianBlurRenderPass";
    private const string k_HorizontalPassName = "HorizontalGaussianBlurRenderPass";

    private GaussianBlurSettings defaultSettings;
    private Material material;
    private RenderTextureDescriptor gaussianBlurTextureDescriptor;
    public GaussianBlurRenderPass(Material material, GaussianBlurSettings defaultSettings)
    {
        this.material = material;
        this.defaultSettings = defaultSettings;

        gaussianBlurTextureDescriptor = new RenderTextureDescriptor(Screen.width, Screen.height,
        RenderTextureFormat.Default, 0);
    }
    private void UpdateGaussianBlurSettings()
    {
        if (material == null) return;
        var volumeComponent =
        VolumeManager.instance.stack.GetComponent<GaussianBlur_CustomValumeComponent>();


        int iterations = volumeComponent.iterations.overrideState ?
           volumeComponent.iterations.value : defaultSettings.iterations;
        float blurSpread = volumeComponent.blurSpread.overrideState ?
            volumeComponent.blurSpread.value : defaultSettings.blurSpread;
        int downSample = volumeComponent.downSample.overrideState ?
            volumeComponent.downSample.value : defaultSettings.downSample;

        material.SetInt(iterationsId, iterations);
        material.SetFloat(blurSpreadId, blurSpread);
        material.SetInt(downSampleId, downSample);

    }
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
        UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

        if (resourceData.isActiveTargetBackBuffer)
            return;
        gaussianBlurTextureDescriptor.width = cameraData.cameraTargetDescriptor.width;
        gaussianBlurTextureDescriptor.height = cameraData.cameraTargetDescriptor.height;
        gaussianBlurTextureDescriptor.depthBufferBits = 0;

        TextureHandle srcCamColor = resourceData.activeColorTexture;
        TextureHandle dst = UniversalRenderer.CreateRenderGraphTexture(renderGraph, gaussianBlurTextureDescriptor, k_GaussianBlurTextureName, false);

        UpdateGaussianBlurSettings();

        if (!srcCamColor.IsValid() || !dst.IsValid())
            return;
        
        RenderGraphUtils.BlitMaterialParameters paraVertical = new(srcCamColor, dst, material, 0);
        renderGraph.AddBlitPass(paraVertical, k_VerticalPassName);
        
        RenderGraphUtils.BlitMaterialParameters paraHorizontal = new(dst, srcCamColor, material, 1);
        renderGraph.AddBlitPass(paraHorizontal, k_HorizontalPassName);
    }

}
