using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class TemplateRenderPass : ScriptableRenderPass
{
    // 定义对应的 Shader 属性的 ID，比每次用字符串去匹配性能更高
    private static readonly int intensityId = Shader.PropertyToID("_Intensity");
    private static readonly int tintColorId = Shader.PropertyToID("_TintColor");
    
    // 渲染图节点和贴图的唯一名字
    private const string k_TempTextureName = "_TemplateEffectTempTex";
    private const string k_DrawPassName = "TemplateEffectDrawPass";
    private const string k_CopyPassName = "TemplateEffectCopyBackPass";

    private Material material;
    private TemplateSettings defaultSettings;
    private RenderTextureDescriptor textureDescriptor;

    public TemplateRenderPass(Material material, TemplateSettings defaultSettings)
    {
        this.material = material;
        this.defaultSettings = defaultSettings;

        // 初始化描述符（创建 RenderTexture 时的参数模板，不带深度缓冲区以提高性能）
        textureDescriptor = new RenderTextureDescriptor(Screen.width, Screen.height, RenderTextureFormat.Default, 0);
    }

    /// <summary>
    /// 从 Volume 系统或默认参数读取最新数据，并将它们绑定至 Material
    /// </summary>
    private void UpdateMaterialParameters()
    {
        if (material == null) return;

        // 从 VolumeManager 面板上的 Volume 混合栈中寻找属于我们的自定义 VolumeComponent
        var volume = VolumeManager.instance.stack.GetComponent<TemplateVolumeComponent>();

        bool isEnabled = defaultSettings != null ? defaultSettings.isEnabled : false;
        float intensity = defaultSettings != null ? defaultSettings.intensity : 0f;
        Color tint = defaultSettings != null ? defaultSettings.tintColor : Color.white;

        // 如果场景中有激活的 Volume，并且美术覆盖了这些属性，则使用 Volume 里的参数
        if (volume != null && volume.IsActive())
        {
            intensity = volume.intensity.overrideState ? volume.intensity.value : intensity;
            tint = volume.tintColor.overrideState ? volume.tintColor.value : tint;
        }
        else if (volume != null && !volume.IsActive())
        {
            // 如果 Volume 存在但是被显式关闭了，我们把强度强行归零，不显示特效
            intensity = 0.0f;
        }

        // 把数据传递给 Shader
        material.SetFloat(intensityId, intensity);
        material.SetColor(tintColorId, tint);
    }

    /// <summary>
    /// URP 现代渲染图（Render Graph）的入口点。在此方法中注册渲染任务（Pass）。
    /// </summary>
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        // 1. 获取 URP 的核心相机和资源上下文
        UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
        UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

        // 2. 边缘情况处理：如果是渲染到主显卡的后缓冲区（BackBuffer），无法进行贴图采样和 Blit，则直接返回
        if (resourceData.isActiveTargetBackBuffer) return;

        // 3. 根据当前相机的动态分辨率/宽高来更新临时纹理的尺寸
        textureDescriptor.width = cameraData.cameraTargetDescriptor.width;
        textureDescriptor.height = cameraData.cameraTargetDescriptor.height;
        textureDescriptor.depthBufferBits = 0; // 后处理不需要深度缓冲

        // 4. 获取相机的源颜色纹理句柄（代表当前屏幕上的画面输入）
        TextureHandle srcCamColor = resourceData.activeColorTexture;

        // 5. 在渲染图内部创建一个生命周期受 RenderGraph 托管的临时渲染纹理
        TextureHandle tempTexture = UniversalRenderer.CreateRenderGraphTexture(renderGraph, textureDescriptor, k_TempTextureName, false);

        // 6. 更新材质参数
        UpdateMaterialParameters();

        // 安全检查
        if (!srcCamColor.IsValid() || !tempTexture.IsValid()) return;

        // ==========================================
        // 第一步：将屏幕画面 srcCamColor 通过材质渲染到临时纹理 tempTexture (使用 Pass 0)
        // ==========================================
        RenderGraphUtils.BlitMaterialParameters drawParams = new(srcCamColor, tempTexture, material, 0);
        renderGraph.AddBlitPass(drawParams, k_DrawPassName);

        // ==========================================
        // 第二步：将渲染好特效的 tempTexture 重新拷贝回屏幕画面 srcCamColor (使用 Pass 1)
        // ==========================================
        RenderGraphUtils.BlitMaterialParameters copyParams = new(tempTexture, srcCamColor, material, 1);
        renderGraph.AddBlitPass(copyParams, k_CopyPassName);
    }
}
