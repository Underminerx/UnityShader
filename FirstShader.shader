// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// POSITION 顶点位置  通常是float4
// NORMAL   顶点法线  通常是float3
// TANGENT  顶点切线  通常是float4
// TEXCOORD 纹理坐标  通常是float2 float4
// COLOR    顶点颜色  通常是float4 fixed4


// 最好使用fixed 在移动平台上差别很大
// 精度(高到低):  float(32bit) 
//                            -> half(16bit)(-60000, +60000) 
//                                              -> fixed(11bit)(-2.0, +2.0)

// 尽量不要在shader中使用流程控制语句 shader并行性能可能因此下降
// 非要用的时候:
//      尽量使用常数条件变量
//      每个分支操作尽量少
//      分支嵌套层数尽量少

Shader "Unlit/FirstShader"
{
    Properties
    {
        // 声明一个Color类型属性
        _Color ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            
            // Shader Model 2.0 3.0 4.0 5.0
            #pragma fragment frag   

            #pragma target 3.0

            #include "UnityCG.cginc"

            // 代码中声明变量
            fixed4 _Color;

            // application to vertex
            struct a2v {
                float4 vertex : POSITION;       // 模型顶点位置填充vertex
                float3 normal : NORMAL;         // 模型法线方向填充normal
                float4 texcoord : TEXCOORD0;    // 第一套纹理填充texcoord
            };

            // vertex to fragment
            struct v2f {
                float4 pos : SV_POSITION;       // 存储在裁剪空间的位置信息
                fixed3 color : COLOR;           // 存储颜色信息
            };

            v2f vert(a2v v)
            {
                v2f o;      // 声明输出结构
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);   // 对颜色进行插值
                return o;
            }

            fixed4 frag (v2f i) : SV_Target     // 输出值会存储到渲染目标中
            {
                fixed3 c = i.color;
                c *= _Color.rgb;
                return fixed4(c, 1.0);    // 显示插值后的i.color
            }
            ENDCG
        }
    }
}
