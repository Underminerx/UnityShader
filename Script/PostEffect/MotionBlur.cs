using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// ʵ��ԭ��1: ����һ���ۻ�����(accumulation buffer)��϶���������ͼ��,ȡ֮���ƽ��ֵ��Ϊ�����˶�ģ��ͼ�� (������)
/// ʵ��ԭ��2: �����ٶȻ���(velocity buffer),�洢�������ص�ǰ���˶��ٶ�,Ȼ����ݴ�ֵ����ģ���������С
/// </summary>
public class MotionBlur : PostEffectsBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial = null;
    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    [Range(0.0f, 0.9f)]
    public float blurAmount = 0.5f;

    // ����֮ǰͼ����ӵĽ��
    private RenderTexture accumulationTexture;

    // �ű�������ʱ����accumulationTexture �����´ο�ʼӦ���˶�ģ��ʱ���µ���ͼ��
    private void OnDisable()
    {
        DestroyImmediate(accumulationTexture);
    }

    [System.Obsolete]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material)
        {
            if (!accumulationTexture || accumulationTexture.width != source.width || accumulationTexture.height != source.height)
            {
                DestroyImmediate(accumulationTexture);
                accumulationTexture = new RenderTexture(source.width, source.height, 0);
                accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
                Graphics.Blit(source, accumulationTexture);
            }

            // �����֡���ۼ�motion
            accumulationTexture.MarkRestoreExpected();      // ��Ҫһ����Ⱦ����Ļָ�����

            material.SetFloat("_BlurAmount", 1.0f - blurAmount);

            Graphics.Blit(source, accumulationTexture, material);       // ��ǰ��Ļͼ��source���ӵ�accumulationTexture��
            Graphics.Blit(accumulationTexture, destination);            // ��ʾ���
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

}
