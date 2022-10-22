// 使用双面渲染 使得透明物体可以看得到物体内部
// Cull Back | Front | Off
// Back     -> 默认状态 背面不渲染
// Front    -> 朝向摄像机的图元不会被渲染
// Off      -> 关闭剔除 所有渲染图元都会被渲染   渲染成本会成倍增加 除非特殊效果 否则不建议关闭
Shader "Custom/AlphaBlendBothSidedShader"
{
    Properties
    {
        _Color ("Main Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5  // 透明阈值
     }

     SubShader
     {
        // 透明度测试
        Tags { 
                // 通常使用了透明度测试的Shader都应该设置这三个标签
                "Queue" = "AlphaTest"  
                "IgnoreProjector" = "True"              // 指明该shader不会受到投影器(Projectors)的影响
                "RenderType" = "TransparentCutout"      // 把这个shader归入提前定义的组(TransparentCutout)中,以指明该shader使用透明度测试
             }

        // 透明度混合 外加 ZWrite Off
        // Tags { "Queue" = "Transparent" }
        
        Pass
        {
            Tags { "LightMode" = "ForwardBase"}
            
            // 关闭剔除
            Cull Off

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
                //    // 若透明度小于阈值则剔除
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
