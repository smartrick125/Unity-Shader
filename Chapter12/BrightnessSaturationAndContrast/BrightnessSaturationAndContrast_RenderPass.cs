using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class BrightnessSaturationAndContrast_RenderPass : ScriptableRenderPass
{
    private static readonly int brightnessId = Shader.PropertyToID("_Brightness");
    private static readonly int saturationId = Shader.PropertyToID("_Saturation");
    private static readonly int contrastId = Shader.PropertyToID("_Contrast");
    
    private const string k_TextureName = "_BSCResultTexture";
    private const string k_PassName = "BrightnessSaturationAndContrastPass";
    private const string k_CopyPassName = "BSC_CopyBackPass";

    private BrightnessSaturationAndContrastSettings defaultSettings;
    private Material material;
    private RenderTextureDescriptor textureDescriptor;

    public BrightnessSaturationAndContrast_RenderPass(Material material, BrightnessSaturationAndContrastSettings defaultSettings)
    {
        this.material = material;
        this.defaultSettings = defaultSettings;

        // 初始化渲染纹理描述符（不包含深度缓冲区）
        textureDescriptor = new RenderTextureDescriptor(Screen.width, Screen.height, RenderTextureFormat.Default, 0);
    }

    private void UpdateMaterialSettings()
    {
        if (material == null) return;

        // 尝试从 Volume 获取局部或全局配置，若无则回退至默认设置
        var volumeComponent = VolumeManager.instance.stack.GetComponent<BrightnessSaturationAndContrast_CustomVolumeComponent>();
        
        float brightness = defaultSettings != null ? defaultSettings.brightness : 1.0f;
        float saturation = defaultSettings != null ? defaultSettings.saturation : 1.0f;
        float contrast = defaultSettings != null ? defaultSettings.contrast : 1.0f;

        if (volumeComponent != null)
        {
            brightness = volumeComponent.brightness.overrideState ? volumeComponent.brightness.value : brightness;
            saturation = volumeComponent.saturation.overrideState ? volumeComponent.saturation.value : saturation;
            contrast = volumeComponent.contrast.overrideState ? volumeComponent.contrast.value : contrast;
        }

        material.SetFloat(brightnessId, brightness);
        material.SetFloat(saturationId, saturation);
        material.SetFloat(contrastId, contrast);
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
        UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

        // 确保不是直接渲染到 BackBuffer 导致无法 Blit
        if (resourceData.isActiveTargetBackBuffer)
            return;

        // 根据当前相机的尺寸更新描述符宽高
        textureDescriptor.width = cameraData.cameraTargetDescriptor.width;
        textureDescriptor.height = cameraData.cameraTargetDescriptor.height;
        textureDescriptor.depthBufferBits = 0;

        TextureHandle srcCamColor = resourceData.activeColorTexture;
        TextureHandle dst = UniversalRenderer.CreateRenderGraphTexture(renderGraph, textureDescriptor, k_TextureName, false);

        // 更新材质里的 Shader 变量数值
        UpdateMaterialSettings();

        if (!srcCamColor.IsValid() || !dst.IsValid())
            return;

        // 1. 使用 Pass 0 (进行亮度和饱和度对比度调整) 将画面绘制到临时纹理 dst
        RenderGraphUtils.BlitMaterialParameters blitToTemp = new(srcCamColor, dst, material, 0);
        renderGraph.AddBlitPass(blitToTemp, k_PassName);

        // 2. 使用 Pass 1 (简单拷贝 Pass) 将 dst 的处理结果拷贝回主摄像机色彩纹理 srcCamColor
        RenderGraphUtils.BlitMaterialParameters blitBack = new(dst, srcCamColor, material, 1);
        renderGraph.AddBlitPass(blitBack, k_CopyPassName);
    }
}
