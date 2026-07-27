using UnityEngine;
using UnityEngine.Rendering;

[DisallowMultipleComponent]
public sealed class CubemapCapturePoint : MonoBehaviour
{
    [Header("Target Renderer")]
    [SerializeField] private Renderer targetRenderer;

    [Header("Cubemap Shader Property")]
    [SerializeField] private string textureProperty = "_EnvironmentCube";

    [Header("Optional Explicit Resources")]
    [Tooltip("Optional. Leave empty to let this component create a runtime cubemap.")]
    [SerializeField] private Camera captureCamera;

    [Tooltip("Optional. Must be a RenderTexture whose Dimension is Cube.")]
    [SerializeField] private RenderTexture targetCubemap;

    [Header("Capture Settings")]
    [SerializeField, Range(16, 1024)]
    private int resolution = 128;

    [SerializeField] private LayerMask cullingMask = ~0;

    [SerializeField, Min(0.01f)]
    private float nearClip = 0.1f;

    [SerializeField, Min(1f)]
    private float farClip = 100f;

    [Header("Performance")]
    [Tooltip("When enabled, only one cubemap face is rendered per frame.")]
    [SerializeField] private bool oneFacePerFrame = true;

    private RenderTexture runtimeCubemap;
    private MaterialPropertyBlock propertyBlock;
    private int currentFace;
    private bool ownsCaptureCamera;
    private bool ownsRuntimeCubemap;

    private RenderTexture ActiveCubemap => targetCubemap != null ? targetCubemap : runtimeCubemap;

    private void OnEnable()
    {
        CreateResources();
        RenderCubemapFaces(63);
    }

    private void LateUpdate()
    {
        CreateResources();

        if (captureCamera == null || ActiveCubemap == null)
            return;

        if (oneFacePerFrame)
        {
            int faceMask = 1 << currentFace;

            RenderCubemapFaces(faceMask);

            currentFace = (currentFace + 1) % 6;
        }
        else
        {
            RenderCubemapFaces(63);
        }
    }

    [ContextMenu("Render Cubemap")]
    private void RenderCubemap()
    {
        CreateResources();
        RenderCubemapFaces(63);
    }

    private void CreateResources()
    {
        if (targetRenderer == null)
            targetRenderer = GetComponent<Renderer>();

        if (captureCamera == null)
        {
            GameObject cameraObject = new GameObject("Realtime Cubemap Camera");
            cameraObject.hideFlags = HideFlags.HideAndDontSave;

            captureCamera = cameraObject.AddComponent<Camera>();
            ownsCaptureCamera = true;
        }

        captureCamera.enabled = false;
        captureCamera.clearFlags = CameraClearFlags.Skybox;
        captureCamera.cullingMask = cullingMask;
        captureCamera.nearClipPlane = nearClip;
        captureCamera.farClipPlane = farClip;
        captureCamera.allowHDR = true;
        captureCamera.allowMSAA = false;

        if (targetCubemap != null)
        {
            if (targetCubemap.dimension != TextureDimension.Cube)
            {
                Debug.LogWarning(
                    "Target Cubemap must be a RenderTexture with Dimension set to Cube.",
                    this
                );
                return;
            }

            if (!targetCubemap.IsCreated())
                targetCubemap.Create();
        }
        else if (runtimeCubemap == null)
        {
            runtimeCubemap = new RenderTexture(
                resolution,
                resolution,
                24,
                RenderTextureFormat.DefaultHDR
            )
            {
                dimension = TextureDimension.Cube,
                wrapMode = TextureWrapMode.Clamp,
                filterMode = FilterMode.Bilinear,
                useMipMap = false,
                autoGenerateMips = false,
                hideFlags = HideFlags.HideAndDontSave,
                name = "Realtime Environment Cubemap"
            };

            runtimeCubemap.Create();
            ownsRuntimeCubemap = true;
        }

        if (targetRenderer != null)
        {
            if (propertyBlock == null)
                propertyBlock = new MaterialPropertyBlock();

            targetRenderer.GetPropertyBlock(propertyBlock);
            propertyBlock.SetTexture(textureProperty, ActiveCubemap);
            targetRenderer.SetPropertyBlock(propertyBlock);
        }
    }

    private void RenderCubemapFaces(int faceMask)
    {
        if (captureCamera == null || ActiveCubemap == null)
            return;

        captureCamera.transform.SetPositionAndRotation(
            transform.position,
            Quaternion.identity
        );

        bool success = captureCamera.RenderToCubemap(
            ActiveCubemap,
            faceMask
        );

        if (!success)
        {
            Debug.LogWarning(
                "Realtime cubemap rendering failed.",
                this
            );
        }
    }

    private void OnDisable()
    {
        if (ownsRuntimeCubemap && runtimeCubemap != null)
        {
            runtimeCubemap.Release();
            DestroyOwnedObject(runtimeCubemap);
        }

        runtimeCubemap = null;
        ownsRuntimeCubemap = false;

        if (ownsCaptureCamera && captureCamera != null)
        {
            DestroyOwnedObject(captureCamera.gameObject);
            captureCamera = null;
        }

        ownsCaptureCamera = false;
        propertyBlock = null;
    }

    private static void DestroyOwnedObject(Object target)
    {
        if (target == null)
            return;

        if (Application.isPlaying)
            Object.Destroy(target);
        else
            Object.DestroyImmediate(target);
    }
}
