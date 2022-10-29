// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/BillboardShader"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _Color ("Color Tine", Color) = (1, 1, 1, 1)
        _VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1      // �����ǹ̶����߻��ǹ̶�ָ���Ϸ�
    }
    SubShader
    {
        Tags { 
            "Queue" = "Transparent"
            "IgnorProjector" = "True"
            "RenderType" = "Transparent"
            "DisableBatching" = "True"
        }

        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
        
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            fixed4 _Color;
            float _VerticalBillboarding;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float3 center = float3(0, 0, 0);
                float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));     

                // ���ݹ۲�λ�ú�ê�����Ŀ�귨�߷��� ������_VerticalBillboarding���ƴ�ֱ�����ϵ�Լ����
                float3 normalDir = viewer - center;
                // ��_VerticalBillboarding����1,��ζ�ŷ��߷���̶�Ϊ�ӽǷ���;��_VerticalBillboarding����0,��ζ�����Ϸ��̶�Ϊ(0,1,0)
                normalDir.y = normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);
                // �õ��������ϵķ���,Ϊ��ֹ���߷�������Ϸ���ƽ��,�Է��߷����y���������ж�,�Եõ����ʵ����Ϸ���
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                float3 rightDir = normalize(cross(upDir, normalDir));
                // ��ȡ׼ȷ���Ϸ�
                upDir = normalize(cross(normalDir, rightDir));
                // ���˻�ȡ������Ҫ��3��������ʸ��

                // ����ԭʼλ�������ê���ƫ�����Լ�3��������ʸ��,����õ��µĶ���λ��
                float3 centerOffs = v.vertex.xyz - center;
                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

                o.vertex = UnityObjectToClipPos(float4(localPos, 1));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = tex2D(_MainTex, i.uv);
                c.rgb *= _Color.rgb;
                return c;
            }
            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}
