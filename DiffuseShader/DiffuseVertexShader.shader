// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// �𶥵�������shader
Shader "Custom/DiffuseVertexShader"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "LightMode" = "ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
    
            fixed4 _Diffuse;

            struct a2v 
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
            };


            // ������������Ҫ�ĸ�������
            //      ��������ɫ ���㷨�� ��Դ��ɫ��ǿ�� ��Դ����
            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // �����ߴ�ģ�Ϳռ�ת��������ռ�
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));     // ֻ���ȡǰ����ǰ����
                // ��ȡ����ռ���շ���
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);    // ǰ���ǳ�����ֻ��һ��ƽ�й�Դ
                // ����������
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                o.color = ambient + diffuse;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
