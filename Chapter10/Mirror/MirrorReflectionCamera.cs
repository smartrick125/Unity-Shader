using UnityEngine;

[ExecuteAlways]
public class MirrorReflectionCamera : MonoBehaviour
{
    [Header("References")]
    public Camera mainCamera;
    public Camera reflectionCamera;
    public RenderTexture targetTexture;

    [Header("Mirror Plane")]
    public Transform mirrorPlane;

    [Header("Settings")]
    public LayerMask reflectionCullingMask = ~0;

    private void LateUpdate()
    {
        if (mainCamera == null)
            mainCamera = Camera.main;

        if (mainCamera == null || reflectionCamera == null || mirrorPlane == null)
            return;

        if (targetTexture != null)
            reflectionCamera.targetTexture = targetTexture;

        // 复制主相机基础参数
        reflectionCamera.fieldOfView = mainCamera.fieldOfView;
        reflectionCamera.aspect = mainCamera.aspect;
        reflectionCamera.nearClipPlane = mainCamera.nearClipPlane;
        reflectionCamera.farClipPlane = mainCamera.farClipPlane;
        reflectionCamera.orthographic = mainCamera.orthographic;
        reflectionCamera.orthographicSize = mainCamera.orthographicSize;
        reflectionCamera.cullingMask = reflectionCullingMask;

        Vector3 planePos = mirrorPlane.position;
        Vector3 planeNormal = mirrorPlane.up.normalized;

        // 镜像相机位置
        Vector3 cameraPos = mainCamera.transform.position;
        float distanceToPlane = Vector3.Dot(cameraPos - planePos, planeNormal);
        Vector3 reflectedPos = cameraPos - 2f * distanceToPlane * planeNormal;

        // 镜像相机朝向
        Vector3 reflectedForward = Vector3.Reflect(mainCamera.transform.forward, planeNormal);
        Vector3 reflectedUp = Vector3.Reflect(mainCamera.transform.up, planeNormal);

        reflectionCamera.transform.position = reflectedPos;
        reflectionCamera.transform.rotation = Quaternion.LookRotation(reflectedForward, reflectedUp);
    }
}