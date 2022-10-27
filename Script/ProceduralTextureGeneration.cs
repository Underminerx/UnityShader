using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

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

        // 定义圆与圆之间的间距
        float circleInterval = textureWidth / 4.0f;
        // 定义圆的半径
        float radius = textureWidth / 10.0f;
        // 定义模糊系数
        float edgeBlur = 1.0f / blurFactor;

        for (int w = 0; w < textureWidth; w++)
        {
            for (int h = 0; h < textureWidth; h++)
            {
                // 使用背景颜色进行初始化
                Color pixel = backgroundColor;

                // 依次画9个圆
                for (int i = 0; i < 3; i++)
                {
                    for (int j = 0; j < 3; j++)
                    {
                        // 计算当前所绘制的圆的圆心位置
                        Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));
                        // 计算当前像素与圆心的距离
                        float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;
                        // 模糊圆的边界
                        Color color = _MixColor
                            (circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f),
                            Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));
                        // 与之前得到的颜色进行混合
                        pixel = _MixColor(pixel, color, color.a);

                    }
                }
            proceduralTexture.SetPixel(w, h, pixel);
            }
        }
        // 强制把像素值写入纹理
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
