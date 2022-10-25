// 对于大多数不透明物体来说 把FallBack设置为VertexLit就可以得到正确的阴影
//      但是对于透明物体来说,就需要小心处理阴影 因为他们的实现通常会使用透明度测试或者透明度混合,需要小心设置FallBack
Shader "Custom/AlphaTestWithShadowShader"
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
                SHADOW_COORDS(3)        // 阴影纹理坐标将占用第四个插值寄存器TEXCOORD3
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                // 计算声明的纹理坐标
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
                //    // 若透明度小于阈值则剔除
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
    // 只有 VertexLit 的话 不会计算镂空部分阴影
    FallBack "Transparent/Cutout/VertexLit"
}
