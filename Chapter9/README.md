# used to explain URPshadoflow
![Shadow Effect drawing](https://github.com/smartrick125/Unity-Shader/blob/main/Chapter9/Images/shadow-display.png)
## URP Shadow Receiving Notes

This section records the shadow artifacts that appear when using a simple shadow-receiving implementation without URP macro handling, especially after enabling cascaded shadows.

* `AcceptShadow_simple`: a simple version that may produce incorrect shadow results when cascaded shadows are used.
* `AcceptShadow_cascade`: a URP-compatible version that uses URP's macro-based shadow handling for cascaded shadows.
