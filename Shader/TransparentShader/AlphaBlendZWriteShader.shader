// ˫pass��Ⱦ
// ��һ��pass: �������д�� ���������ɫ
//              Ϊ�˰Ѹ�ģ�͵����ֵд����Ȼ���
// �ڶ���pass: ����͸���Ȼ��
// 
// �˷���ȱ��: ��һ��pass����������
//              ģ���ڲ��������͸��Ч�� ֻ����ⲿ����͸��Ч��

// �����һ����ƬԪ���� ���ɱ�̵��߶ȿ����� ��������������� ������ӵȵ�

// ��ϵ�ʽ   Դ��ɫS + Ŀ����ɫD -> �����ɫO
//      ������ϵ�ʽ һ�����RGBͨ�� һ�����Aͨ��

// Blend SrcFactor DstFactor        // ǰ�߳���Դ��ɫ ���߳���Ŀ����ɫ
// Blend SrcFactor DstFactor, SrcFactorA DstFactorA

// �������
//      One Zero 
//      SrcColor SrcAlpha  ����ΪԴ��ɫֵ  ����ΪԴ��ɫ͸����ֵ
//      DstColor DstAlpha
//      OneMinusSrcColor OneMinusSrcAlpha OneMinusDstColor OneMinusDstAlpha

// Blend SrcFactor DstFactor, SrcFactorA DstFactorA     // �ڻ�Ϻ������ɫ��͸����ֵ����Դ��ɫ��͸����

// BlendOp BlendOperation ��ϲ�������
//      Add     // Ĭ�ϻ�ϲ���
//      Sub     // ��Ϻ�� Դ��ɫ   ��ȥ��Ϻ��  Ŀ����ɫ
//      RevSub  // ��Ϻ�� Ŀ����ɫ ��ȥ��Ϻ��  Դ��ɫ
//      Min     // ʹ��Դ��ɫ��Ŀ����ɫ�еĽ�Сֵ ������Ƚ�
//      Max     // ͬ��

// // ���� ��͸���Ȼ��
// Blend SrcAlpha OneMinusSrcAlpha          // �൱��Ĭ��ʡ�� BlendOp Add

// // ������ 
// Blend OneMinusSrcColor One

// // ��Ƭ���� �����
// Blend DstColor Zero

// // �������
// Blend DstColor SrcColor

// // �䰵
// BlendOp Min
// Blend One One            // Max �� Min����ʱ����Ի������ Ҳ������һ��û�� ���Ǳ���Ҫд

// // ����
// BlendOp Max
// Blend One One

// // ��ɫ
// Blend OneMinusSrcColor One
// // ͬ��
// Blend One OneMinusSrcColor

// // ���Լ���
// Blend One One

Shader "Custom/AlphaBlendZWriteShader"
{
    Properties
    {
        _Color ("Main Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _AlphaScale ("Alpha Scale", Range(0, 1)) = 1
     }

     SubShader
     {
        // ͸���Ȳ���
        Tags { 
                "Queue" = "Transparent"  
                "IgnoreProjector" = "True"        // ָ����shader�����ܵ�ͶӰ��(Projectors)��Ӱ��
                "RenderType" = "Transparent"      // �����shader������ǰ�������(Transparent)��,��ָ����shaderʹ��͸���Ȳ���
             }

        // ��pass������д����Ȼ���
        Pass
        {
            ZWrite On
            // ����������ɫͨ����д����(write mask)
            // ColorMask RGB | A | 0 | �����κ�R��G��B��A�����
            ColorMask 0         // ��pass��д���κ���ɫͨ��
        }

        Pass
        {
            Tags { "LightMode" = "ForwardBase"}

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex, i.uv);

                fixed3 albedo = texColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
