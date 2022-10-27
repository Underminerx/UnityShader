// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// 使用GrabPass
//      Unity会把当前屏幕的图像绘制在一张纹理中 以便在后续的pass中访问它
//          通常使用GrabPass来实现诸如玻璃等透明材质的模拟 可以让我们对该物体后边的图像进行更复杂的处理 
//              例如使用法线来模拟折射效果 而不再是简单的和原屏幕颜色进行混合
//
//  使用GrabPass时需要额外小心物体的渲染队列设置
//      "Queue" = "Transparent"
//          保证当渲染该物体时,所有的不透明物体都已经被绘制到屏幕上

//  首先使用一张法线纹理来修改模型的法线信息 然后使用之前的反射方法,通过一个Cubemap来模拟玻璃的反射
//      模拟折射时则使用GrabPass获取玻璃后边的屏幕图像,并使用切线空间下的法线对屏幕纹理坐标偏移后,再对屏幕图像进行采样来模拟近似的折射效果
Shader "Custom/GlassRefractionShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
        _Distortion ("Distortion", Range(0, 100)) = 10
        _RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderType" = "Opaque"}

        // 抓取物体后的图像放入一张贴图
        // 可以在下一个pass中使用_RefractionTex访问此贴图
        GrabPass { "_RefractionTex" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"            

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _Cubemap;
            float _Distortion;
            fixed _RefractAmount;

            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;    // 获取该纹理纹素大小

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 srcPos : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;
                float4 TtoW1 : TEXCOORD3;
                float4 TtoW2 : TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.srcPos = ComputeGrabScreenPos(o.vertex);      // 得到对应被抓取的屏幕图像的采样坐标

                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                // 计算该顶点对应的从切线空间到世界空间的变换矩阵 存入xyz分量中 与NormalMapWorldSpaceShader中的方法相同
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;

            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));

                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                i.srcPos.xy = offset + i.srcPos.xy;
                // i.srcPos = offset * i.srcPos.z + i.srcPos.xy;        // 会让变形程度随着摄像机的远近发生变化
                fixed3 refrCol = tex2D(_RefractionTex, i.srcPos.xy/i.srcPos.w).rgb;

                // 把法线转换到世界空间下
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                fixed3 reflDir = reflect(-worldViewDir, bump);
                fixed4 texColor = tex2D(_MainTex, i.uv.xy);
                fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;

                fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;
                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}
