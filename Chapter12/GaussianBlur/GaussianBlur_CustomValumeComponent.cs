using System;
using UnityEngine.Rendering;

[Serializable]
public class GaussianBlur_CustomValumeComponent : VolumeComponent
{
    public ClampedIntParameter iterations =
        new ClampedIntParameter(1, 0, 4);
    public ClampedFloatParameter blurSpread =
        new ClampedFloatParameter(1f, 0.2f, 3.0f);
    public ClampedIntParameter downSample =
        new ClampedIntParameter(1, 1, 8);
}