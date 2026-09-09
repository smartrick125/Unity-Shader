using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule.Util;

public class MotionBlurRenderPass : ScriptableRenderPass
{
    private static readonly int blurAmountId = Shader.PropertyToID("_BlurAmount");
    private const string k_MotionBlurTextureName = "_MotionBlurTexture";
    private const string k_WritePassName = "WriteRenderPass";
    private const string k_WriteBackPassName = "WriteBackRenderPass";

    private MotionBlurSettings defaultSettings;
    private Material material;
    private RTHandle rTHandle;
    private RenderTextureDescriptor motionBlurTextureDescriptor;


    class PassData
    {
        public TextureHandle src;
        public TextureHandle dst;
        public Material blitMaterial;
        public int passIndex;

    }
    public MotionBlurRenderPass(Material material, MotionBlurSettings defaultSettings)
    {
        this.material = material;
        this.defaultSettings = defaultSettings;
    }
    private void UpdateMotionBlurSettings()
    {
        if (material == null)
            return;

        var volumeComponent =
            VolumeManager.instance.stack
                .GetComponent<CustomVolumeComponent>();

        float blurAmount =
            volumeComponent != null &&
            volumeComponent.blurAmount.overrideState
                ? volumeComponent.blurAmount.value
                : defaultSettings.blurAmount;

        // blurAmount越大，历史保留越多；
        // Shader Alpha代表当前帧占比。
        material.SetFloat(blurAmountId, 1.0f - blurAmount);
    }
    public override void RecordRenderGraph(RenderGraph renderGraph,
    ContextContainer frameData)
    {
        UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
        UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

        if (resourceData.isActiveTargetBackBuffer)
            return;

        if (material == null)
            return;

        TextureHandle srcCamColor = resourceData.activeColorTexture;

        RenderTextureDescriptor descriptor = cameraData.cameraTargetDescriptor;

        descriptor.depthBufferBits = 0;
        descriptor.msaaSamples = 1;

        bool historyReallocated =
            RenderingUtils.ReAllocateHandleIfNeeded(
                ref rTHandle,
                descriptor,
                FilterMode.Bilinear,
                TextureWrapMode.Clamp,
                name: k_MotionBlurTextureName);

        TextureHandle accumulationTexture = renderGraph.ImportTexture(rTHandle);

        if (!srcCamColor.IsValid() || !accumulationTexture.IsValid())
            return;

        UpdateMotionBlurSettings();

        if (historyReallocated)
        {
        // 第一帧或分辨率变化：
        // 历史贴图还没有有效内容，直接用当前帧初始化。
        renderGraph.AddBlitPass(
            srcCamColor,
            accumulationTexture,
            Vector2.one,
            Vector2.zero,
            passName: "Initialize Motion Blur History");
        }
        else
        {
        // 正常帧：
        // 当前画面通过Shader混合进旧的历史贴图。
            using (var builder =
                renderGraph.AddRasterRenderPass<PassData>(
                    k_WritePassName,
                    out var passData))
                {
                passData.src = srcCamColor;
                passData.dst = accumulationTexture;
                passData.blitMaterial = material;
                passData.passIndex = 0;

                builder.UseTexture(passData.src, AccessFlags.Read);

                builder.SetRenderAttachment(passData.dst, 0, AccessFlags.ReadWrite);

                builder.SetRenderFunc(static (PassData data, RasterGraphContext context) =>
                    {
                        ExecuteAccumulation(data, context);
                    });
                }
        }

    // 第二个节点：
    // 把更新后的历史结果写回相机颜色。
        renderGraph.AddBlitPass(
            accumulationTexture,
            srcCamColor,
            Vector2.one,
            Vector2.zero,
            passName: k_WriteBackPassName);
    }

    private static void ExecuteAccumulation(PassData data, RasterGraphContext context)
    {
        Blitter.BlitTexture(
            context.cmd,
            data.src,
            new Vector4(1, 1, 0, 0),
            data.blitMaterial,
            data.passIndex);
    }

}
