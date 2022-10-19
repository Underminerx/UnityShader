// ģ�Ϳռ��·�������[-1,1]
// ���߿ռ��·�������[0,1]
// ��ʽ(n+1)/2 һ�㷨�߷�����ģ�ͱ����㷽��(0, 0, 1) ת����Ϊ(0.5, 0.5, 1)
// �ʴ��������������ɫ��
// 
// ģ�Ϳռ��·��������¼���Ǿ��Է�����Ϣ �������ڴ�����ʱ�Ǹ�ģ�� ��Ӧ�õ�����ģ���Ͼ���ȫ������
// ������������:
// 1.���߿ռ��·��������¼������Է�����Ϣ (�����ԭ����ķ���ƫ��)
// 2.�ɽ���UV����
// 3.�����÷�������
// 4.��ѹ�� (�������Ϣ��¼�Ļ��󲿷�zֵ����1 ��������Ϣ��¼�Ļ���һ��)

// ʹ�����߿ռ��µ�����������ѡ��:
// 1.�����߿ռ��½��й��ռ��� ��ʱ��Ҫ�ѹ��շ����ӽǷ���任�����߿ռ���
// 2.������ռ��½��й��ռ��� ��ʱ��Ҫ�Ѳ����õ��ķ��߱任������ռ���
// Ч����˵ ��һ�ָ����� ��Ϊ�����ڶ�����ɫ���о���ɶԹ��շ������ӽǷ���ı任
//         �ڶ��ַ�����Ҫ�ȶԷ���������в��� ���Ա任������ƬԪ��ɫ����ʵ��
// ͨ������˵ �ڶ��ָ��� 

// �Ӿ�������ûʲô���� ���ǵڶ���ʹ���˸����ֵ�Ĵ������洢�任���� �����ױ���

Shader "Custom/NormalMapTangentSpaceShader"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _BumpMap ("Normal", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1.0
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
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

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _MainTex_ST.xy + _BumpMap_ST.zw;

                // // ԭʼ�������  ����һ������(ģ�Ϳռ�ת���߿ռ�)
                // float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w; // w������ѡ���˺�ֱ�����е���һ��
                // float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

                // Unity���ú���(ģ�Ϳռ�ת���߿ռ�)
                TANGENT_SPACE_ROTATION;  // ����ֱ�ӵõ�rotation

                // ת�ƹ⼰�ӽǵ����߿ռ�
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                return o;
            }

            // ֱ�������߿ռ��¼������
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                fixed3 tangentNormal;

                // // �����ͼ����û������Ϊ"������ͼ" (�ֶ��׹�ʽ ��[-1,0]��Χ�ڵ�ģ�Ϳռ���ͼת��Ϊ[0,1]��Χ�ڵ����߿ռ���ͼ)
                // tangentNormal.xy = (packedNormal.xy * 2 -1) * _BumpScale;
                // tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                
                // ���������"������ͼ"���� ����Ҫ�Է�����ͼ�Ĳ�������"���"
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
