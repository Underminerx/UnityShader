// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// 菲涅尔反射模型
//      光线照射到物体表面时,一部分发生反射,一部分进入物体内部,发生折射或散射
//          被反射的光和入射光存在一定比率关系,可以通过菲涅尔等式进行计算
//              (现象:湖边看脚下水面,睡眠几乎透明;看远处水面,看不见水下情况,只能看到水面反射环境)

// 菲涅尔等式:
//      F(v,n)= F0+(1-F0)(1-v·n)^5
//          F0为反射系数,控制菲涅尔反射强度 v是视角方向 n是表面法线
// 菲涅尔近似等式:
//      F(v,n)=max(0,min(i,bias+scale×(1-v·n)^power))
//          bisa、scale、power是控制项
//              菲涅尔近似等式使我们可以在边界处模拟反射光强和折射光强/漫反射光强之间的变换 许多车漆、水面等材质的渲染中,常使用菲涅尔反射来模拟
Shader "Custom/FresnelShader"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _FresnelScale ("Fresnel Scale", Range(0, 1)) = 0.5
        _Cubemap ("Reflection Cubemap", Cube) = "_Sktbox" {}
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
            #include "AutoLight.cginc"

            fixed4 _Color;
            float _FresnelScale;
            samplerCUBE _Cubemap;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = mul(v.normal, (float3x3) unity_WorldToObject);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);
                TRANSFER_SHADOW(o);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb;
                
                fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal), 5);

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

                fixed3 color = ambient + lerp(diffuse, reflection, saturate(fresnel)) * atten;

                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
