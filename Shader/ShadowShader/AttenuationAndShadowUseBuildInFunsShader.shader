// ͳһ�������˥������Ӱ
//      ����˥������Ӱ���������յ���Ⱦ�ṹ��Ӱ�챾��������ͬ��
//          Ѱ��һ�ַ���ͬʱ����������Ϣ ʹ��Unity���ú�UNITY_LIGHT_ATTENUATION
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
            // ��pass���ڼ��㻷���� ����� ���������ж��ƽ�й� ���ѡ���������Ǹ����ݸ�Base Pass���������ش���
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM

            // ȷ����shader��ʹ�ù���˥���ȹ��ձ������Ա���ȷ��ֵ
            #pragma multi_compile_fwdadd
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            // Ϊ�˱�֤shadow������������
            // a2v �Ķ����������������Ϊ vertex
            // v2f �ṹ���������Ϊv
            // v2f �Ķ����������������Ϊ pos

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
                //1 �� ����һ�����ڶ���Ӱ�������������,��������һ�����õĲ�ֵ�Ĵ���������ֵ
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
                
                //2 �� ���㲢��ƬԪ��ɫ��������Ӱ����
                TRANSFER_SHADOW(o);

                return o;
            }

            // !!! Unity���ú�����û�й�һ���� ��Ҫ�ֶ���һ��
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // ���������䲿��
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));


                fixed3 diffuse =  _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                
                // ����߹ⷴ�䲿��
                // ��ȡ����ռ䷴�䷽��(reflect�������䷽��Ҫ��ӹ�Դָ�򽻵㴦,��ȡ��)
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
                
                // ��ȡ����ռ��ӽǷ���
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                // ������ռ��ȡ half direction
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // �׹�ʽ
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
 
                // ˥��ֵ��Ϊ1
                // fixed atten = 1.0;
                //3 �� ������Ӱֵ
                //fixed shadow = SHADOW_ATTENUATION(i);
                // �滻�����д��� (���ڶ���atten) ������Ӱ��˥���ĺ�
                    // �Զ�����atten,����v2f����������Ӱֵ,����ռ���������Դ�ռ��µ������ٶԹ���˥��������дβ����õ�˥��ֵ
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos); 

                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }
            ENDCG
        }

        Pass 
        {
            // Ϊ���������ع�Դ����Additional Pass
            Tags { "LightMode" = "ForwardAdd" }

            // Ϊ����֮ǰ����õ��Ĺ��ս�����е��� ��û��Blend ���Pass�Ľ���Ḳ��֮ǰ�Ĺ��ս��
            Blend One One       // ���Ǳ�������ΪOne One   Ҳ��������ΪSrcAlpha One��
            
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

            // !!! Unity���ú�����û�й�һ���� ��Ҫ�ֶ���һ��
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // ���������䲿��
                fixed3 worldNormal = normalize(i.worldNormal);


                // ���㲻ͬ��Դ�ķ��� (����ǰǰ����ȾPass����Ĺ�Դ��ƽ�й�,��ôUnity�ײ���Ⱦ����ͻᶨ��USING_DIRECTIONAL_LIGHT)
                #ifdef USING_DIRECTIONAL_LIGHT
                    // ����ƽ�й� ��Դ���������ֱ�ӵõ�
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);     
                #else
                    // ���ǵ��Դ���߾۹��,��ô_WorldSpaceLightPos0.xyz��ʾ�ľ�������ռ��µĹ�Դλ��,��Ҫ�õ���Դ����Ļ�����Ҫ���м���
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);    
                #endif


                fixed3 diffuse =  _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                
                // ����߹ⷴ�䲿��
                // ��ȡ����ռ䷴�䷽��(reflect�������䷽��Ҫ��ӹ�Դָ�򽻵㴦,��ȡ��)
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
                
                // ��ȡ����ռ��ӽǷ���
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

                // ������ռ��ȡ half direction
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // �׹�ʽ
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
 
                // ����ͬ��Դ��˥��
                // ����ʹ����ѧ���ʽ�������������ڵ��Դ�;۹�Ƶ�˥��,����Щ������������
                // ���Unityѡ����ʹ��һ��������Ϊ���ұ�(LUT),����ƬԪ��ɫ���еõ���Դ��˥��
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0;
                #else
                    // ���ȵõ���Դ�ռ��µ�����,Ȼ��ʹ�ø������˥��������в����õ�˥��ֵ
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz; // �Ѷ��������ռ�任����Դ�ռ�
                    // _LightTexture0�����õ�һ������,Ϊ�˼��ټ���
                    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL; // ������ģ��ƽ����˥��������в���
                    // ���������Դ������˥�� (�����Է��ֹ�Դ�߽�Ƚϼ���)
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
