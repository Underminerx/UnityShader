// 高光反射(specular)   物体表面如何反射光线
// 漫反射(diffuse)     多少光线会被折射、吸收、散射

// 计算机图形学第一定律：如果它看起来是对的，那么它就是对的

// Phong -> 裴祥风 Bui Tuong Phong 越南籍美国人

// 自发光  (emissive)
// 高光反射 (specular)
// 漫反射  (diffuse)
// 环境光  (ambient)

// 漫反射光照符合兰伯特定律(Lambert's law) : 反射光线的强度与表面法线和光源方向之间夹角的余弦值成正比

// 高光反射模型   Phong模型   Blinn模型   -> Blinn-Phong光照模型 
// 如果摄像机和光源距离模型足够远 Blinn模型会快于Phong模型

// 两种光照模型计算:  
//      逐像素光照 -> 得到每个像素的法线      Phong shading 
//      逐顶点光照 -> 在每个顶点上计算光照    Gouraud shading  计算量小于Phong 但是依赖于线性插值 出现非线性计算则会出错(计算高光反射)

// Blinn-Phong模型局限性(各向同性)：
//      菲涅尔反射无法表现   (反射/折射与视点角度之间的关系)
//      各向异性无法表现    e.g.拉丝金属 毛发

Shader "Unlit/SecondLitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
