using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// 实现屏幕后处理
//      在摄像机中添加一个屏幕后处理的脚本 (获取屏幕的渲染纹理)
//          调用Graphics.Blit函数使用特定的Shader来对当前图像进行处理,再把返回的渲染纹理显示到屏幕上
//              对于一些复杂的屏幕特效可能需要调用多次Graphics.Blit

// 在进行后处理之前需要检查一系列条件是否满足(平台是否支持渲染纹理和屏幕特效,是否支持当前shader...)
// 实现屏幕特效时只需要继承自该基类再实现派生类中不同的操作即可
[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class PostEffectsBase : MonoBehaviour
{
    // 提前检查资源条件是否满足
    protected void CheckResources()
    {
        // 无需再调用 永远返回true
        // bool isSupported = CheckSupport();

        if (true /* !isSupported */ )
        {
            NotSupported();
        }

    }

    /// <summary>
    /// 已过时 无需再调用 永远返回true
    /// </summary>
    /// <returns></returns>
    [Obsolete]
    protected bool CheckSupport()
    {
        if (!SystemInfo.supportsImageEffects || !SystemInfo.supportsRenderTextures)
        {
            Debug.LogWarning("平台不支持图像特效或渲染纹理!");
            return false;
        }
        return true;
    }

    protected void NotSupported()
    {
        enabled = false;
    }

    protected void Start()
    {
        CheckResources();
    }

    // 当需要创建特效需要的材质时调用
    protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
    {
        if (!shader)
        {
            return null;
        }

        // 若已经有material且其上的shader是指定shader则直接返回此material
        if (shader.isSupported && material && material.shader == shader)
        {
            return material;
        }

        if (!shader.isSupported)
        {
            return null;
        }
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            if (material)
            {
                return material;
            }
            else
            {
                return null;
            }
        }

    }
}
