// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// 逐顶点高光反射shader
// 高光部分明显不平滑 顶点着色器计算光照再插值过程是线性的 破坏了原计算的非线性关系 会出现较大的视觉问题 因此需要使用逐像素计算高光反射
Shader "Unlit/SpecularVertexShader"
{
    Properties
    {
        _Diffuse ("漫反射颜色", Color) = (1, 1, 1, 1)
        _Specular ("高光反射颜色", Color) = (1, 1, 1, 1)
        _Gloss ("高光区域", Range(8.0, 256)) = 20
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

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 计算漫反射部分
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 diffuse =  _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
                
                // 计算高光反射部分
                // 获取世界空间反射方向(reflect函数入射方向要求从光源指向交点处,故取反)
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
                // 获取世界空间视角方向
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
                // 套公式
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

                o.color = ambient + diffuse + specular;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
