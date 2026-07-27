using UnityEngine;
using UnityEngine.Rendering;

public class EdgeDetection_CustomVolumeComponent :
    VolumeComponent
{
    public ClampedFloatParameter edgesOnly =
        new ClampedFloatParameter(0f, 0f, 1f);

    public ColorParameter edgeColor =
        new ColorParameter(Color.black);

    public ColorParameter backgroundColor =
        new ColorParameter(Color.white);
}