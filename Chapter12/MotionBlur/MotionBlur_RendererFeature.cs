using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class MotionBlurRendererFeature : ScriptableRendererFeature
{
    [SerializeField] private MotionBlurSettings defaultSettings;
    [SerializeField] private Shader shader;
    private Material material;
    private MotionBlurRenderPass motionBlurRenderPass;
    public override void Create()
    {
        if (shader == null)
        {
            return;
        }
        material = new Material(shader);
        motionBlurRenderPass = new MotionBlurRenderPass(material, defaultSettings);

        motionBlurRenderPass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
    }
    public override void AddRenderPasses(ScriptableRenderer renderer,
        ref RenderingData renderingData)
    {
        if (motionBlurRenderPass == null)
        {
            return;
        }
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(motionBlurRenderPass);
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
public class MotionBlurSettings
{
    [Range(0, 0.9f)] public float blurAmount;
}
