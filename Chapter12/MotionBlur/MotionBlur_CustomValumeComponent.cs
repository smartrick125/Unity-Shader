using System;
using UnityEngine.Rendering;

[Serializable]
public class CustomVolumeComponent : VolumeComponent
{
    public ClampedFloatParameter blurAmount =
           new ClampedFloatParameter(0.5f, 0, 0.9f);
}
