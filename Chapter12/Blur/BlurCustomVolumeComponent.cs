using System;
using UnityEngine.Rendering;

// [VolumeComponentMenu] 属性用于在 Volume 的 Add Override 菜单中注册该组件
// 添加后可以在 Add Override -> Custom Post-processing -> Blur 路径下找到
[Serializable]
[VolumeComponentMenu("Custom Post-processing/Blur")]
public class BlurCustomVolumeComponent : VolumeComponent
{
    // 横向模糊强度：使用 ClampedFloatParameter 限制参数范围（最小 0，最大 0.5，默认 0.05）
    public ClampedFloatParameter horizontalBlur =
            new ClampedFloatParameter(0.05f, 0, 0.5f);

    // 纵向模糊强度：使用 ClampedFloatParameter 限制参数范围（最小 0，最大 0.5，默认 0.05）
    public ClampedFloatParameter verticalBlur =
        new ClampedFloatParameter(0.05f, 0, 0.5f);
}
