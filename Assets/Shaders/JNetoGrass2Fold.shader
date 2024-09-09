// Developed by: João Neto
Shader "Unlit/JNetoGrass2Fold"
{

    Properties 
    {
        // SHADER VARIABLES ASSIGNED VIA MATERIAL
        
	    [Header(Base Texture)] [Space]
        _TintTop("Tint (Top)", Color) = (1, 1, 1, 1)
        _TintBottom("Tint (Bottom)", Color) = (0, 0, 0, 1)
        _Albedo("Albedo", 2D) = "white" {}
    	
        [Header(Folding)] [Space]
    	_FoldFactor("Fold Factor", Range(-2, 2)) = 0.14	// Controls the degree of folding applied to the grass leaves.
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

            // Defining PI to rotate the blades.
            #define PI 3.14
			#define TWO_PI 6.28
            
            // Including the URP Shader Libraries
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            // Redefining properties as HLSL properties in the required CBuffer
            CBUFFER_START(UnityPerMaterial)
            
                float4 _TintBottom;
                float4 _TintTop;
                sampler2D _Albedo;
				float _FoldFactor;
            
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
					float3x3 randRotMatrix = angleAxis3x3(rand(pos) * TWO_PI, float3(0, 0, 1.0f));
					float3x3 randBendMatrix = angleAxis3x3(rand(pos.zzx) * _FoldFactor * PI * 0.5f, float3(-1.0f, 0, 0));

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
                    float4 color = tex2D(_Albedo, i.uv);
                    color = color * lerp(_TintBottom, _TintTop, i.uv.y);
                    return color;
                }
                
            ENDHLSL
        }
        
    }
}
