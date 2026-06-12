# Note on AlphaBlendBothSided in Chapter8
## English Version
The **AlphaBlendBothSided** exmaple mentioned in Chapter8 cannoy directly follow the old approach used in the Built-in Render Pipeline.

The reason is that modern SRP/URP,rending in mainly contorlled by **Queue** and **LightMode**. The rendering process is more like a mechanism that classifies rendering based on the purpose of each Pass, rather than simply executing the **Pass** block in the order they are written inside the same ShaderLab file.

Therefore, writing multiply **Pass** blocks in the same ShaderLab does not
guarantee that these passes will be render in the expected order. Insead, the rendering order dependes on **URP's rendering** process and its **LightMode** classificaation.

For **AlphaBlendBothSided**, since alpha blending usually requies **ZWrite** to be disabled, and **Cull** is also disabled, the rending order between frount faces and back faces become uncontrollable. This issue cannot be solved reliably by simply using the old multi-pass approach from the Built-in Render Pipeline.

## Recommended solutions are:
Use two separate materials to render the front faces and back faces separately;

Or use a Renderer Feature to customize the rendering process and control the order explicitly;
## 中文说明

Chapter 8 中涉及到的 AlphaBlendBothSided 无法直接使用内置渲染管线中的旧思路。

原因是，在现代 SRP / URP 中，渲染流程主要依赖 Queue 和 LightMode 进行控制。它更像是一种以 Pass 作用为分类依据的渲染机制，而不是简单按照同一个 ShaderLab 中 Pass 的书写顺序依次执行。

因此，在同一个 ShaderLab 中写多个 Pass，并不能保证这些 Pass 一定会按照预期顺序进行渲染，而是会依赖 URP 自身的渲染流程和 LightMode 分类来决定。

对于 AlphaBlendBothSided 这种情况，由于混合模式需要关闭 ZWrite，同时又关闭 Cull，会产生正反面透明混合顺序不可控的问题。这个问题无法仅靠内置管线中的旧式多 Pass 思路稳定解决。

## 更推荐的方式是：

使用双材质分别渲染正面和背面；
或者通过 Renderer Feature 自定义渲染流程来解决顺序问题。
