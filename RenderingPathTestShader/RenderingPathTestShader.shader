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

// ����������Ⱦ·�� 5.x�о��Ѳ���ʹ��
//      ��Ӳ��Ҫ�����,�������,Ч����������
//          һ����һ��pass�оͿ������
//      

// �ӳ���Ⱦ·�� һ�ָ�Ϊ���ϵ���Ⱦ����
//      ����ǰ����Ⱦ�������ƿ������,�ӳ���Ⱦ�������������� 
//          �ӳ���Ⱦ��������ɫ���塢��Ȼ��� �Լ�G���� �洢�˹��ĵı���������Ϣ(���ߡ�λ�á��������Ե�)
//
// �ӳ���Ⱦԭ��
//      ����pass 
//          ��һ�������й��ռ��� ������ɼ�ƬԪ ����G-buffer
//          �ڶ�������G-buffer�ĸ���ƬԪ��Ϣ���й��ռ���
// Pass 1 {
//     // �����������Ĺ��ռ���
//     // �ѹ��ռ�����Ϣ�洢��G-buffer��
//     for (each primitive in this model) {
//         for (each fragment covered by this primitive) {
//             if (failed in depth test){
//                 // δͨ����Ȳ��� ˵��ƬԪ���ɼ�
//                 discard;
//             } else {
//                 // ����ƬԪ�ɼ�
//                 // ����Ҫ����Ϣ����G-buffer
//                 writeGBuffer(materialInfo, pos, normal);
//             }
//         }
//     }
// }
   
// Pass 2 {
//     // ����G-buffer�����Ϣ�����������ռ���
//     for (each pixel in the screen) {
//         if (the pixel is valid) {
//             // ����������Ч
//             // ��ȡG-buffer��Ϣ
//             readBuffer(pixel, materialInfo, pos, normal);
   
//             // ���ݶ�������Ϣ���й��ռ���
//             float4 color = Shading(materialInfo, pos, normal, lightDir, viewDir);
//             // ����֡����
//             writeFrameBufer(pixel, color);  
//         }
//     }
// }
//
// Unity�е��ӳ���Ⱦ
//      Unity�������ӳ���Ⱦ һ���������� һ����5.x�е�  ��������ʹ���˴���ʵʱ���� ����ѡ���ӳ���Ⱦ·�� ������Ҫһ��Ӳ��֧��
//  �ӳ���Ⱦ��ÿ����Դ�����԰��������ش���
//      ȱ��:��֧�������Ŀ���ݹ���
//           ���ܴ����͸������
//            ���Կ���һ��Ҫ��(����֧��MRT��Shader Mode 3.0 �����ϡ������Ⱦ�����Լ�˫���ģ�建��)
//
//      �ӳ���Ⱦ�ɷ��ʵ����ñ����ͺ���
//          _LightColor0    float4      ��Դ��ɫ
//          _LightMatrix0   float4x4    ������ռ䵽��Դ�ռ�ı任����,���ڲ���cookie�͹�ǿ˥������
//

// ƽ�й�
//      ֻ�з��� û��λ�� û��˥������(��ǿ�������ž���ı�)

// ���Դ
//      �ɿռ���һ�����嶨�� ǿ��˥��ֵ������һ����������

// �۹��
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
