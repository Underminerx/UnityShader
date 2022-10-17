// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// ������������shader
Shader "Unlit/DiffusePixelShader"
{
    Properties
    {
        _Diffuse ("��������ɫ", Color) = (1, 1, 1, 1)
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
                fixed3 worldNormal : TEXCOORD0;
            };



            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // �����ߴ�ģ�Ϳռ�ת����ռ�
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

                return o;
            }

            // ������������Ҫ�ĸ�������
            //      ��������ɫ ���㷨�� ��Դ��ɫ��ǿ�� ��Դ����
            // ��ƬԪ��ɫ���������������ģ��
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                fixed3 color = ambient + diffuse;
                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
