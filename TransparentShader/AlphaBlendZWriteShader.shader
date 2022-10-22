// 双pass渲染
// 第一个pass: 开启深度写入 但不输出颜色
//              为了把该模型的深度值写入深度缓冲
// 第二个pass: 正常透明度混合
// 
// 此方法缺点: 多一个pass更消耗性能
//              模型内部不会产生透明效果 只会和外部产生透明效果

// 混合是一个逐片元操作 不可编程但高度可配置 可以设置运算操作 混合因子等等

// 混合等式   源颜色S + 目标颜色D -> 输出颜色O
//      两个混合等式 一个混合RGB通道 一个混合A通道

// Blend SrcFactor DstFactor        // 前者乘以源颜色 后者乘以目标颜色
// Blend SrcFactor DstFactor, SrcFactorA DstFactorA

// 混合因子
//      One Zero 
//      SrcColor SrcAlpha  因子为源颜色值  因子为源颜色透明度值
//      DstColor DstAlpha
//      OneMinusSrcColor OneMinusSrcAlpha OneMinusDstColor OneMinusDstAlpha

// Blend SrcFactor DstFactor, SrcFactorA DstFactorA     // 在混合后输出颜色的透明度值就是源颜色的透明度

// BlendOp BlendOperation 混合操作命令
//      Add     // 默认混合操作
//      Sub     // 混合后的 源颜色   减去混合后的  目标颜色
//      RevSub  // 混合后的 目标颜色 减去混合后的  源颜色
//      Min     // 使用源颜色和目标颜色中的较小值 逐分量比较
//      Max     // 同上

// // 正常 即透明度混合
// Blend SrcAlpha OneMinusSrcAlpha          // 相当于默认省略 BlendOp Add

// // 柔和相加 
// Blend OneMinusSrcColor One

// // 正片叠底 即相乘
// Blend DstColor Zero

// // 两倍相乘
// Blend DstColor SrcColor

// // 变暗
// BlendOp Min
// Blend One One            // Max 与 Min操作时会忽略混合因子 也就是这一行没用 但是必须要写

// // 变亮
// BlendOp Max
// Blend One One

// // 滤色
// Blend OneMinusSrcColor One
// // 同上
// Blend One OneMinusSrcColor

// // 线性减淡
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
        // 透明度测试
        Tags { 
                "Queue" = "Transparent"  
                "IgnoreProjector" = "True"        // 指明该shader不会受到投影器(Projectors)的影响
                "RenderType" = "Transparent"      // 把这个shader归入提前定义的组(Transparent)中,以指明该shader使用透明度测试
             }

        // 此pass仅用于写入深度缓冲
        Pass
        {
            ZWrite On
            // 用于设置颜色通道的写掩码(write mask)
            // ColorMask RGB | A | 0 | 其他任何R、G、B、A的组合
            ColorMask 0         // 该pass不写入任何颜色通道
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
