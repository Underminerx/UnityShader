// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
// 基于Blinn-Phong光照模型
Shader "Custom/ForwardRenderingShader"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            // 此pass用于计算环境光 方向光 若场景中有多个平行光 则会选择最亮的那个传递给Base Pass进行逐像素处理
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM

            // 确保在shader中使用光照衰减等光照变量可以被正确赋值
            #pragma multi_compile_fwdadd
            
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
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            // !!! Unity内置函数是没有归一化的 需要手动归一化
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 计算漫反射部分
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // fixed3 worldNormal = normalize(mul(i.worldNormal, (float3x3)unity_WorldToObject));
                // fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);


                fixed3 diffuse =  _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                
                // 计算高光反射部分
                // 获取世界空间反射方向(reflect函数入射方向要求从光源指向交点处,故取反)
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
                
                // 获取世界空间视角方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

                // 在世界空间获取 half direction
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // 套公式
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
 
                // 衰减值置为1
                fixed atten = 1.0;

                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }
            ENDCG
        }

        Pass 
        {
            // 为其他逐像素光源定义Additional Pass
            Tags { "LightMode" = "ForwardAdd" }

            // 为了与之前计算得到的光照结果进行叠加 若没有Blend 则此Pass的结果会覆盖之前的光照结果
            Blend One One       // 不是必须设置为One One   也可以设置为SrcAlpha One等
            
            CGPROGRAM
            
            #pragma multi_compile_fwdadd

            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            // !!! Unity内置函数是没有归一化的 需要手动归一化
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 计算漫反射部分
                fixed3 worldNormal = normalize(i.worldNormal);


                // 计算不同光源的方向 (若当前前向渲染Pass处理的光源是平行光,那么Unity底层渲染引擎就会定义USING_DIRECTIONAL_LIGHT)
                #ifdef USING_DIRECTIONAL_LIGHT
                    // 若是平行光 光源方向则可以直接得到
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);     
                #else
                    // 若是点光源或者聚光灯,那么_WorldSpaceLightPos0.xyz表示的就是世界空间下的光源位置,想要得到光源方向的话就需要进行计算
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);    
                #endif


                fixed3 diffuse =  _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                
                // 计算高光反射部分
                // 获取世界空间反射方向(reflect函数入射方向要求从光源指向交点处,故取反)
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
                
                // 获取世界空间视角方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

                // 在世界空间获取 half direction
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // 套公式
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
 
                // 处理不同光源的衰减
                // 可以使用数学表达式计算给定点相对于点光源和聚光灯的衰减,但这些计算往往复杂
                // 因此Unity选择了使用一张纹理作为查找表(LUT),以在片元着色器中得到光源的衰减
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0;
                #else
                    // 首先得到光源空间下的坐标,然后使用该坐标对衰减纹理进行采样得到衰减值
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #endif
                return fixed4(ambient + (diffuse + specular) * atten, 1.0);

            }
            ENDCG
        }
    }
    FallBack "Specular"
}
