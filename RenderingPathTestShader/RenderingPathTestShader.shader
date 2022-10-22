// ��Ⱦ·�������������Ӧ�õ�shader����
// ��ҪΪÿ��Passָ����ʹ�õ���Ⱦ·��
// 
// ǰ����Ⱦ·��		(Forward Rendering Path)
// �ӳ���Ⱦ·��		(Defferred Rendering Path)
// ����������Ⱦ·��	(Vertex Lit Rendering Path)   �Ѿ�����ʹ��
// 
// һ��һ����Ŀֻʹ��һ����Ⱦ·��
// 
// ��������Ŀ����(ȫ��)���������(�ֲ�)��������Ⱦ·��
// Ȼ����Ҫ��ÿ��Pass��ʹ�ñ�ǩ��ָ����Pass��ʹ�õ���Ⱦ·��

// Always		����ʹ��������Ⱦ·��,��pass�ܻᱻ��Ⱦ,����������κι���
// ForwardBase	����ǰ����Ⱦ,����㻷���⡢����Ҫ��ƽ�й⡢�𶥵�/SH��Դ��Lightmaps
// ForwardAdd	����ǰ����Ⱦ,��������������ع�Դ,ÿ��pass��Ӧһ����Դ
// Deferred		�����ӳ���Ⱦ,����ȾG-����(G-buffer)
// ShadowCaster	�����������Ϣ��Ⱦ����Ӱӳ������(shadowmap)����һ�����������

// ����ʹ��
// PrepassBase	�����������ӳ���Ⱦ,����Ⱦ���ߺ͸߹ⷴ���ָ������
// PrepassFinal	�����������ӳ���Ⱦ,ͨ���ϲ��������պ��Է�������Ⱦ�õ�������ɫ

// ָ����Ⱦ·���������Ǻ�Unity�ײ���Ⱦ�����һ����Ҫ�Ĺ�ͨ
// Ȼ��Unity�ͻ�Ϊ�����ṩ���õĹ��ձ�����������Щ����


//// ǰ����Ⱦα����
//Pass
//{
//    for (each primitive in this model) {
//        for (each fragment covered by this primitive) {
//            if (failed in depth test)
//                // ��û��ͨ����Ȳ��� ��˵����ƬԪ���ɼ�
//                discard;
//            else {
//                // ����ƬԪ�ɼ� ����й��ռ���
//                float4 color = Shading(materialInfo, pos, normal, lightDir, viewDir);
//                // ����֡����
//                writeFrameBuffer(fragment, color);
//            }
//        }
//    }
//}

// N�������ܵ�M����Դ��Ӱ��,����Ⱦ����������ҪN*M��pass
// ����д��������ع���,��Ҫִ�е�pass��Ŀ��ܴ�,�����Ⱦ����ͨ��������ÿ������������ع��յ���Ŀ


// ǰ����Ⱦ��Unity�������ִ�����յķ�ʽ:
//      �𶥵㴦�������ش�����г����(Spherical Harmonics, SH)����

// ����һ����Դʹ�����ִ���ģʽȡ�����������ͺ���Ⱦģʽ ������ָ��Դ��ƽ�й⻹���������͹�Դ ��Ⱦģʽָ�����Դ�Ƿ�����Ҫ��(Important ���������ع�Դ����)
//      ǰ����Ⱦ��,��Ⱦһ������ʱ,Unity����ݹ�Դ���ü���Դ�������Ӱ��̶�(Զ��,��Դǿ�ȵ�)��������Ҫ�̶�����
//          ����,һ����Ŀ��Դ�ᰴ�������ش��� ���4����Դ�����𶥵㴦�� ʣ��İ�SH��ʽ����
//              Unity�жϹ���:
//                  ������ƽ�йⰴ�������ش���
//                  Not Important�����𶥵����SH����
//                  Important���������ش���
//                  ������������õ��������ع�Դ����С��Quality Setting�������ع�Դ����, ��������������������ش���
//                  
// ͨ��һ��ǰ����ȾShader�лᶨ��һ��Base Pass(Ҳ���Զ����� ��˫����Ⱦ)�Լ�һ��Additional Pass
//      ���Base Pass����ִ��һ��,��Additional Pass�����Ӱ�����������������ع�Դ����Ŀ����ε���,ÿ�������ع�Դ��ִ��һ��Additional Pass

// ǰ����Ⱦ�еĹ��ձ���
// _LightColor0                float4       ��pass����������ع�Դ����ɫ
// _WorldSpaceLightPos0        float4       .xyz�Ǹ�pass�������ع�Դ��λ�� ����ƽ�й� ����wֵΪ0 ������Դ����wֵΪ1
// _LightMatrix0               float4x4     ������ռ䵽��Դ�ռ�ı仯���� �����ڲ���cookie�͹�ǿ˥������
// unity_4LightPosX0, Y0, Z0   float4       ������Base Pass ��ǰ�ĸ�����Ҫ�ĵ��Դ������ռ��е�λ��
// unity_4LightAtten0          float4       ������Base Pass �洢��ǰ�ĸ�����Ҫ�ĵ��Դ��˥������
// unity_LightColor            half4[4]     ������Base Pass �洢��ǰ�ĸ�����Ҫ�ĵ��Դ����ɫ

// ǰ����Ⱦ�е����ù��պ���
// float3 WorldSpaceLightDir(float4 v)      ��ǰ����Ⱦ ���� ģ�� �ռ��ж���λ�� ��������ռ�Ӹõ㵽��Դ�Ĺ��շ��� δ��һ�� �ڲ�ʹ������һ������
// float3 UnityWorldSpaceLightDir(float4 v) ��ǰ����Ⱦ ���� ���� �ռ��ж���λ�� ��������ռ�Ӹõ㵽��Դ�Ĺ��շ��� δ��һ��
// float3 ObjSpaceLightDir(float4 v)        ��ǰ����Ⱦ ���� ģ�� �ռ��ж���λ�� ����ģ�Ϳռ�Ӹõ굽��Դ�Ĺ��շ��� δ��һ��
// float3 Shade4PointLights(...)            ��ǰ����Ⱦ �����ĸ����Դ�Ĺ��� �����Ǵ����ʸ���Ĺ������� ǰ����Ⱦͨ��ʹ��������𶥵����
//
Shader "Custom/RenderingPathTestShader"
{
    Properties
    {

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

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(1.0, 1.0, 1.0, 1.0);
            }
            ENDCG
        }
    }
}
