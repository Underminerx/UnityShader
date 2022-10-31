Shader "Custom/BloomShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Bloom ("Bloom (RGB)", 2D) = "black" {}
        _LuminanceThreshold ("Luminance Threshold", Float) = 0.5
        _BlurSize ("Blur Size", Float) = 1.0
    }
    
    CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminanceThreshold;
        float _BlurSize;

        // ������ȡ������Ҫʹ�õĶ�����ƬԪ��ɫ��
        struct v2f
        {
            float4 vertex : SV_POSITION;
            half2 uv : TEXCOORD0;
        };

        v2f vertExtractBright(appdata_img v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        fixed luminance(fixed4 color)
        {
            return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
        }

        fixed fragExtractBright(v2f i) : SV_Target
        {
            // �������ȼ�ȥ��ֵ �����ȡ��0-1 ��ֵ��ԭ����ֵ��˵õ���ȡ�����������
            fixed4 c = tex2D(_MainTex, i.uv);
            fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
            
            return c * val;
        }

        // ����������ͼ����ԭͼ��Ķ�����ƬԪ��ɫ��
        struct v2fBloom
        {
            float4 vertex : SV_POSITION;
            half4 uv : TEXCOORD0;       // xy������_MainTex zw������_Bloom
        };

        v2fBloom vertBloom(appdata_img v)
        {
            v2fBloom o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord;
            o.uv.zw = v.texcoord;

            // ƽ̨���컯����
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0.0)
               o.uv.w = 1.0 - o.uv.w;
            #endif

            return o;
        }

        fixed4 fragBloom(v2fBloom i) : SV_Target
        {
            // ��ϸ���ģ��ͼ��ԭͼ
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
        }
    ENDCG


    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }
        
        UsePass "Custom/GaussianBlurShader/GAUSSIAN_BLUR_VERTICAL"
        UsePass "Custom/GaussianBlurShader/GAUSSIAN_BLUR_HORIZONTAL"

        Pass
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
    FallBack Off

}
