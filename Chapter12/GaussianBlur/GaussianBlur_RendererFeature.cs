using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GaussianBlurRendererFeature : ScriptableRendererFeature
{
    [SerializeField] private GaussianBlurSettings settings;
    [SerializeField] private Shader shader;
    private Material material;
    private GaussianBlurRenderPass gaussianRenderPass;

    public override void Create()
    {
        name = "高斯模糊";
        if (shader == null)
        {
            shader = Shader.Find("Custom/GaussianBlur");
        }
        if (material != null && material.shader == shader)
        {
            if (gaussianRenderPass != null) return;
        }
        if (material != null)
        {
            CoreUtils.Destroy(material);
            material = null;
        }

        if (shader == null)
        {
            return;
        }

        material = CoreUtils.CreateEngineMaterial(shader);
        gaussianRenderPass = new GaussianBlurRenderPass(material, settings);

        gaussianRenderPass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;

    }

    public override void AddRenderPasses(ScriptableRenderer renderer,
        ref RenderingData renderingData)
    {
        if (gaussianRenderPass == null || material == null)
        {
            return;
        }

        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(gaussianRenderPass);
        }
    }
    protected override void Dispose(bool disposing)
    {
        if (Application.isPlaying)
        {
            Destroy(material);
        }
        else
        {
            DestroyImmediate(material);
        }
    }

}

[Serializable]
public class GaussianBlurSettings
{
    [Range(0, 4)] public int iterations;
    [Range(0.2f, 3.0f)] public float blurSpread;
    [Range(1, 8)] public int downSample;
}
