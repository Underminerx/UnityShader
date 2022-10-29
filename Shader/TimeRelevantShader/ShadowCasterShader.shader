// ʹ�þ��ж��㶯����ģ���ܹ���ȷ��Ⱦ��Ӱ
Shader "Custom/ShadowCasterShader"
{
    Properties
    {
        _Magnitude ("Distortion Magnitude", Float) = 1                  // ��������
        _Frequency ("Distortion Frequency", Float) = 1                  // ����Ƶ��
        _InvWaveLength ("Distortion Inverse Wave Length", Float) = 10   // ��������
        _Speed ("Speed", Float) = 0.5
    }
    SubShader
    {
        Tags { 
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            // �������ϲ��������ģ�� ��Щģ�͸��Ե�ģ�Ϳռ�ͻᶪʧ ������Ҫ�������ģ�Ϳռ��¶Զ������ƫ�� �����Ҫȡ���Ը�shader�����������
            "DisableBatching" = "True"          
        }

        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"            
            // #include "Lighting.cginc"
            // #include "AutoLight.cginc"

            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
            float _Speed;

            struct appdata
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float4 offset;
                offset.yzw = float3(0.0, 0.0, 0.0);
                offset.x = sin(
                            _Frequency * _Time.y 
                            + v.vertex.x * _InvWaveLength 
                            + v.vertex.y * _InvWaveLength 
                            + v.vertex.z * _InvWaveLength
                            ) * _Magnitude;

                v.vertex = v.vertex + offset;

                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)      // ���б��� û�н�������������UnityClipSpaceShadowCasterPos����
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    FallBack "VertexLit"
}
