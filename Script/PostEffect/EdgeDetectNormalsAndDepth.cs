using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 这种实现方式是将整个场景中物体都添加描边效果
/// 有时我们希望只对特定物体进行描边
/// 可以使用Unity提供的Graphics.DrawMesh或者Graphics.DrawMeshNow函数把需要描边的物体再渲染一遍(在所有不透明物体渲染完毕后)
/// 然后再使用边缘检测算法计算深度或者法线纹理中每个像素的梯度值,判断它们是否小于某个阈值 小于则再shader中使用clip()函数将该像素剔除掉,显示原来物体颜色
/// </summary>
public class EdgeDetectNormalsAndDepth : PostEffectsBase
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

    /// <summary>
    /// 对深度+法线纹理采样时使用的采样距离 值越大 描边越宽
    /// </summary>
    public float sampleDistance = 1.0f;

    // 以下两个影响当前邻域的深度值或者法线值相差多少时会被认为存在一条边界
    public float sensitivityDepth = 1.0f;       

    public float sensituvityNormals = 1.0f;

    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    // 正常情况下不透明和透明的pass都被渲染完毕后才调用OnRenderImage函数
    // 添加标签可以使得在不透明的pass渲染完毕就调用此OnRenderImage函数
    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material)
        {
            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);
            material.SetFloat("_SampleDistance", sampleDistance);
            material.SetVector("_Sensitivity", new Vector4(sensituvityNormals, sensitivityDepth, 0.0f, 0.0f));

            Graphics.Blit(source, destination, edgeDetectionMaterial);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
