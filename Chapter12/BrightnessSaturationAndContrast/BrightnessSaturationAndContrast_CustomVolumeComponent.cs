using System;
using UnityEngine.Rendering;

[Serializable]
public class BrightnessSaturationAndContrast_CustomVolumeComponent : VolumeComponent
{
    public ClampedFloatParameter brightness =
        new ClampedFloatParameter(1.0f, 0.0f, 3.0f);
    public ClampedFloatParameter saturation =
        new ClampedFloatParameter(1.0f, 0.0f, 3.0f);
    public ClampedFloatParameter contrast =
        new ClampedFloatParameter(1.0f, 0.0f, 3.0f);
}
