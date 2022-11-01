Shader "Custom/MotionBlurShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurAmount ("Blur Amount", Float) = 1.0
    }

    CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        fixed _BlurAmount;

        struct v2f
        {
            float4 vertex : SV_POSITION;
            half2 uv : TEXCOORD0;
        };

        v2f vert(appdata_img v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);

            o.uv = v.texcoord;

            return o;
        }

        // �ֿ�����RGB��A : ����RGBʱ��Ҫ��������Aͨ�������ͼ�� ���ֲ�ϣ��Aͨ����ֵд�뵽��Ⱦ����
        // ������Ⱦ����RGBͨ��
        fixed4 fragRGB(v2f i) : SV_Target
        {
            return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
        }

        // ������Ⱦ����Aͨ��
        half4 fragA(v2f i) : SV_Target
        {
            return tex2D(_MainTex, i.uv);
        }
    ENDCG

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRGB
            
            ENDCG
        }
        
        Pass
        {
            Blend One Zero
            ColorMask A

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment fragA

            ENDCG
        }
    }
    FallBack Off
}
