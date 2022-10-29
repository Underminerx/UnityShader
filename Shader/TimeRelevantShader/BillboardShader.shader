// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/BillboardShader"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _Color ("Color Tine", Color) = (1, 1, 1, 1)
        _VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1      // 调整是固定法线还是固定指向上方
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

                // 根据观察位置和锚点计算目标法线方向 并根据_VerticalBillboarding控制垂直方向上的约束度
                float3 normalDir = viewer - center;
                // 若_VerticalBillboarding等于1,意味着法线方向固定为视角方向;若_VerticalBillboarding等于0,意味着向上方固定为(0,1,0)
                normalDir.y = normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);
                // 得到粗略向上的方向,为防止法线方向和向上方向平行,对法线方向的y分量进行判断,以得到合适的向上方向
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                float3 rightDir = normalize(cross(upDir, normalDir));
                // 获取准确的上方
                upDir = normalize(cross(normalDir, rightDir));
                // 至此获取了所需要的3个正交基矢量

                // 根据原始位置相对于锚点的偏移量以及3个正交基矢量,计算得到新的顶点位置
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
