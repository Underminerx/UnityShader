using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// ʵ����Ļ����
//      ������������һ����Ļ����Ľű� (��ȡ��Ļ����Ⱦ����)
//          ����Graphics.Blit����ʹ���ض���Shader���Ե�ǰͼ����д���,�ٰѷ��ص���Ⱦ������ʾ����Ļ��
//              ����һЩ���ӵ���Ļ��Ч������Ҫ���ö��Graphics.Blit

// �ڽ��к���֮ǰ��Ҫ���һϵ�������Ƿ�����(ƽ̨�Ƿ�֧����Ⱦ�������Ļ��Ч,�Ƿ�֧�ֵ�ǰshader...)
// ʵ����Ļ��Чʱֻ��Ҫ�̳��Ըû�����ʵ���������в�ͬ�Ĳ�������
[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class PostEffectsBase : MonoBehaviour
{
    // ��ǰ�����Դ�����Ƿ�����
    protected void CheckResources()
    {
        // �����ٵ��� ��Զ����true
        // bool isSupported = CheckSupport();

        if (true /* !isSupported */ )
        {
            NotSupported();
        }

    }

    /// <summary>
    /// �ѹ�ʱ �����ٵ��� ��Զ����true
    /// </summary>
    /// <returns></returns>
    [Obsolete]
    protected bool CheckSupport()
    {
        if (!SystemInfo.supportsImageEffects || !SystemInfo.supportsRenderTextures)
        {
            Debug.LogWarning("ƽ̨��֧��ͼ����Ч����Ⱦ����!");
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

    // ����Ҫ������Ч��Ҫ�Ĳ���ʱ����
    protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
    {
        if (!shader)
        {
            return null;
        }

        // ���Ѿ���material�����ϵ�shader��ָ��shader��ֱ�ӷ��ش�material
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
