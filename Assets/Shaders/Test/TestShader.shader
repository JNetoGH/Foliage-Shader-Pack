Shader "Unlit/TestShader"
{
    
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor  ("Base Color", Color) = (1, 1, 1, 1)
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        HLSLINCLUDE
        
            // Including the URP Core Shader Library
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Redefining properties as HLSL properties in the required CBuffer
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
            CBUFFER_END

            // Defines the texture and its sampler
            // Textures don't need to be defined again in the CBuffer.
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct VertexInput
            {
                float4 position: POSITION; // Semantics meaning: object space position
                float2 uv : TEXCOORD0; // uv coordinates
            };

            struct FragOutput
            {
                float4 position: SV_POSITION; // Semantics meaning: clip space position
                float2 uv : TEXCOORD0; // uv coordinates
            };
                
        ENDHLSL
        
        Pass
        {
            HLSLPROGRAM

                // Tells the Hlsl which shader is the fragment and the vertex shader.
                #pragma vertex vert
                #pragma fragment frag

                // Transforms the Object Space (VertexInput) to Clip Space (FragOutput o)
                FragOutput vert(VertexInput i)
                {
                    FragOutput o;
                    o.position = TransformObjectToHClip(i.position.xyz);
                    o.uv = i.uv;
                    return o;
                }

                // Uses the FragOutput where the coordinates are in clip space to blend the texture with a color
                float4 frag(FragOutput i): SV_Target
                {
                    float4 sampledFrag = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                    return sampledFrag * _BaseColor;
                }
                
            ENDHLSL
        }
    }

}
