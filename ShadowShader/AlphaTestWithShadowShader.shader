// ���ڴ������͸��������˵ ��FallBack����ΪVertexLit�Ϳ��Եõ���ȷ����Ӱ
//      ���Ƕ���͸��������˵,����ҪС�Ĵ�����Ӱ ��Ϊ���ǵ�ʵ��ͨ����ʹ��͸���Ȳ��Ի���͸���Ȼ��,��ҪС������FallBack
Shader "Custom/AlphaTestWithShadowShader"
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
            #include "AutoLight.cginc"

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
                SHADOW_COORDS(3)        // ��Ӱ�������꽫ռ�õ��ĸ���ֵ�Ĵ���TEXCOORD3
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                // ������������������
                TRANSFER_SHADOW(o);

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


                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4(ambient + diffuse * atten, 1.0);
            }
            ENDCG
        }
    }
    // ֻ�� VertexLit �Ļ� ��������οղ�����Ӱ
    FallBack "Transparent/Cutout/VertexLit"
}
