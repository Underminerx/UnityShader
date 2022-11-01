using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 实现原理1: 利用一块累积缓存(accumulation buffer)混合多张连续的图像,取之间的平均值作为最后的运动模糊图像 (开销大)
/// 实现原理2: 利用速度缓存(velocity buffer),存储各个像素当前的运动速度,然后根据此值决定模糊方向与大小
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

    // 保存之前图像叠加的结果
    private RenderTexture accumulationTexture;

    // 脚本不运行时销毁accumulationTexture 这样下次开始应用运动模糊时重新叠加图像
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

            // 不清除帧以累计motion
            accumulationTexture.MarkRestoreExpected();      // 需要一个渲染纹理的恢复操作

            material.SetFloat("_BlurAmount", 1.0f - blurAmount);

            Graphics.Blit(source, accumulationTexture, material);       // 当前屏幕图像source叠加到accumulationTexture中
            Graphics.Blit(accumulationTexture, destination);            // 显示结果
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

}
