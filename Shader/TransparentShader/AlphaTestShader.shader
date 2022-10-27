// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// ʵ��͸�������ַ���:
//
//      1.͸���Ȳ���(Alpha Test)       ���������İ�͸��!
//          ĳƬԪ͸����С��ĳ����ֵƬԪ�ͻᱻ���� �ʿ��Բ��ر����д�� Ч��:Ҫô��ȫ͸�� Ҫô��ȫ��͸��
// 
//      2.͸���Ȼ��(Alpha Blending)   ����ʵ�������İ�͸��!
//          ��Ҫ�ر����д��(ZWrite) ��û�йر���Ȳ��� ��ʱ��Ȼ�����ֻ����
//
//      �ر����д��� ��Ⱦ˳������Ҫ ��������Ⱦ��Զ������ ����Ⱦ�Ͻ������� �������ִ���
//
//      ���������� ��Ⱦ����һ���������Ƚ�����������Ⱦ
//          1.����Ⱦ���в�͸������,���������ǵ���Ȳ��Ժ����д��
//          2.�Ѱ�͸���������Զ����������,Ȼ��Ӻ���ǰ��Ⱦ,��������Ȳ���,���ر����д��
//              �������ֵ�����ؼ���� ������ѭ���ص������Ҳ�����
//                  ����취:�ָ����� �������ٴ����������
//                          �������ָ�����,����������͸��ͨ���������,ʹ�ô��岻��ô����
// 
//      UnityΪ�˽����һ�����ṩ����Ⱦ����(render queue) 
//          ʹ��SubShader��Queue��ǩ����ģ�͹����ĸ���Ⱦ���� ������ԽС Խ�类��Ⱦ
//              Background->1000  Geometry->2000  AlphaTest->2450  Transparent->3000  Overlay->4000
//

Shader "Custom/AlphaTestShader"
{
    Properties
    {
        _Color ("Main Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5  // ͸����ֵ
     }

     SubShader
     {
        // ͸���Ȳ���
        Tags { 
                // ͨ��ʹ����͸���Ȳ��Ե�Shader��Ӧ��������������ǩ
                "Queue" = "AlphaTest"  
                "IgnoreProjector" = "True"              // ָ����shader�����ܵ�ͶӰ��(Projectors)��Ӱ��
                "RenderType" = "TransparentCutout"      // �����shader������ǰ�������(TransparentCutout)��,��ָ����shaderʹ��͸���Ȳ���
             }

        // ͸���Ȼ�� ��� ZWrite Off
        // Tags { "Queue" = "Transparent" }
        
        Pass
        {
            Tags { "LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;
            
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

                // Alpha Test
                clip(texColor.a - _Cutoff);
                //// Equal to
                //if ((texColor.a - _Cutoff) < 0.0)
                //{
                //    // ��͸����С����ֵ���޳�
                //    discard;
                //}

                fixed3 albedo = texColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                return fixed4(ambient + diffuse, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Transparent/Cutout/VertexLit"
}
