using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// ����ʵ�ַ�ʽ�ǽ��������������嶼������Ч��
/// ��ʱ����ϣ��ֻ���ض�����������
/// ����ʹ��Unity�ṩ��Graphics.DrawMesh����Graphics.DrawMeshNow��������Ҫ��ߵ���������Ⱦһ��(�����в�͸��������Ⱦ��Ϻ�)
/// Ȼ����ʹ�ñ�Ե����㷨������Ȼ��߷���������ÿ�����ص��ݶ�ֵ,�ж������Ƿ�С��ĳ����ֵ С������shader��ʹ��clip()�������������޳���,��ʾԭ��������ɫ
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
    /// �����+�����������ʱʹ�õĲ������� ֵԽ�� ���Խ��
    /// </summary>
    public float sampleDistance = 1.0f;

    // ��������Ӱ�쵱ǰ��������ֵ���߷���ֵ������ʱ�ᱻ��Ϊ����һ���߽�
    public float sensitivityDepth = 1.0f;       

    public float sensituvityNormals = 1.0f;

    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    // ��������²�͸����͸����pass������Ⱦ��Ϻ�ŵ���OnRenderImage����
    // ��ӱ�ǩ����ʹ���ڲ�͸����pass��Ⱦ��Ͼ͵��ô�OnRenderImage����
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
