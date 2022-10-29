// 使得具有顶点动画的模型能够正确渲染阴影
Shader "Custom/ShadowCasterShader"
{
    Properties
    {
        _Magnitude ("Distortion Magnitude", Float) = 1                  // 波动幅度
        _Frequency ("Distortion Frequency", Float) = 1                  // 波动频率
        _InvWaveLength ("Distortion Inverse Wave Length", Float) = 10   // 波长倒数
        _Speed ("Speed", Float) = 0.5
    }
    SubShader
    {
        Tags { 
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            // 批处理会合并所有相关模型 这些模型各自的模型空间就会丢失 这里需要在物体的模型空间下对顶点进行偏移 因此需要取消对该shader的批处理操作
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

                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)      // 这行报错 没有接受两个参数的UnityClipSpaceShadowCasterPos函数
                
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
