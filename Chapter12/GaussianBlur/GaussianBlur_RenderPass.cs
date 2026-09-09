using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class GaussianBlurRenderPass : ScriptableRenderPass
{
    private static readonly int blurSpreadId = Shader.PropertyToID("_BlurSpread");

    private const string k_GaussianBlurTextureNameA = "_GaussianBlurTextureA";
    private const string k_GaussianBlurTextureNameB = "_GaussianBlurTextureB";
    private const string k_DownsamplePassName = "GaussianBlurDownsamplePass";
    private const string k_VerticalPassName = "VerticalGaussianBlurRenderPass";
    private const string k_HorizontalPassName = "HorizontalGaussianBlurRenderPass";
    private const string k_UpsamplePassName = "GaussianBlurUpsamplePass";

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
    private void UpdateGaussianBlurSettings(out int iterations, out int downSample)
    {
        if (material == null)
        {
            iterations = 0;
            downSample = 1;
            return;
        }

        var volumeComponent =
        VolumeManager.instance.stack.GetComponent<GaussianBlur_CustomValumeComponent>();

        iterations = volumeComponent.iterations.overrideState ?
           volumeComponent.iterations.value : defaultSettings.iterations;
        float blurSpread = volumeComponent.blurSpread.overrideState ?
            volumeComponent.blurSpread.value : defaultSettings.blurSpread;
        downSample = volumeComponent.downSample.overrideState ?
            volumeComponent.downSample.value : defaultSettings.downSample;

        downSample = Mathf.Max(1, downSample);
        material.SetFloat(blurSpreadId, blurSpread);
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
        UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

        if (resourceData.isActiveTargetBackBuffer)
            return;

        UpdateGaussianBlurSettings(out int iterations, out int downSample);
        if (iterations <= 0)
            return;

        gaussianBlurTextureDescriptor.width = Mathf.Max(1, cameraData.cameraTargetDescriptor.width / downSample);
        gaussianBlurTextureDescriptor.height = Mathf.Max(1, cameraData.cameraTargetDescriptor.height / downSample);
        gaussianBlurTextureDescriptor.depthBufferBits = 0;
        gaussianBlurTextureDescriptor.msaaSamples = 1;

        TextureHandle srcCamColor = resourceData.activeColorTexture;
        TextureHandle tempA = UniversalRenderer.CreateRenderGraphTexture(renderGraph, gaussianBlurTextureDescriptor, k_GaussianBlurTextureNameA, false);
        TextureHandle tempB = UniversalRenderer.CreateRenderGraphTexture(renderGraph, gaussianBlurTextureDescriptor, k_GaussianBlurTextureNameB, false);

        if (!srcCamColor.IsValid() || !tempA.IsValid() || !tempB.IsValid())
            return;

        renderGraph.AddBlitPass(srcCamColor, tempA, Vector2.one, Vector2.zero, passName: k_DownsamplePassName);

        for (int i = 0; i < iterations; i++)
        {
            RenderGraphUtils.BlitMaterialParameters paraVertical = new(tempA, tempB, material, 0);
            renderGraph.AddBlitPass(paraVertical, k_VerticalPassName);

            RenderGraphUtils.BlitMaterialParameters paraHorizontal = new(tempB, tempA, material, 1);
            renderGraph.AddBlitPass(paraHorizontal, k_HorizontalPassName);
        }

        renderGraph.AddBlitPass(tempA, srcCamColor, Vector2.one, Vector2.zero, passName: k_UpsamplePassName);
    }

}
