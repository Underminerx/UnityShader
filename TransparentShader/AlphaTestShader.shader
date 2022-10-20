// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// 实现透明的两种方法:
//
//      1.透明度测试(Alpha Test)       不是真正的半透明!
//          某片元透明度小于某个阈值片元就会被丢弃 故可以不关闭深度写入 效果:要么完全透明 要么完全不透明
// 
//      2.透明度混合(Alpha Blending)   可以实现真正的半透明!
//          需要关闭深度写入(ZWrite) 但没有关闭深度测试 此时深度缓冲是只读的
//
//      关闭深度写入后 渲染顺序极其重要 必须先渲染较远的物体 再渲染较近的物体 否则会出现错误
//
//      基于这两点 渲染引擎一般会对物体先进行排序再渲染
//          1.先渲染所有不透明物体,并开启他们的深度测试和深度写入
//          2.把半透明物体根据远近进行排序,然后从后往前渲染,并开启深度测试,但关闭深度写入
//              但是深度值是像素级别的 若出现循环重叠情况则也会出错
//                  解决办法:分割网格 尽量减少错误排序情况
//                          如果不想分割网格,可以试着让透明通道更加柔和,使得穿插不怎么明显
// 
//      Unity为了解决这一问题提供了渲染队列(render queue) 
//          使用SubShader的Queue标签决定模型归于哪个渲染队列 索引号越小 越早被渲染
//              Background->1000  Geometry->2000  AlphaTest->2450  Transparent->3000  Overlay->4000
//

Shader "Custom/AlphaTestShader"
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
