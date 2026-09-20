using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
public class BloomRenderPass : ScriptableRenderPass
{
    //private static readonly int iterationsId = Shader.PropertyToID("_Iterations");
    private static readonly int blurSpreadId = Shader.PropertyToID("_BlurSpread");
    //private static readonly int downSampleId = Shader.PropertyToID("_DownSample");
    private static readonly int luminanceThreshlodId = Shader.PropertyToID("_LuminanceThreshlod");

    private const string k_BloomTextureNameA = "_BloomTextureA";
    private const string k_BloomTextureNameB = "_BloomTextureB";

    private const string k_ExtractBrightPassName = "ExtractBrightRenderPass";
    private const string k_VerticalPassName = "VerticalBlurRenderPass";
    private const string k_HorizontalPassName = "HorizontalBlurRenderPass";
    private const string k_CombinePassName = "CombineRenderPass";
    /*private const string k_CopyBackPassName = "CopyBackPass";*/
    private BloomSettings defaultSettings;
    private Material material;
    private RenderTextureDescriptor bloomTextureDescriptor;
    private class PassData
    {
        public TextureHandle src;
        public TextureHandle dst;
        //public TextureHandle bloomTex;
        public Material blitMaterial;
        public int passIndex;

    }

    public BloomRenderPass(Material material, BloomSettings defaultSettings)
    {
        this.material = material;
        this.defaultSettings = defaultSettings;

        bloomTextureDescriptor = new RenderTextureDescriptor(Screen.width, Screen.height,
            RenderTextureFormat.Default, 0);
    }
    private void UpdateBloomSettings(out int iterations, out int downSample)
    {
        if (material == null)
        {
            iterations = 0;
            downSample = 1;
            return;
        }
        var volumeComponent =
            VolumeManager.instance.stack.GetComponent<Bloom_CustomValumeComponent>();

        //if (volumeComponent == null) return;

        iterations = volumeComponent.iterations.overrideState ?
           volumeComponent.iterations.value : defaultSettings.iterations;
        float blurSpread = volumeComponent.blurSpread.overrideState ?
            volumeComponent.blurSpread.value : defaultSettings.blurSpread;
        downSample = volumeComponent.downSample.overrideState ?
            volumeComponent.downSample.value : defaultSettings.downSample;
        float luminanceThreshlod = volumeComponent.luminanceThreshlod.overrideState ?
            volumeComponent.luminanceThreshlod.value : defaultSettings.luminanceThreshlod;

        downSample = Mathf.Max(1, downSample);
        material.SetFloat(blurSpreadId, blurSpread);
        material.SetFloat(luminanceThreshlodId, luminanceThreshlod);

    }


    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
        UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

        Debug.Log($"[Bloom] RecordRenderGraph 被调用, isBackBuffer={resourceData.isActiveTargetBackBuffer}");

        if (resourceData.isActiveTargetBackBuffer)
        {
            Debug.Log("[Bloom] 提前返回: isActiveTargetBackBuffer = true");
            return;
        }

        UpdateBloomSettings(out int iterations, out int downSample);
        if (iterations <= 0)
            return;

        bloomTextureDescriptor.width = Mathf.Max(1,cameraData.cameraTargetDescriptor.width / downSample);
        bloomTextureDescriptor.height = Mathf.Max(1, cameraData.cameraTargetDescriptor.height / downSample);
        bloomTextureDescriptor.depthBufferBits = 0;
        bloomTextureDescriptor.msaaSamples = 1;


        TextureHandle srcCamColor = resourceData.activeColorTexture;
        TextureHandle tempA = UniversalRenderer.CreateRenderGraphTexture(renderGraph, bloomTextureDescriptor, k_BloomTextureNameA, false);
        TextureHandle tempB = UniversalRenderer.CreateRenderGraphTexture(renderGraph, bloomTextureDescriptor, k_BloomTextureNameB, false);


        if (!srcCamColor.IsValid() || !tempA.IsValid() || !tempB.IsValid())
        {
            Debug.Log($"[Bloom] 纹理无效 srcCam={srcCamColor.IsValid()} tempA={tempA.IsValid()} tempB={tempB.IsValid()}");
            return;
        }

        Debug.Log("[Bloom] 纹理有效，开始注册Pass");

        using (var builder = renderGraph.AddRasterRenderPass<PassData>(k_ExtractBrightPassName, out var passData))
        {
            passData.src = srcCamColor;
            passData.dst = tempA;
            passData.blitMaterial = material;
            passData.passIndex = 0;

            builder.UseTexture(passData.src, AccessFlags.Read);
            builder.SetRenderAttachment(passData.dst, 0, AccessFlags.Write);

            builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => ExecutePass(data, context));
        }

        for (int i = 0; i < iterations; i++)
        {
            using (var builder = renderGraph.AddRasterRenderPass<PassData>(k_VerticalPassName, out var passData))
            {
                passData.src = tempA;
                passData.dst = tempB;
                passData.blitMaterial = material;
                passData.passIndex = 1;

                builder.UseTexture(passData.src, AccessFlags.Read);
                builder.SetRenderAttachment(passData.dst, 0, AccessFlags.Write);

                builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => ExecutePass(data, context));
            }
            using (var builder = renderGraph.AddRasterRenderPass<PassData>(k_HorizontalPassName, out var passData))
            {
                passData.src = tempB;
                passData.dst = tempA;
                passData.blitMaterial = material;
                passData.passIndex = 2;

                builder.UseTexture(passData.src, AccessFlags.Read);
                builder.SetRenderAttachment(passData.dst, 0, AccessFlags.Write);

                builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => ExecutePass(data, context));
            }
        }
        using (var builder = renderGraph.AddRasterRenderPass<PassData>(k_CombinePassName, out var passData))
        {
            passData.src = tempA;
            /*passData.bloomTex = ;*/
            passData.dst = srcCamColor;
            passData.blitMaterial = material;
            passData.passIndex = 3;

            builder.UseTexture(passData.src, AccessFlags.Read);
            /*builder.UseTexture(passData.bloomTex, AccessFlags.Read);*/
            builder.SetRenderAttachment(passData.dst, 0, AccessFlags.ReadWrite);

            builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => ExecutePass(data, context));
            /*{
                Debug.Log("[Bloom] CopyBack 正在执行");
                context.cmd.SetGlobalTexture("_BloomTex", data.bloomTex);
                Blitter.BlitTexture(context.cmd, data.src, new Vector4(1, 1, 0, 0), data.blitMaterial, data.passIndex);

            }*/
        }
        /*using (var builder = renderGraph.AddRasterRenderPass<PassData>(k_CopyBackPassName, out var passData))
        {
            passData.src = tempB;
            passData.dst = srcCamColor;
            passData.blitMaterial = material;
            passData.passIndex = 4;

            builder.UseTexture(passData.src, AccessFlags.Read);
            builder.SetRenderAttachment(passData.dst, 0, AccessFlags.Write);

            builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => ExecutePass(data, context));
        }*/
    }
    private static void ExecutePass(PassData data, RasterGraphContext context)
    {
        Blitter.BlitTexture(context.cmd, data.src, new Vector4(1, 1, 0, 0), data.blitMaterial, data.passIndex);
    }
}
