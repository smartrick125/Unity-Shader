using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class BlurRenderPass : ScriptableRenderPass
{
    // 将 Shader 属性名转换为 ID，比每帧用字符串匹配性能更高
    private static readonly int horizontalBlurId = Shader.PropertyToID("_HorizontalBlur");
    private static readonly int verticalBlurId = Shader.PropertyToID("_VerticalBlur");

    // 渲染图中临时纹理和各 Pass 节点的唯一标识名
    private const string k_BlurTextureName = "_BlurTexture";
    private const string k_VerticalPassName = "VerticalBlurRenderPass";
    private const string k_HorizontalPassName = "HorizontalBlurRenderPass";

    // RendererFeature 面板上的默认参数（当 Volume 没有覆盖时使用）
    private BlurSettings defaultSettings;
    // 承载 Shader 参数的材质实例
    private Material material;

    // 临时渲染纹理的描述符（宽高、格式等信息的模板）
    private RenderTextureDescriptor blurTextureDescriptor;

    public BlurRenderPass(Material material, BlurSettings defaultSettings)
    {
        this.material = material;
        this.defaultSettings = defaultSettings;

        // 初始化描述符，不包含深度缓冲（后处理不需要深度）
        blurTextureDescriptor = new RenderTextureDescriptor(Screen.width, Screen.height,
            RenderTextureFormat.Default, 0);
    }

    /// <summary>
    /// 从 Volume 系统或默认参数读取最新的模糊数值，并传递给材质
    /// </summary>
    private void UpdateBlurSettings()
    {
        if (material == null) return;

        // 尝试从 VolumeManager 的混合栈中获取自定义 Volume 组件
        var volumeComponent =
            VolumeManager.instance.stack.GetComponent<BlurCustomVolumeComponent>();

        // 如果 Volume 中覆盖了该参数，则使用 Volume 的值；否则回退到面板默认值
        float horizontalBlur = volumeComponent.horizontalBlur.overrideState ?
            volumeComponent.horizontalBlur.value : defaultSettings.horizontalBlur;
        float verticalBlur = volumeComponent.verticalBlur.overrideState ?
            volumeComponent.verticalBlur.value : defaultSettings.verticalBlur;

        // 将数值传递给 Shader
        material.SetFloat(horizontalBlurId, horizontalBlur);
        material.SetFloat(verticalBlurId, verticalBlur);
    }

    /// <summary>
    /// URP 渲染图（RenderGraph）的入口方法，在此注册每帧的渲染任务
    /// </summary>
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        // 获取 URP 的核心资源和相机上下文数据
        UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
        UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

        // 如果当前渲染目标是后缓冲区（BackBuffer），无法进行 Blit 操作，直接返回
        if (resourceData.isActiveTargetBackBuffer)
            return;

        // 根据当前相机的动态分辨率更新临时纹理的宽高
        blurTextureDescriptor.width = cameraData.cameraTargetDescriptor.width;
        blurTextureDescriptor.height = cameraData.cameraTargetDescriptor.height;
        blurTextureDescriptor.depthBufferBits = 0;

        // 获取相机的源颜色纹理句柄（当前屏幕画面）
        TextureHandle srcCamColor = resourceData.activeColorTexture;
        // 在渲染图中创建一个生命周期受托管的临时渲染纹理
        TextureHandle dst = UniversalRenderer.CreateRenderGraphTexture(renderGraph, blurTextureDescriptor, k_BlurTextureName, false);

        // 更新材质中的模糊参数
        UpdateBlurSettings();

        // 安全检查：避免场景中材质预览导致的无效纹理错误
        if (!srcCamColor.IsValid() || !dst.IsValid())
            return;

        // 第一步：使用 Pass 0（纵向模糊），将相机画面从 srcCamColor 绘制到临时纹理 dst
        RenderGraphUtils.BlitMaterialParameters paraVertical = new(srcCamColor, dst, material, 0);
        renderGraph.AddBlitPass(paraVertical, k_VerticalPassName);

        // 第二步：使用 Pass 1（横向模糊），将纵向模糊后的 dst 绘制回相机画面 srcCamColor
        RenderGraphUtils.BlitMaterialParameters paraHorizontal = new(dst, srcCamColor, material, 1);
        renderGraph.AddBlitPass(paraHorizontal, k_HorizontalPassName);
    }
}