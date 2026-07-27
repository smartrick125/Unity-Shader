using System;
using UnityEngine;
using UnityEngine.Rendering;

// [VolumeComponentMenu] 属性用于在 Volume 的 Add Override 菜单中注册该组件
[Serializable]
[VolumeComponentMenu("Custom Post-processing/Template Effect")]
public class TemplateVolumeComponent : VolumeComponent
{
    // 1. 开关参数：可以用 BoolParameter 控制特效是否开启
    public BoolParameter isEnabled = new BoolParameter(false);

    // 2. 数值参数：使用 ClampedFloatParameter 限制参数范围，并设置默认值
    public ClampedFloatParameter intensity = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);

    // 3. 颜色参数：用于色调混合等效果
    public ColorParameter tintColor = new ColorParameter(Color.white);

    // 4. 判断当前特效是否应该处于激活状态
    public bool IsActive() => isEnabled.value && intensity.value > 0.0f;
}
