Shader "Custom/GaussianBlurShader"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurSize ("Blur Size", Float) = 1.0
    }

    // unity会把 CGINCLUDE 和 ENDCG 之间的代码插入到每一个pass中，已达到声明一遍，多次使用的目的
    CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        float _BlurSize;

        struct v2f 
        {
            float4 vertex : SV_POSITION;
            half2 uv[5] : TEXCOORD0;
        };

        v2f vertBlurVertical(appdata_img v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);

            half2 uv = v.texcoord;

            o.uv[0] = uv;
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
        
            return o;
        }

        v2f vertBlurHorizontal(appdata_img v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);

            half2 uv = v.texcoord;

            o.uv[0] = uv;
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.x * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.x * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.x * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.x * 2.0) * _BlurSize;
        
            return o;
        }

        // 两个pass共用的片元着色器
        fixed4 fragBlur(v2f i) : SV_TARGET
        {
            float weight[3] = {0.4026, 0.2442, 0.0545};

            fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

            for (int it = 1; it < 3; it++)
            {
                sum += tex2D(_MainTex, i.uv[it * 2 - 1]).rgb * weight[it];
                sum += tex2D(_MainTex, i.uv[2 * it]).rgb * weight[it];
            }

            return fixed4(sum, 1.0);
        }
    ENDCG
        
        SubShader
        {
            Tags { "RenderType"="Opaque" }

            Cull Off ZWrite Off ZTest Always
        
            Pass
            {
                // 高斯模糊是很多屏幕特效的基础
                // 定义名字可以再其他shader中直接通过名字使用该pass
                NAME "GAUSSIAN_BLUR_VERTICAL"

                CGPROGRAM
                #pragma vertex vertBlurVertical
                #pragma fragment fragBlur
                ENDCG
            }

            Pass
            {
                NAME "GAUSSIAN_BLUR_HORIZONTAL"

                CGPROGRAM
                #pragma vertex vertBlurHorizontal
                #pragma fragment fragBlur
                ENDCG
            }
        }
        FallBack Off
}
