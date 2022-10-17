// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//// ��������ϵ�µĲ�ͬ����
//#if UNITY_UV_STARTS_AT_TOP
//if (_MainTex_TexelSize.y < 0)
//    uv.y = 1 - uv.y;
//#endif

Shader "Unlit/DebugShader"
{
    Properties
    {
        
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR0;
            };


            v2f vert (appdata_full v)
            {



                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //// ���ӻ����߷���
                //o.color = fixed4(v.normal * 0.5 + fixed3(0.5, 0.5, 0.5), 1.0);

                //// ���ӻ����߷���
                //o.color = fixed4(v.tangent.xyz * 0.5 + fixed3(0.5, 0.5, 0.5), 1.0);

                //// ���ӻ������߷���
                //fixed3 binormal = cross(v.normal, v.tangent.xyz) * v.tangent.w;
                //o.color = fixed4(binormal * 0.5 + fixed3(0.5, 0.5, 0.5), 1.0);

                //// ���ӻ���һ����������
                //o.color = fixed4(v.texcoord.xy, 0.0, 1.0);

                // ���ӻ��ڶ����������� 
                o.color = fixed4(v.texcoord1.xy, 0.0, 1.0);
                
                //// ���ӻ���һ�����������С������
                //o.color = frac(v.texcoord);
                //if (any(saturate(v.texcoord) - v.texcoord))
                //{
                //    o.color.b = 0.5;
                //}
                //o.color.a = 1.0;
                
                //// ���ӻ��ڶ������������С������
                //o.color = frac(v.texcoord1);
                //if (any(saturate(v.texcoord1) - v.texcoord1))
                //{
                //    o.color.b = 0.5;
                //}
                //o.color.a = 1.0;

                //// ���ӻ�������ɫ
                //o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }
    }
}
