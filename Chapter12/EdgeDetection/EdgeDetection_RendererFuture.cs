using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EdgeDetction_rendererfuture : ScriptableRendererFeature
{
    [SerializeField] private EdgeDetectionSettings settings;
    [SerializeField] private Shader shader;
    private Material material;
    private EdgeDetection_RenderPass edgeDetection_RenderPass;
    public override void Create()
    {
        name = "边缘检测";

        if (shader == null)
        {
            shader = Shader.Find("Custom/EdgeDetection");
        }

        // 优化：如果材质已经存在且 Shader 没变，且 RenderPass 未丢失，则无需重新创建
        if (material != null && material.shader == shader)
        {
            if (edgeDetection_RenderPass != null) return;
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
        edgeDetection_RenderPass = new EdgeDetection_RenderPass(material, settings);

        edgeDetection_RenderPass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer,
        ref RenderingData renderingData)
    {
        if (edgeDetection_RenderPass == null || material == null)
        {
            return;
        }

        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(edgeDetection_RenderPass);
        }
    }
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

[Serializable]
public class EdgeDetectionSettings
{
    [Range(0, 1.0f)] public float edgesOnly = 0f;
    public Color edgeColor = Color.black;
    public Color backgroundColor = Color.white;
}
