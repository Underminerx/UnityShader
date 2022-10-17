// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// POSITION ����λ��  ͨ����float4
// NORMAL   ���㷨��  ͨ����float3
// TANGENT  ��������  ͨ����float4
// TEXCOORD ��������  ͨ����float2 float4
// COLOR    ������ɫ  ͨ����float4 fixed4


// ���ʹ��fixed ���ƶ�ƽ̨�ϲ��ܴ�
// ����(�ߵ���):  float(32bit) 
//                            -> half(16bit)(-60000, +60000) 
//                                              -> fixed(11bit)(-2.0, +2.0)

// ������Ҫ��shader��ʹ�����̿������ shader�������ܿ�������½�
// ��Ҫ�õ�ʱ��:
//      ����ʹ�ó�����������
//      ÿ����֧����������
//      ��֧Ƕ�ײ���������

Shader "Unlit/FirstShader"
{
    Properties
    {
        // ����һ��Color��������
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

            // ��������������
            fixed4 _Color;

            // application to vertex
            struct a2v {
                float4 vertex : POSITION;       // ģ�Ͷ���λ�����vertex
                float3 normal : NORMAL;         // ģ�ͷ��߷������normal
                float4 texcoord : TEXCOORD0;    // ��һ���������texcoord
            };

            // vertex to fragment
            struct v2f {
                float4 pos : SV_POSITION;       // �洢�ڲü��ռ��λ����Ϣ
                fixed3 color : COLOR;           // �洢��ɫ��Ϣ
            };

            v2f vert(a2v v)
            {
                v2f o;      // ��������ṹ
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);   // ����ɫ���в�ֵ
                return o;
            }

            fixed4 frag (v2f i) : SV_Target     // ���ֵ��洢����ȾĿ����
            {
                fixed3 c = i.color;
                c *= _Color.rgb;
                return fixed4(c, 1.0);    // ��ʾ��ֵ���i.color
            }
            ENDCG
        }
    }
}
