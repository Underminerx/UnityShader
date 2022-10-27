// 模型空间下法线纹理[-1,1]
// 切线空间下法线纹理[0,1]
// 公式(n+1)/2 一般法线方向都是模型本身顶点方向(0, 0, 1) 转换后为(0.5, 0.5, 1)
// 故大多数看起来是蓝色的
// 
// 模型空间下法线纹理记录的是绝对法线信息 仅可用于创建它时那个模型 但应用到其他模型上就完全错误了
// 切线纹理优势:
// 1.切线空间下法线纹理记录的是相对法线信息 (相对于原顶点的方向偏移)
// 2.可进行UV动画
// 3.可重用法线纹理
// 4.可压缩 (用相对信息记录的话大部分z值都是1 而绝对信息记录的话则不一定)

// 使用切线空间下的纹理有两种选择:
// 1.在切线空间下进行光照计算 此时需要把光照方向、视角方向变换到切线空间下
// 2.在世界空间下进行光照计算 此时需要把采样得到的法线变换到世界空间下
// 效率上说 第一种更优秀 因为可以在顶点着色器中就完成对光照方向与视角方向的变换
//         第二种方法需要先对法线纹理进行采样 所以变换必须在片元着色器中实现
// 通用性上说 第二种更好 

// 视觉表现上没什么区别 但是第二种使用了更多插值寄存器来存储变换矩阵 更容易报错

Shader "Custom/NormalMapTangentSpaceShader"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _BumpMap ("Normal", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1.0
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _MainTex_ST.xy + _BumpMap_ST.zw;

                // // 原始代码计算  构造一个矩阵(模型空间转切线空间)
                // float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w; // w决定了选择叉乘后垂直向量中的哪一个
                // float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

                // Unity内置函数(模型空间转切线空间)
                TANGENT_SPACE_ROTATION;  // 可以直接得到rotation

                // 转灯光及视角到切线空间
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                return o;
            }

            // 直接在切线空间下计算光照
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                fixed3 tangentNormal;

                // // 如果贴图类型没有设置为"法线贴图" (手动套公式 将[-1,0]范围内的模型空间贴图转换为[0,1]范围内的切线空间贴图)
                // tangentNormal.xy = (packedNormal.xy * 2 -1) * _BumpScale;
                // tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                
                // 如果设置了"法线贴图"类型 则需要对法线贴图的采样进行"解包"
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
