using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

/// <summary>
/// 手动实现 Render Graph 版本的高斯模糊 Render Pass。
/// 写入到用户创建的 GaussianBlur_RenderPas1.cs 中。
/// 使用了官方最佳实践推荐的 static 方法和 static lambda，以避免 GC Alloc。
/// </summary>
public class GaussianBlur_RenderPass1 : ScriptableRenderPass
{
    private static readonly int iterationsId = Shader.PropertyToID("_Iterations");
    private static readonly int blurSpreadId = Shader.PropertyToID("_BlurSpread");
    private static readonly int downSampleId = Shader.PropertyToID("_DownSample");

    private const string k_GaussianBlurTextureName = "_GaussianBlurTexture1";
    private const string k_VerticalPassName = "VerticalGaussianBlurRenderPass_Manual";
    private const string k_HorizontalPassName = "HorizontalGaussianBlurRenderPass_Manual";

    private GaussianBlurSettings defaultSettings;
    private Material material;
    private RenderTextureDescriptor gaussianBlurTextureDescriptor;

    // 1. 定义数据结构：用于在“声明阶段”与“执行阶段”之间传递资源
    private class PassData
    {
        public TextureHandle src;
        public TextureHandle dst;
        public Material blitMaterial;
        public int passIndex;
    }

    public GaussianBlur_RenderPass1(Material material, GaussianBlurSettings defaultSettings)
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

    // 2. 声明阶段 (Setup Phase)
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

        // ==========================================
        // 纵向模糊 Pass（手动编写版）
        // ==========================================
        using (var builder = renderGraph.AddRasterRenderPass<PassData>(k_VerticalPassName, out var passData))
        {
            passData.src = srcCamColor;
            passData.dst = dst;
            passData.blitMaterial = material;
            passData.passIndex = 0; // Shader 中的 Pass 0 (Vertical)

            builder.UseTexture(passData.src, AccessFlags.Read);
            builder.SetRenderAttachment(passData.dst, 0, AccessFlags.Write);

            // 使用 static 匿名函数配合独立静态方法，杜绝 GC 堆内存分配
            builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => ExecutePass(data, context));
        }

        // ==========================================
        // 横向模糊 Pass（手动编写版）
        // ==========================================
        using (var builder = renderGraph.AddRasterRenderPass<PassData>(k_HorizontalPassName, out var passData))
        {
            passData.src = dst;
            passData.dst = srcCamColor;
            passData.blitMaterial = material;
            passData.passIndex = 1; // Shader 中的 Pass 1 (Horizontal)

            builder.UseTexture(passData.src, AccessFlags.Read);
            builder.SetRenderAttachment(passData.dst, 0, AccessFlags.Write);

            // 使用 static 匿名函数配合独立静态方法，杜绝 GC 堆内存分配
            builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => ExecutePass(data, context));
        }
    }

    // 3. 执行阶段 (Execution Phase)：必须是 static 静态方法
    private static void ExecutePass(PassData data, RasterGraphContext context)
    {
        Blitter.BlitTexture(context.cmd, data.src, new Vector4(1, 1, 0, 0), data.blitMaterial, data.passIndex);
    }
}
