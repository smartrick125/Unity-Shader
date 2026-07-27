using UnityEngine;
using UnityEngine.Rendering;

// 最小版实时 Cubemap 采样点。
// 用法：
// 1. 把这个脚本挂到一个空物体上，这个空物体的位置就是 Cubemap 的采样位置。
// 2. 把需要反射的物体 Renderer 拖到 targetRenderer。
// 3. 目标物体材质的 shader 里要有一个名为 _EnvironmentCube 的 Cube 贴图属性。
[DisallowMultipleComponent]
public sealed class UNminCubemapCapturePoint : MonoBehaviour
{
//1.输入
    //1.采样点位置
    //2.目标renderer    
    [Header("反射目标")]
    [SerializeField] private Renderer targetRenderer;//render目标
    //3.shader属性名
    [Header("Shader 中的 Cubemap 属性名")]
    [SerializeField] private string cubemapProperty = "_EnvironmentCube";//shader属性名链接shader
    //4.额外输入
    [Header("Cubemap 设置")]
    [SerializeField, Range(16, 1024)] private int resolution = 128;//cubemap每个面的尺寸
    [SerializeField] private LayerMask cullingMask = ~0;//可以拍到哪些layer
//2.作用
    //在一个指定位置实时生成一个cubemap然后传给目标物体做反射

    private Camera captureCamera;

    private RenderTexture cubemap;
    private MaterialPropertyBlock propertyBlock;

    private void OnEnable()//准备相机
    {
        CreateCamera();
        CreateCubemap();
        BindCubemapToRenderer();

            // 启用时先完整采样一次，避免第一帧没有反射内容。
        RenderCubemap();
    }

    private void LateUpdate()//每帧渲染cubemap
    {
            // 最小版直接每帧更新六个面，逻辑最直观，但性能开销也最大。
        RenderCubemap();
    }

    private void CreateCamera()//准备cubemap
    {
        if (captureCamera != null)
            return;

        GameObject cameraObject = new GameObject("UNmin Cubemap Camera");
        cameraObject.hideFlags = HideFlags.HideAndDontSave;
        //1.创建一个隐藏的camera[不参与画面渲染只排cubemap]
        captureCamera = cameraObject.AddComponent<Camera>();//*

            // 关闭 Camera 自己的自动渲染，只在 RenderToCubemap 时手动让它渲染。
        captureCamera.enabled = false;//*
        captureCamera.clearFlags = CameraClearFlags.Skybox;
        captureCamera.cullingMask = cullingMask;
        captureCamera.nearClipPlane = 0.1f;
        captureCamera.farClipPlane = 100f;
        captureCamera.allowHDR = true;
        captureCamera.allowMSAA = false;
    }

    private void CreateCubemap()
    {
        if (cubemap != null)
            return;
        //2.创建一张cubemap rendertexture
        cubemap = new RenderTexture(
            resolution,
            resolution,
            24,
            RenderTextureFormat.DefaultHDR
        )
        {
            // 关键：RenderTexture 必须是 Cube，才能存六个方向的画面。
            dimension = TextureDimension.Cube,//*
            wrapMode = TextureWrapMode.Clamp,
            filterMode = FilterMode.Bilinear,
            useMipMap = false,
            autoGenerateMips = false,
            hideFlags = HideFlags.HideAndDontSave,
            name = "UNmin Realtime Cubemap"
        };

        cubemap.Create();
    }

    private void BindCubemapToRenderer()//把cubemap交给材质
    {
        if (targetRenderer == null)
            return;

        if (propertyBlock == null)
            propertyBlock = new MaterialPropertyBlock();

            // 用 MaterialPropertyBlock 只修改这个 Renderer，不直接改材质资源本身。
        targetRenderer.GetPropertyBlock(propertyBlock);
        //3.把cubemap绑定给目标renderer
        propertyBlock.SetTexture(cubemapProperty, cubemap);//*
        targetRenderer.SetPropertyBlock(propertyBlock);//*
    }

    private void RenderCubemap()//每帧渲染cubemap
    {
        if (captureCamera == null || cubemap == null)
            return;

            // 采样点在哪里，临时 Camera 就在哪里拍 Cubemap。
        captureCamera.transform.SetPositionAndRotation(
            transform.position,
            Quaternion.identity
        );

            // 不传 faceMask 时默认渲染 Cubemap 的六个面。
        //4.每帧更新cubemap
        captureCamera.RenderToCubemap(cubemap);//*
    }

    private void OnDisable()//退出时清理资源
    {
        if (cubemap != null)
        {
            cubemap.Release();
            DestroyOwnedObject(cubemap);
            cubemap = null;
        }

        if (captureCamera != null)
        {
            DestroyOwnedObject(captureCamera.gameObject);
            captureCamera = null;
        }

        propertyBlock = null;
    }

    private static void DestroyOwnedObject(Object target)//退出时清理资源
    {
        if (target == null)
            return;

        if (Application.isPlaying)
            Object.Destroy(target);
        else
            Object.DestroyImmediate(target);
    }
}
