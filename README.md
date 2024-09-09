![image](https://github.com/JNetoGH/Foliage-Shader-Pack/assets/24737993/4987003b-1d69-49c1-b5b9-1a97191e66e7)


# JNeto Foliage Shader
João Neto (a22200558)

<br>
<br>

## PREVIEW


https://github.com/JNetoGH/Foliage-Shader-Pack/assets/24737993/e09d0638-80e0-4a9f-a770-0354d41e4a7c




<br>
<br>

## IMPORTANT!!!
Do not attempt to update the Unity version to any above 2021 LTS, it may cause compatibility issues due to the material upgrade process.

![image](https://github.com/JNetoGH/Foliage-Shader-Pack/assets/24737993/21bab29a-5586-4e35-8fa7-3612aff0bd80)

<br>
<br>

##  FEATURES
**Flexibity**
You can apply this shader to generate foliage on pretty much any object with a mesh.

https://github.com/JNetoGH/Foliage-Shader-Pack/assets/24737993/2bd31a88-2d45-42b5-b244-5f266db52a2f

<br>

**Customization**
The leaves are completely brown customizable in color, shape, curvature and speed.

https://github.com/JNetoGH/Foliage-Shader-Pack/assets/24737993/d9e61405-092d-4aa1-bbd3-b4ca8e639174

<br>
<br>

## OVERVIEW
This report encompasses every aspect of my journey in creating a functional and customizable Foliage Shader. I've included all iterations starting from the initial stages within the project as materials. This documentation showcases my progression and development over time.
I've included some examples of customization possibilities using this shader in the main scene of this project. To fully explore them, it's recommended to enter play mode.

<br>
<br>

## DEV REPORT
**Pre-Production**

At first, I explored multiple methods for generating procedural grass, but the two main approachs were utilizing compute shaders (following Ned Makes Games take) or making a geometry shader (following Roystan's take). After my research, I opted for the geometry shader approach. Although compute shaders can do pretty much anything, I chose geometry shaders as they are specifically designed for creating geometry. I considered this to be a more natural and straightforward solution for generating procedural vegetation.

**TestShader.shader**

This was the first step to create a geometry shader. This is a very basic shader which i made by searching for "Unity shader development basics" (sources at the references), and this shader only outputs a simple texture on a surface but serves as a base with all the necessary boilerplate code, allowing me to explore and study the basics of ShaderLab and HLSL development, such as Properties, CBuffer, Semantic, etc...

<img width="490" alt="image" src="https://github.com/JNetoGH/Foliage-Shader-Pack/assets/24737993/93d658f0-311c-4823-90a3-b9c6df4ee564">

<br>
<br>

**JNetoGrass1Basic.Shader**

In my initial iteration, I created a geometry shader to generate procedural grass using a TriangleStream. This shader generates new geometry for each vertex through a specific struct passed to the TriangleStream. 
The vertex shader converts vertex coordinates from object space to clip space and also transforms normal and tangent information to world space. This is crucial for preparing data that will be used in the geometry generation.
There is a fragment shader that blends the base texture with the bottom and top tint using lerp.
However, in this version, all the generated leaves point upwards without any customization options.

<img width="490" alt="image" src="https://github.com/JNetoGH/Foliage-Shader-Pack/assets/24737993/10c5c412-1cc2-42b2-82a2-8b547676b4be">
<br>
<br>


**JNetoGrass2Fold.Shader**

This shader introduces a new feature compared to the previous shader iteration. It incorporates a "Fold Factor" property that controls the degree of folding applied to the grass leaves. This factor allows adjusting the degree of folding effect applied to the procedural vegetation, providing more flexibility and variation in the appearance of the grass blades.
It also uses a transformation matrix, aligning the grass blades along their respective normals using tangent space to local space conversion, it fixes the previous issue of the blades only pointing up.
The shader uses two rotation matrices to achieve the folding effect. One rotates the grass blades randomly around their normal vector (y-axis), while the other rotates them around their base (X-axis). These rotations create variation in the orientation of the grass blades, resembling the natural folding patterns seen in real vegetation.

<img width="490" alt="image" src="https://github.com/JNetoGH/Foliage-Shader-Pack/assets/24737993/a48e6642-91b7-4fc9-98ce-11d734ecef83">
<br>
<br>

**JNetoGrass3Shape.Shader**

This was the hardest iteration and added these new features to the shader:
Curvature Control, This iteration introduces the ability to manage the extent and intensity of curvature along the grass leaves. The properties, _CurveDistance and _CurveIntensity, allow adjusting the curve.
Width and Height Variability, Now it's posbbile to set a random range to the width and height of the leaves, by setting the minimum and maximum values for both the width (_MinWidth and _MaxWidth) and height (_MinHeight and _MaxHeight) of the grass blades.
More Complex Shapes, It defines the number of segments (NUM_OF_SEGMENTS) to create different shapes within the geometry. By incorporating more segments in the generation process, it enables more complex shapes, in constrast to the previous iteration where the segments were hardcoded, and accomplishes it by iterating the segment creation using a for loop instead of manually setting them to the TriangleStream.

<img width="490" alt="image" src="https://github.com/JNetoGH/Foliage-Shader-Pack/assets/24737993/c648cf1e-c62a-48c6-b639-120ea9114544">
<br>
<br>

**JNetoGrass4Wind.Shader**

In this shader version, the wind effect is implemented using the "_WindForce" property. This property represents the strength or intensity of the wind that affects the grass leaves. The wind force is used in the calculation of the fold factor (_FoldFactor) before getting the matrix responsible for the folding/bending of the leaves.
It creates wind oscillation by doing sin(_Time.y * _WindForce), which is responsible for altering the folding calculations.

https://github.com/JNetoGH/Foliage-Shader-Pack/assets/24737993/638c3612-28a4-4af6-84dc-db180afc3733

<br>
<br>

## References

**ShaderLab Basics** (Cyan Gamedev: <br>
https://cyangamedev.wordpress.com/2020/06/05/urp-shader-code/2/

**HLSL Basics** (Cyan Gamedev): <br>
https://cyangamedev.wordpress.com/2020/06/05/urp-shader-code/3/

**Shader Code in URP** (Daniel Ilett): <br>
https://danielilett.com/2021-04-02-basics-3-shaders-in-urp/

**Six Grass Rendering Techniques in Unity** (Daniel Ilett): <br>
https://danielilett.com/2022-12-05-tut6-2-six-grass-techniques/

**Rendering Grass In Unity URP Using Noise and Geometry Shaders** (Ned Makes Games): <br>
https://www.youtube.com/watch?v=YghAbgCN8XA

**Stylised Grass with Shaders in URP (Daniel Ilett):** <br>
https://danielilett.com/2021-08-24-tut5-17-stylised-grass/

**Blade Grass! Generate and Bake a Field Mesh Using a Compute Shader** (Ned Makes Games): <br>
https://www.youtube.com/watch?v=6SFTcDNqwaA&t=484s

**Roystan's Grass Shader** (Roystan): <br>
[https://docs.unity3d.com/Manual/ExecutionOrder.html](https://roystan.net/articles/grass-shader/)https://roystan.net/articles/grass-shader/

<br>
<br>
<br>
