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
    /// 高斯模糊迭代次数
    /// </summary>
    [Range(0, 4)]
    public int iterations = 3;

    /// <summary>
    /// 高斯模糊范围
    /// </summary>
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;


    /// <summary>
    /// 缩放系数 越大需要处理的像素数越少,进一步提高模糊程度,但过大可能会导致像素化
    /// </summary>
    [Range(1, 8)]
    public int downSample = 2;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        #region 初始版本
        //// 版本1
        //if (material)
        //{
        //    int rtW = source.width;
        //    int rtH = source.height;
        //    // 分配一块与屏幕图像大小相同的buffer 存储第一个pass执行完毕后的模糊结果
        //    RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);

        //    // 渲染垂直pass
        //    Graphics.Blit(source, buffer, material, 0);
        //    // 渲染水平pass
        //    Graphics.Blit(buffer, destination, material, 1);

        //    // 释放buffer
        //    RenderTexture.ReleaseTemporary(buffer);
        //}
        //else
        //{
        //    Graphics.Blit(source, destination);
        //}

        //// 版本2 降采样
        //if (material)
        //{
        //    int rtW = source.width / downSample;
        //    int rtH = source.height / downSample;
        //    RenderTexture buffer = RenderTexture.GetTemporary(rtH, rtW, 0);
        //    buffer.filterMode = FilterMode.Bilinear;
        //    // 渲染垂直pass
        //    Graphics.Blit(source, buffer, material, 0);
        //    // 渲染水平pass
        //    Graphics.Blit(buffer, destination, material, 1);

        //    // 释放buffer
        //    RenderTexture.ReleaseTemporary(buffer);
        //}
        //else
        //{
        //    Graphics.Blit(source, destination);
        //}
        #endregion

        // 版本3 加入迭代次数 两个buffer左右横跳迭代
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
                // 渲染垂直pass
                Graphics.Blit(buffer0, buffer1, material, 0);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                
                // 渲染水平pass
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
