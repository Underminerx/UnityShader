using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// ±ﬂ‘µºÏ≤‚À„∑®
/// </summary>
public class EdgeDetection : PostEffectsBase
{
    public Shader edgeDetectionShader;
    private Material edgeDetectionMaterial = null;
    public Material material
    {
        get
        {
            edgeDetectionMaterial = CheckShaderAndCreateMaterial(edgeDetectionShader, edgeDetectionMaterial);
            return edgeDetectionMaterial;
        }
    }

    [Range(0.0f, 1.0f)]
    public float edgesOnly = 0.0f;

    public Color edgeColor = Color.black;

    public Color backgroundColor = Color.white;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material)
        {
            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);
            
            Graphics.Blit(source, destination, edgeDetectionMaterial);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
