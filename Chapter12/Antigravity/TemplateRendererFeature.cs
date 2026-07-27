using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class TemplateRendererFeature : ScriptableRendererFeature
{
    // 后处理使用的 settings 数据结构，用于回退或者默认设置
    [SerializeField] private TemplateSettings settings;
    // 指定后处理使用的 Shader 资源
    [SerializeField] private Shader shader;
    
    private Material material;
    private TemplateRenderPass renderPass;

    /// <summary>
    /// 初始化方法，当 Feature 被启用、材质改变或者编辑器发生修改时调用
    /// </summary>
    public override void Create()
    {
        if (shader == null)
        {
            // 如果面板未手动指定 Shader，可以通过名字尝试查找
            shader = Shader.Find("Hidden/Custom/TemplateShader");
        }

        // 优化：如果材质已经存在且 Shader 没变，且 RenderPass 未丢失，则无需重新创建
        if (material != null && material.shader == shader)
        {
            if (renderPass != null) return;
        }

        // 清理旧材质，防止重复创建时发生内存泄漏
        if (material != null)
        {
            CoreUtils.Destroy(material);
            material = null;
        }

        if (shader == null) return;

        // 使用 CoreUtils.CreateEngineMaterial 安全创建材质
        material = CoreUtils.CreateEngineMaterial(shader);
        
        // 实例化具体的渲染 Pass
        renderPass = new TemplateRenderPass(material, settings);

        // 设置渲染事件：后处理一般是在不透明和半透明物体渲染完、天空盒绘制完毕后执行
        renderPass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
    }

    /// <summary>
    /// 每一帧渲染时，URP 会调用此方法把 Pass 放入相机的渲染队列中
    /// </summary>
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderPass == null || material == null) return;

        // 仅在 Game 摄像机（游戏窗口）或特定摄像机渲染时生效，防止干扰场景编辑窗口（Scene 视图）
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(renderPass);
        }
    }

    /// <summary>
    /// 释放资源，防止内存泄漏（切换场景、关闭游戏或重新编译时调用）
    /// </summary>
    protected override void Dispose(bool disposing)
    {
        // 使用 URP 标准的 CoreUtils.Destroy 释放材质
        if (material != null)
        {
            CoreUtils.Destroy(material);
            material = null;
        }
    }
}

/// <summary>
/// 当场景中没有 Volume 覆盖时，Feature 面板上默认提供的全局控制参数
/// </summary>
[Serializable]
public class TemplateSettings
{
    public bool isEnabled = true;
    [Range(0.0f, 1.0f)] public float intensity = 0.5f;
    public Color tintColor = Color.white;
}
