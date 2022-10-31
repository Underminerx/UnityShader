using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 实现原理： 根据一个阈值提取出图像中较亮的部分,存储在一个另外纹理中,进行高斯模糊,模拟光线扩散,最后与原图像进行混合
/// </summary>
public class Bloom : PostEffectsBase
{
    public Shader bloomShader;
    private Material bloomMaterial;
    public Material material
    {
        get
        {
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }

    [Range(0, 4)]
    public int iterations = 3;

    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;

    [Range(1, 8)]
    public int dowmSample = 2;

    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);

            int rtW = source.width / dowmSample;
            int rtH = source.height / dowmSample;

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtH, rtW, 0);
            buffer0.filterMode = FilterMode.Bilinear;

            Graphics.Blit(source, buffer0, material, 0);

            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1, material, 1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1 , material, 2);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }
            material.SetTexture("_Bloom", buffer0);
            Graphics.Blit(source, destination, material, 3);

            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }


}
