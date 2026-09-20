using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class Bloom_RendererFeature : ScriptableRendererFeature
{
    [SerializeField] private BloomSettings settings;
    [SerializeField] private Shader shader;
    private Material material;
    private BloomRenderPass bloomRenderPass;

    public override void Create()
    {
        name = "辉光";
        if (shader == null)
        {
            shader = Shader.Find("Custom/Bloom");
        }
        if (material != null && material.shader == shader)
        {
            if (bloomRenderPass != null) return;
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
        bloomRenderPass = new BloomRenderPass(material, settings);

        //bloomRenderPass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
        bloomRenderPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (bloomRenderPass == null || material == null)
        {
            return;
        }

        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(bloomRenderPass);
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
public class BloomSettings
{
    [Range(0, 6)] public int iterations = 1;
    [Range(0.2f, 3.0f)] public float blurSpread = 1.0f;
    [Range(1, 8)] public int downSample = 1;
    [Range(0, 4.0f)] public float luminanceThreshlod = 0.6f;

}
