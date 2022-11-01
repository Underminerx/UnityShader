using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// ��������ӳ����������������ַ���:
// 1.ֱ����һЩ���Ⲽ��������(�Ƽ�, ���Զ��������ݽ���ѹ��, ֧�ֱ�Ե�������⻬����glossy reflection��HDR)
   
//         �ṩһ�ž������Ⲽ�ֵ�����,��������������չ��ͼ�Ľ��沼�֡�ȫ�����ֵ�,Ȼ��Texture Type����ΪCubemap����
// 			�ڻ����������Ⱦ��, ͨ��ʹ��һ��HDRͼ�������ɸ�����Cubemap
// 	2.�ֶ�����һ��Cubemap��Դ, ������ͼ������
// 		Unity 5 ֮ǰ�ķ���
// 	3.�ɽű����� (ǰ���ֶ���Ҫ������ǰ׼���������������ͼ��, �õ������������������Ǳ����������������õ�)
// 				(�����������������ϣ�����������ڳ�����λ�õĲ�ͬ���ɲ�ͬ������������)
//         ͨ��Unity�ṩ��Camera.RenderToCubemap����ʵ��,���԰Ѵ�����λ�ù۲쵽�ĳ���ͼ��洢������ͼ����,�Ӷ���������λ���϶�Ӧ������������

[ExecuteInEditMode]
public class ProceduralTextureGeneration : MonoBehaviour
{
    public Material material = null;
    private Texture2D m_generatedTexture = null;

    #region Material properties
    //[SerializeField, SetProperty("textureWidth")]
    [SerializeField]
    private int m_textureWidth = 512;
    public int textureWidth
    {
        get 
        { 
            return m_textureWidth; 
        }
        set 
        {
            m_textureWidth = value;
            _UpdateMaterial(); 
        }
    }

    //[SerializeField, SetProperty("backgroundColor")]
    [SerializeField]
    private Color m_backgroundColor = Color.white;
    public Color backgroundColor
    {
        get
        {
            return m_backgroundColor;
        }
        set
        {
            m_backgroundColor = value;
            _UpdateMaterial();
        }
    }

    //[SerializeField, SetProperty("circleColor")]
    [SerializeField]
    private Color m_circleColor = Color.white;
    public Color circleColor
    {
        get
        {
            return m_circleColor;
        }
        set
        {
            m_circleColor = value;
            _UpdateMaterial();
        }
    }

    //[SerializeField, SetProperty("blurFactor")]
    [SerializeField]
    private float m_blurFactor = 2.0f;
    public float blurFactor
    {
        get
        {
            return m_blurFactor;
        }
        set
        {
            m_blurFactor = value;
            _UpdateMaterial();
        }
    }
    #endregion

    private void Start()
    {
        if (material == null)
        {
            Renderer renderer = gameObject.GetComponent<Renderer>();
            if (renderer == null) 
            {
                Debug.LogWarning("Cannot find a renderer.");
                return;
            }
            material = renderer.sharedMaterial;
        }
        _UpdateMaterial();
    }

    public void _UpdateMaterial()
    {
        if (material != null)
        {
            m_generatedTexture = _GenerateProceduralTexture();
            material.SetTexture("_MainTex", m_generatedTexture);
        }
    }

    private Texture2D _GenerateProceduralTexture()
    {
        Texture2D proceduralTexture = new Texture2D(textureWidth, textureWidth);

        // ����Բ��Բ֮��ļ��
        float circleInterval = textureWidth / 4.0f;
        // ����Բ�İ뾶
        float radius = textureWidth / 10.0f;
        // ����ģ��ϵ��
        float edgeBlur = 1.0f / blurFactor;

        for (int w = 0; w < textureWidth; w++)
        {
            for (int h = 0; h < textureWidth; h++)
            {
                // ʹ�ñ�����ɫ���г�ʼ��
                Color pixel = backgroundColor;

                // ���λ�9��Բ
                for (int i = 0; i < 3; i++)
                {
                    for (int j = 0; j < 3; j++)
                    {
                        // ���㵱ǰ�����Ƶ�Բ��Բ��λ��
                        Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));
                        // ���㵱ǰ������Բ�ĵľ���
                        float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;
                        // ģ��Բ�ı߽�
                        Color color = _MixColor
                            (circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f),
                            Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));
                        // ��֮ǰ�õ�����ɫ���л��
                        pixel = _MixColor(pixel, color, color.a);

                    }
                }
            proceduralTexture.SetPixel(w, h, pixel);
            }
        }
        // ǿ�ư�����ֵд������
        proceduralTexture.Apply();

        return proceduralTexture;
    }

    private Color _MixColor(Color color0, Color color1, float mixFactor)
    {
        Color mixColor = Color.white;
        mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
        mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
        mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
        mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
        return mixColor;
    }

}
