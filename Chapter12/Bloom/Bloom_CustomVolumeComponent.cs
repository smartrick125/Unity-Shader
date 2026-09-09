using System;
using UnityEngine.Rendering;

[Serializable]
public class Bloom_CustomValumeComponent : VolumeComponent
{
    public ClampedIntParameter iterations =
        new ClampedIntParameter(1, 0, 6);
    public ClampedFloatParameter blurSpread =
        new ClampedFloatParameter(1f, 0.2f, 3.0f);
    public ClampedIntParameter downSample =
        new ClampedIntParameter(1, 1, 8);
    public ClampedFloatParameter luminanceThreshlod =
        new ClampedFloatParameter(0.6f, 0, 4.0f);
}