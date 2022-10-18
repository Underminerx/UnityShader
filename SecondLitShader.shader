// �߹ⷴ��(specular)   ���������η������
// ������(diffuse)     ���ٹ��߻ᱻ���䡢���ա�ɢ��

// �����ͼ��ѧ��һ���ɣ�������������ǶԵģ���ô�����ǶԵ�

// Phong -> ����� Bui Tuong Phong Խ�ϼ�������

// �Է���  (emissive)
// �߹ⷴ�� (specular)
// ������  (diffuse)
// ������  (ambient)

// ��������շ��������ض���(Lambert's law) : ������ߵ�ǿ������淨�ߺ͹�Դ����֮��нǵ�����ֵ������

// �߹ⷴ��ģ��   Phongģ��   Blinnģ��   -> Blinn-Phong����ģ�� 
// ���������͹�Դ����ģ���㹻Զ Blinnģ�ͻ����Phongģ��

// ���ֹ���ģ�ͼ���:  
//      �����ع��� -> �õ�ÿ�����صķ���      Phong shading 
//      �𶥵���� -> ��ÿ�������ϼ������    Gouraud shading  ������С��Phong �������������Բ�ֵ ���ַ����Լ���������(����߹ⷴ��)

// Blinn-Phongģ�;�����(����ͬ��)��
//      �����������޷�����   (����/�������ӵ�Ƕ�֮��Ĺ�ϵ)
//      ���������޷�����    e.g.��˿���� ë��

Shader "Unlit/SecondLitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
