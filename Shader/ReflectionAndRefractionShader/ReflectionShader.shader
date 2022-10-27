// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
Shader "Custom/ReflectionShader"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _ReflectColor ("Reflection Color", Color) = (1, 1, 1, 1)
        _ReflectAmount ("Reflection Amount", Range(0, 1)) = 1      // ����̶�
        _Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {}    // ģ�ⷴ��Ļ���ӳ������
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
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed4 _ReflectColor;
            float _ReflectAmount;
            samplerCUBE _Cubemap;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

                // ���㷴�� (���巴�䵽������еĹ��߷�������ɹ�·����ԭ����������� -> �����ӽǷ�����ڶ��㷨�ߵ÷��䷽�������������߷���)
                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

                TRANSFER_SHADOW(o);

                return o;
            }

            // Ҳ����ѡ����ƬԪ��ɫ���м��㷴�䷽�� Ч������ϸ�� �����ֲ���������Ժ��Բ���
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

                // ʹ������ռ䷴�䷽�����cubemap
                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // �����������ɫ�뷴����ɫ
                fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount) * atten;
                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
