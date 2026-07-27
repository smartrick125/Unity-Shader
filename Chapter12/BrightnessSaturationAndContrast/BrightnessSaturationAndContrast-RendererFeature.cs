using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BrightnessSaturationAndContrast_RendererFeature : ScriptableRendererFeature
{
    [SerializeField] private BrightnessSaturationAndContrastSettings settings;
    [SerializeField] private Shader shader;
    private Material material;
    private BrightnessSaturationAndContrast_RenderPass bscRenderPass;

    public override void Create()
    {
        name = "亮度，饱和度，对比度";
        
        // 自动查找 Shader，如果没面板指定，则尝试通过名字获取
        if (shader == null)
        {
            shader = Shader.Find("Custom/BrightnessSaturationAndContrast");
        }

        // 优化方法：如果材质已经存在且 Shader 没变，且 RenderPass 未丢失，则无需重新创建，避免频繁分配/销毁内存
        if (material != null && material.shader == shader)
        {
            if (bscRenderPass != null) return;
        }

        // 清理旧材质，防止重复创建时发生内存泄漏
        if (material != null)
        {
            CoreUtils.Destroy(material);
            material = null;
        }

        if (shader == null)
        {
            return;
        }

        // 使用 CoreUtils.CreateEngineMaterial 安全创建材质
        material = CoreUtils.CreateEngineMaterial(shader);
        bscRenderPass = new BrightnessSaturationAndContrast_RenderPass(material, settings);

        // 设置渲染事件：通常后处理在天空盒渲染之后执行
        bscRenderPass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (bscRenderPass == null || material == null)
        {
            return;
        }

        // 仅在 Game 窗口（游戏相机）下应用该后处理，避免干扰 Scene 场景编辑器
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(bscRenderPass);
        }
    }

    protected override void Dispose(bool disposing)
    {
        // 使用 URP 标准的 CoreUtils.Destroy 释放材质，避免内存泄漏
        if (material != null)
        {
            CoreUtils.Destroy(material);
            material = null;
        }
    }
}

[Serializable]
public class BrightnessSaturationAndContrastSettings
{
    [Range(0.0f, 3.0f)] public float brightness = 1.0f;
    [Range(0.0f, 3.0f)] public float saturation = 1.0f;
    [Range(0.0f, 3.0f)] public float contrast = 1.0f;
}
