// 统一管理光照衰减和阴影
//      光照衰减和阴影对物体最终的渲染结构的影响本质上是相同的
//          寻找一种方法同时计算两个信息 使用Unity内置宏UNITY_LIGHT_ATTENUATION
Shader "Custom/AttenuationAndShadowUseBuildInFunsShader"
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
            #include "AutoLight.cginc"

            // 为了保证shadow宏能正常工作
            // a2v 的顶点坐标变量名必须为 vertex
            // v2f 结构体必须命名为v
            // v2f 的顶点坐标变量名必须为 pos

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
                //1 宏 声明一个用于对阴影纹理采样的坐标,参数是下一个可用的插值寄存器的索引值
                SHADOW_COORDS(2)
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
                
                //2 宏 计算并向片元着色器传递阴影坐标
                TRANSFER_SHADOW(o);

                return o;
            }

            // !!! Unity内置函数是没有归一化的 需要手动归一化
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 计算漫反射部分
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));


                fixed3 diffuse =  _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                
                // 计算高光反射部分
                // 获取世界空间反射方向(reflect函数入射方向要求从光源指向交点处,故取反)
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
                
                // 获取世界空间视角方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                // 在世界空间获取 half direction
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // 套公式
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
 
                // 衰减值置为1
                // fixed atten = 1.0;
                //3 宏 计算阴影值
                //fixed shadow = SHADOW_ATTENUATION(i);
                // 替换上两行代码 (宏内定义atten) 计算阴影和衰减的宏
                    // 自动声明atten,传入v2f参数计算阴影值,世界空间坐标计算光源空间下的坐标再对光照衰减纹理进行次采样得到衰减值
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos); 

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
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz; // 把顶点从世界空间变换到光源空间
                    // _LightTexture0是内置的一张纹理,为了减少计算
                    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL; // 用坐标模的平方对衰减纹理进行采样
                    // 真正计算光源的线性衰减 (经测试发现光源边界比较尖锐)
                    // float distance = length(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                    // fixed atten = 1.0 / distance;
                
                #endif
                return fixed4(ambient + (diffuse + specular) * atten, 1.0);

            }
            ENDCG
        }
    }
    FallBack "Specular"
}
