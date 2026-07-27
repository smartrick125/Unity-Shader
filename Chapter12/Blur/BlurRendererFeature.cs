using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BlurRendererFeature : ScriptableRendererFeature
{
    [SerializeField] private BlurSettings settings;
    [SerializeField] private Shader shader;
    private Material material;
    private BlurRenderPass blurRenderPass;

    public override void Create()
    {
        // 优化方法：如果材质已经存在且 Shader 没变，无需重新创建，避免频繁分配/销毁内存
        if (material != null && material.shader == shader)
        {
            // 确保 RenderPass 引用的是最新的材质，并直接返回
            if (blurRenderPass != null) return;
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
        blurRenderPass = new BlurRenderPass(material, settings);

        blurRenderPass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (blurRenderPass == null)
        {
            return;
        }
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(blurRenderPass);
        }
    }
    protected override void Dispose(bool disposing)
    {
        // 使用 URP 标准的 CoreUtils.Destroy，它会自动在编辑模式下调用 DestroyImmediate，在运行模式下调用 Destroy
        if (material != null)
        {
            CoreUtils.Destroy(material);
            material = null;
        }
    }

}

[Serializable]
public class BlurSettings
{
    [Range(0, 0.4f)] public float horizontalBlur;
    [Range(0, 0.4f)] public float verticalBlur;
}

