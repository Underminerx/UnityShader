// ��˹�������ɼ��㷴���
//      ��1sinx1 = ��2sinx2       
//          ��1 ��2���������ʵ�������
//              �����������1 ����һ����1.5
// ����һ��͸������,��׼ȷ������Ҫ������������
//      ��һ���ǹ��߽����ڲ�ʱ
//      �ڶ����ǹ��ߴ��ڲ����ʱ    ʵʱ��Ⱦʵ�ֵڶ��������ǱȽ����ѵ� ���һ��ֻʵ�ֵ�һ��
//

Shader "Custom/RefractionShader"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _RefractColor ("Refraction Color", Color) = (1, 1, 1, 1)
        _RefractAmount ("Refraction Amount", Range(0, 1)) = 1      // ����̶�
        _RefractRatio ("Refraction Ratio", Range(0.1, 1)) = 0.5
        _Cubemap ("Refraction Cubemap", Cube) = "_Skybox" {}    // ģ�ⷴ��Ļ���ӳ������
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
            fixed4 _RefractColor;
            float _RefractAmount;
            float _RefractRatio;
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
                float3 worldRefr : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

                // ��������ռ��µ����� (��һ��������߷���, ��һ�����淨��, ����������ڽ��������ʺ�����������ڽ��ʵ�������֮��ı�ֵ)
                o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

                // ʹ������ռ䷴�䷽�����cubemap
                fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // �����������ɫ�뷴����ɫ
                fixed3 color = ambient + lerp(diffuse, refraction, _RefractAmount) * atten;
                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
