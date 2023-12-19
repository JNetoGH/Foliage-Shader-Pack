Shader "Unlit/JNetoCustom2GrassBend"
{

    Properties 
    {
        // SHADER VARIABLES ASSIGNED VIA MATERIAL
        
        // Base Textures
        _TipColor("Tip Color", Color) = (1, 1, 1, 1)
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _BladeTexture("Blade Texture", 2D) = "white" {}
        
        // Grass blade related stuff
    	_BendDelta("Bend Variation", Range(0, 1)) = 0.2
        _BladeWidthMin("Blade Width (Min)", Range(0, 0.1)) = 0.02 
        _BladeWidthMax("Blade Width (Max)", Range(0, 0.1)) = 0.05 
        _BladeHeightMin("Blade Height (Min)", Range(0, 2)) = 0.1
        _BladeHeightMax("Blade Height (Max)", Range(0, 2)) = 0.2
        _BladeSegments ("Blade Segments", Range(1, 10)) = 3 
        _BladeBendDistance("Blade Forward Amount", Float) = 0.38 
        _BladeBendCurve("Blade Curvature Amount", Range(1, 4)) = 2
        _TessellationGrassDistance("Tessellation Grass Distance", Range(0.01, 2)) = 0.1
        _GrassMap("Grass Visibility Map", 2D) = "white" {}
        _GrassThreshold("Grass Visibility Threshold", Range(-0.1, 1)) = 0.5
        _GrassFalloff("Grass Visibility Fade-In Falloff", Range(0, 0.5)) = 0.05
        
        _WindMap("Wind Offset Map", 2D) = "bump" {}
        _WindVelocity("Wind Velocity", Vector) = (1, 0, 0, 0)
        _WindFrequency("Wind Pulse Frequency", Range(0, 1)) = 0.01
    }

    SubShader
    {
         
        // Geometry tag on queue means it'll be rendered after the background but before transparent objects.
        Tags {
            "RenderType" = "Opaque"                 // Indicates that the object is opaque, doesn't have transparency.
            "Queue" = "Geometry"                    // Defines the rendering queue for the object
            "RenderPipeline" = "UniversalPipeline"  // Specifies the rendering pipeline the shader is designed for.
        }
        LOD 100
        Cull Off // disables back-face culling for the rendered object, turned off to show both sides of the grass.
        
        HLSLINCLUDE

            // Defining PI to rotate the blades.
            #define UNITY_PI 3.14159265359f
			#define UNITY_TWO_PI 6.28318530718f
            
            // Including the URP Shader Libraries
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            // Redefining properties as HLSL properties in the required CBuffer
            CBUFFER_START(UnityPerMaterial)
            
                float4 _BaseColor;
                float4 _TipColor;
                sampler2D _BladeTexture;

				float _BendDelta;
                float _BladewidthMin;
                float _BladeWidthMax;
                float _BladeHeightMin;
                float _BladeHeightMax;
                float _BladeBendDistance;
                float _BladeBendCurve;
                float _TessellationGrassDistance;
                sampler2D _GrassMap;
                float4 _GrassMap_ST;
                float _GrassThreshold;
                float _GrassFalloff;
            
                sampler2D _WindMap;
                float4 _WindMap_ST;
                float4 _WindVelocity;
                float _WindFrequency;
                float4 ShadowColor;
            
            CBUFFER_END
            
            struct VertexInput
            {
                float4 vertex : POSITION; // Semantics meaning: object space position
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
                float2 uv: TEXCOORD0; // UV Coord
            };

            struct VertexOutput
            {
                float4 vertex : SV_POSITION; // Semantics meaning: clip space position
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
                float2 uv: TEXCOORD0; // UV Coord
            };

            struct GeomData
            {
                float4 pos : SV_POSITION; // vertex position: clip space position
                float2 uv : TEXCOORD0; // UV Coord
                float3 worldPos: TEXCOORD1; // world space position
            };

            // Geometry functions derived from Roystan's tutorial:
            // https://roystan.net/articles/grass-shader.html
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
            
			// Simple noise function, sourced from Roystan's tutorial:
            // https://roystan.net/articles/grass-shader.html
			// Returns a number in the 0...1 range.
			float rand(float3 co)
			{
				return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
			}

			// Construct a rotation matrix that rotates around the provided axis, sourced from:
			// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
			float3x3 angleAxis3x3(float angle, float3 axis)
			{
				float c, s;
				sincos(angle, s, c);

				float t = 1 - c;
				float x = axis.x;
				float y = axis.y;
				float z = axis.z;

				return float3x3
				(
					t * x * x + c,      t * x * y - s * z,  t * x * z + s * y,
					t * x * y + s * z,  t * y * y + c,      t * y * z - s * x,
					t * x * z - s * y,  t * y * z + s * x,  t * z * z + c
				);
			}
            
            
        ENDHLSL

        Pass
        {
            
            Name "GrassPass"
            Tags { "RenderType"="UniversalForward" }
            
            HLSLPROGRAM
                
                // Shader declarations: Tell the HLSL which shader is the fragment and the vertex shader.
                #pragma require geometry
                #pragma vertex geomVert
                #pragma fragment frag
                #pragma geometry geom
                
                
                // Transforms form Object Space (VertexInput i) to world Space (VertexOutput o).
                // in order to the geometry shader generate teh grass.
                VertexOutput geomVert(VertexInput i)
                {
                    VertexOutput o;
                    o.vertex = float4(TransformObjectToWorld(i.vertex), 1.0f);
                    o.normal = TransformObjectToWorldNormal(i.normal);
                    o.tangent = i.tangent;
                    o.uv = TRANSFORM_TEX(i.uv, _GrassMap);
                    return o;
                }
            
                // Takes a single vertex position and the geometry data struct
                // TriangleStream<GeomData> acts like a list of vertex data
                [maxvertexcount(3)] // max number of vertexes the geom shader can output for each vertex input, 3 => 1 triangle.
                void geom(point VertexOutput input[1], inout TriangleStream<GeomData> triStream)
                {
                    // Each blade must be defined in tangent space, so it points along the vertex normal vectors,
                    // then apply a transformation from tangent to local space.
                    float3 pos = input[0].vertex.xyz;
                    float3 normal = input[0].normal;
                    float4 tangent = input[0].tangent;
                    float3 bitangent = cross(normal, tangent.xyz) * tangent.w;

                    // Tangent space to local space transformation matrix.
                    float3x3 tangentToLocal = float3x3
					(
						tangent.x, bitangent.x, normal.x,
						tangent.y, bitangent.y, normal.y,
						tangent.z, bitangent.z, normal.z
					);
            	
            		// Using the definition for Pi:
                    // 1) Rotates around the normal vector (y-axis) a random amount.
            		// 2) Rotates around the bottom of the blade (X-axis) a random amount.
					float3x3 randRotMatrix = angleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1.0f));
					float3x3 randBendMatrix = angleAxis3x3(rand(pos.zzx) * _BendDelta * UNITY_PI * 0.5f, float3(-1.0f, 0, 0));

					// Transform the grass blades to the correct tangent space.
            		// Only the tip vertex is influenced by the bend transformation.
            		// The vertical offset must be on the z-axis because it's in Tangent Space.
					// before transforming it to clip space
					float3x3 baseTransformationMatrix = mul(tangentToLocal, randRotMatrix);
					float3x3 tipTransformationMatrix = mul(mul(tangentToLocal, randBendMatrix), randRotMatrix);
            	
            		// Makes the 3 vertices of the grass blade
            		// The vertical offset must be on the z-axis because it's in Tangent Space.
                    triStream.Append(TransformGeomToClip(
                    	pos, float3(-0.1f, 0.0f, 0.0f), baseTransformationMatrix, float2(0.0f, 0.0f)));
                    triStream.Append(TransformGeomToClip(
                    	pos, float3(0.1f, 0.0f, 0.0f),  baseTransformationMatrix, float2(1.0f, 0.0f)));
                    triStream.Append(TransformGeomToClip(
                    	pos, float3(0.0f, 0.0f, 0.5f),  tipTransformationMatrix, float2(0.5f, 1.0f)));

                    // Ends the current triangle strip and starts a new one .
                    triStream.RestartStrip();   
                }

                // Blends the blade texture with the base and tip color using lerp.
                float4 frag(GeomData i): SV_Target
                {
                    float4 color = tex2D(_BladeTexture, i.uv);
                    color = color * lerp(_BaseColor, _TipColor, i.uv.y);
                    return color;
                }
                
            ENDHLSL
        }
        
    }
}
