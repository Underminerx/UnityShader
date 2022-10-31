using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlur : PostEffectsBase
{
    public Shader gaussianBlurShader;
    private Material gaussianBlurMaterial = null;
    public Material material
    {
        get
        {
            gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }
    }

    /// <summary>
    /// ��˹ģ����������
    /// </summary>
    [Range(0, 4)]
    public int iterations = 3;

    /// <summary>
    /// ��˹ģ����Χ
    /// </summary>
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;


    /// <summary>
    /// ����ϵ�� Խ����Ҫ�����������Խ��,��һ�����ģ���̶�,��������ܻᵼ�����ػ�
    /// </summary>
    [Range(1, 8)]
    public int downSample = 2;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        #region ��ʼ�汾
        //// �汾1
        //if (material)
        //{
        //    int rtW = source.width;
        //    int rtH = source.height;
        //    // ����һ������Ļͼ���С��ͬ��buffer �洢��һ��passִ����Ϻ��ģ�����
        //    RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);

        //    // ��Ⱦ��ֱpass
        //    Graphics.Blit(source, buffer, material, 0);
        //    // ��Ⱦˮƽpass
        //    Graphics.Blit(buffer, destination, material, 1);

        //    // �ͷ�buffer
        //    RenderTexture.ReleaseTemporary(buffer);
        //}
        //else
        //{
        //    Graphics.Blit(source, destination);
        //}

        //// �汾2 ������
        //if (material)
        //{
        //    int rtW = source.width / downSample;
        //    int rtH = source.height / downSample;
        //    RenderTexture buffer = RenderTexture.GetTemporary(rtH, rtW, 0);
        //    buffer.filterMode = FilterMode.Bilinear;
        //    // ��Ⱦ��ֱpass
        //    Graphics.Blit(source, buffer, material, 0);
        //    // ��Ⱦˮƽpass
        //    Graphics.Blit(buffer, destination, material, 1);

        //    // �ͷ�buffer
        //    RenderTexture.ReleaseTemporary(buffer);
        //}
        //else
        //{
        //    Graphics.Blit(source, destination);
        //}
        #endregion

        // �汾3 ����������� ����buffer���Һ�������
        if (material)
        {
            int rtW = source.width / downSample;
            int rtH = source.height / downSample;
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtH, rtW, 0);
            buffer0.filterMode = FilterMode.Bilinear;

            Graphics.Blit(source, buffer0);

            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtH, rtW, 0);
                // ��Ⱦ��ֱpass
                Graphics.Blit(buffer0, buffer1, material, 0);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                
                // ��Ⱦˮƽpass
                Graphics.Blit(buffer0, buffer1, material, 1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }
            Graphics.Blit(buffer0, destination);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
