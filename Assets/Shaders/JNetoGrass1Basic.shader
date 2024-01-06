// Developed by: João Neto
Shader "Unlit/JNetoGrass1Basic"
{

    Properties 
    {
        // SHADER VARIABLES ASSIGNED VIA MATERIAL
        [Header(Base Texture)] [Space]
        _TintTop("Tint (Top)", Color) = (1, 1, 1, 1)
        _TintBottom("Tint (Bottom)", Color) = (0, 0, 0, 1)
        _Albedo("Albedo", 2D) = "white" {}
    }

    SubShader
    {
         
        Tags {
        	// Geometry tag on queue means it'll be rendered after the background but before transparent objects.
        	"Queue" = "Geometry"                    // Defines the rendering queue for the object
            "RenderType" = "Opaque"                 // Indicates that the object is opaque, doesn't have transparency.
            "RenderPipeline" = "UniversalPipeline"  // Specifies the rendering pipeline the shader is designed for.
        }
        
        LOD 100 
        Cull Off // disables back-face culling for the rendered object, turned off to show both sides of the grass.

        HLSLINCLUDE

            // Including the URP Shader Libraries
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
             
            // Redefining properties as HLSL properties in the required CBuffer
            CBUFFER_START(UnityPerMaterial)

                float4 _TintTop;
                float4 _TintBottom;
                sampler2D _Albedo;
            
            CBUFFER_END
            
            struct VertexInput
            {
                float4 vertex : POSITION; // Semantics meaning: object space position
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
            };

            struct VertexOutput
            {
                float4 vertex : SV_POSITION; // Semantics meaning: clip space position
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
            };

            struct GeomData
            {
                float4 pos : SV_POSITION; // vertex position: clip space position
                float2 uv : TEXCOORD0; // UV Coord
                float3 worldPos: TEXCOORD1; // world space position
            };
            
            // Generates the Geometry data, converting it to clip space.
            // This func takes the root position of the grass blade and allow to apply a offset with a transformation
            // that allow things like rotate and bend.
            GeomData TransformGeomToClip(float3 pos, float3 offset, float3x3 transformationMatrix, float2 uv)
            {
                GeomData o;
                o.pos = TransformObjectToHClip(pos + mul(transformationMatrix, offset));
                o.uv = uv;
                o.worldPos = TransformObjectToWorld(pos + mul(transformationMatrix, offset));
                return o;
            }
            
        ENDHLSL

        Pass
        {
            
            Name "GrassPass"
            Tags { "RenderType"="UniversalForward" }
            
            HLSLPROGRAM

                // Shader declarations: Tell the HLSL which shader is the fragment and the vertex shader.
                #pragma require geometry
                #pragma vertex vert
                #pragma fragment frag
                #pragma geometry geom
                
                // Transforms form Object Space (VertexInput i) to world Space (VertexOutput o).
                // in order to the geometry shader generate teh grass.
                VertexOutput vert(VertexInput i)
                {
                    VertexOutput o;
                    o.vertex = float4(TransformObjectToWorld(i.vertex), 1.0f);
                    o.normal = TransformObjectToWorldNormal(i.normal);
                    o.tangent = i.tangent;
                    return o;
                }
            
                // Takes a single vertex position and the geometry data struct
                // TriangleStream<GeomData> acts like a list of vertex data
                [maxvertexcount(3)] // max number of vertexes the geom shader can output for each vertex input, 3 => 1 triangle.
                void geom(point VertexOutput input[1], inout TriangleStream<GeomData> triStream)
                {
                    float3 pos = input[0].vertex.xyz;
                
                    // identity matrix for transformations
                    float3x3 identity = float3x3
                    (
                        1, 0, 0,
                        0, 1, 0,
                        0, 0, 1
                    );

                    // Makes the 3 vertices of the grass leaf
                    triStream.Append(TransformGeomToClip(pos, float3(-0.1, 0, 0), identity, float2(0, 0)));
                    triStream.Append(TransformGeomToClip(pos, float3(0.1, 0, 0),  identity, float2(1, 0)));
                    triStream.Append(TransformGeomToClip(pos, float3(0, 0.5, 0),  identity, float2(0.5, 1)));

                    // Ends the current triangle strip and starts a new one .
                    triStream.RestartStrip();   
                }

                // Blends the base texture with the bottom and top tint using lerp.
                float4 frag(GeomData i): SV_Target
                {
                    float4 color = tex2D(_Albedo, i.uv);
                    color = color * lerp(_TintBottom, _TintTop, i.uv.y);
                    return color;
                }
                
            ENDHLSL
        }
        
    }
}
