// 渲染路径决定光照如何应用到shader里面
// 需要为每个Pass指定它使用的渲染路径
// 
// 前向渲染路径		(Forward Rendering Path)
// 延迟渲染路径		(Defferred Rendering Path)
// 顶点照明渲染路径	(Vertex Lit Rendering Path)   已经不再使用
// 
// 一般一个项目只使用一种渲染路径
// 
// 可以在项目设置(全局)或者摄像机(局部)中设置渲染路径
// 然后需要在每个Pass中使用标签来指定该Pass所使用的渲染路径

// Always		不管使用哪种渲染路径,该pass总会被渲染,但不会计算任何光照
// ForwardBase	用于前向渲染,会计算环境光、最重要的平行光、逐顶点/SH光源和Lightmaps
// ForwardAdd	用于前向渲染,会计算额外的逐像素光源,每个pass对应一个光源
// Deferred		用于延迟渲染,会渲染G-缓冲(G-buffer)
// ShadowCaster	把物体深度信息渲染到阴影映射纹理(shadowmap)或者一张深度纹理中

// 不再使用
// PrepassBase	用于遗留的延迟渲染,会渲染法线和高光反射的指数部分
// PrepassFinal	用于遗留的延迟渲染,通过合并纹理、光照和自发光来渲染得到最后的颜色

// 指定渲染路径就是我们和Unity底层渲染引擎的一次重要的沟通
// 然后Unity就会为我们提供内置的光照变量来访问这些属性


//// 前向渲染伪代码
//Pass
//{
//    for (each primitive in this model) {
//        for (each fragment covered by this primitive) {
//            if (failed in depth test)
//                // 若没有通过深度测试 则说明该片元不可见
//                discard;
//            else {
//                // 若该片元可见 则进行光照计算
//                float4 color = Shading(materialInfo, pos, normal, lightDir, viewDir);
//                // 更新帧缓冲
//                writeFrameBuffer(fragment, color);
//            }
//        }
//    }
//}

// N个物体受到M个光源的影响,则渲染整个场景需要N*M个pass
// 如果有大量逐像素光照,需要执行的pass数目会很大,因此渲染引擎通常会限制每个物体的逐像素光照的数目


// 前向渲染在Unity中有三种处理光照的方式:
//      逐顶点处理、逐像素处理、球谐函数(Spherical Harmonics, SH)处理

// 决定一个光源使用哪种处理模式取决于它的类型和渲染模式 类型是指光源是平行光还是其他类型光源 渲染模式指这个光源是否是重要的(Important 当成逐像素光源处理)
//      前向渲染中,渲染一个物体时,Unity会根据光源设置及光源对物体的影响程度(远近,光源强度等)来进行重要程度排序
//          其中,一定数目光源会按照逐像素处理 最多4个光源按照逐顶点处理 剩余的按SH方式处理
//              Unity判断规则:
//                  最亮的平行光按照逐像素处理
//                  Not Important按照逐顶点或者SH处理
//                  Important按照逐像素处理
//                  如果上述几个得到的逐像素光源数量小于Quality Setting中逐像素光源数量, 则会再挑几个进行逐像素处理
//                  
// 通常一个前向渲染Shader中会定义一个Base Pass(也可以定义多个 如双面渲染)以及一个Additional Pass
//      这个Base Pass仅会执行一次,而Additional Pass会根据影响该物体的其他逐像素光源的数目被多次调用,每个逐像素光源会执行一次Additional Pass

// 前向渲染中的光照变量
// _LightColor0                float4       该pass处理的逐像素光源的颜色
// _WorldSpaceLightPos0        float4       .xyz是该pass的逐像素光源的位置 若是平行光 则其w值为0 其他光源类型w值为1
// _LightMatrix0               float4x4     从世界空间到光源空间的变化矩阵 可用于采样cookie和光强衰减纹理
// unity_4LightPosX0, Y0, Z0   float4       仅用于Base Pass 是前四个非重要的点光源在世界空间中的位置
// unity_4LightAtten0          float4       仅用于Base Pass 存储了前四个非重要的点光源的衰减因子
// unity_LightColor            half4[4]     仅用于Base Pass 存储了前四个非重要的点光源的颜色

// 前向渲染中的内置光照函数
// float3 WorldSpaceLightDir(float4 v)      仅前向渲染 输入 模型 空间中顶点位置 返回世界空间从该点到光源的光照方向 未归一化 内部使用了下一个函数
// float3 UnityWorldSpaceLightDir(float4 v) 仅前向渲染 输入 世界 空间中顶点位置 返回世界空间从该点到光源的光照方向 未归一化
// float3 ObjSpaceLightDir(float4 v)        仅前向渲染 输入 模型 空间中顶点位置 返回模型空间从该店到光源的光照方向 未归一化
// float3 Shade4PointLights(...)            仅前向渲染 计算四个点光源的光照 参数是打包进矢量的光照数据 前向渲染通常使用其计算逐顶点光照
//

// 顶点照明渲染路径 5.x中就已不再使用
//      对硬件要求最低,性能最高,效果最差的类型
//          一般在一个pass中就可以完成
//      

// 延迟渲染路径 一种更为古老的渲染方法
//      由于前向渲染可能造成瓶颈问题,延迟渲染近年又流行起来 
//          延迟渲染会利用颜色缓冲、深度缓冲 以及G缓冲 存储了关心的表面其他信息(法线、位置、材质属性等)
//
// 延迟渲染原理
//      两个pass 
//          第一个不进行光照计算 仅计算可见片元 存入G-buffer
//          第二个利用G-buffer的各个片元信息进行光照计算
// Pass 1 {
//     // 不进行真正的光照计算
//     // 把光照计算信息存储到G-buffer中
//     for (each primitive in this model) {
//         for (each fragment covered by this primitive) {
//             if (failed in depth test){
//                 // 未通过深度测试 说明片元不可见
//                 discard;
//             } else {
//                 // 若该片元可见
//                 // 将需要的信息存入G-buffer
//                 writeGBuffer(materialInfo, pos, normal);
//             }
//         }
//     }
// }
   
// Pass 2 {
//     // 利用G-buffer里的信息进行真正光照计算
//     for (each pixel in the screen) {
//         if (the pixel is valid) {
//             // 若该像素有效
//             // 读取G-buffer信息
//             readBuffer(pixel, materialInfo, pos, normal);
   
//             // 根据读到的信息进行光照计算
//             float4 color = Shading(materialInfo, pos, normal, lightDir, viewDir);
//             // 更新帧缓冲
//             writeFrameBufer(pixel, color);  
//         }
//     }
// }
//
// Unity中的延迟渲染
//      Unity有两种延迟渲染 一种是遗留的 一种是5.x中的  若场景中使用了大量实时光照 则尽量选择延迟渲染路径 但是需要一定硬件支持
//  延迟渲染中每个光源都可以按照逐像素处理
//      缺点:不支持真正的抗锯齿功能
//           不能处理半透明物体
//            对显卡有一定要求(必须支持MRT、Shader Mode 3.0 及以上、深度渲染纹理以及双面的模板缓冲)
//
//      延迟渲染可访问的内置变量和函数
//          _LightColor0    float4      光源颜色
//          _LightMatrix0   float4x4    从世界空间到光源空间的变换矩阵,用于采样cookie和光强衰减纹理
//

// 平行光
//      只有方向 没有位置 没有衰减概念(光强不会随着距离改变)

// 点光源
//      由空间中一个球体定义 强度衰减值可以由一个函数定义

// 聚光灯
//      
Shader "Custom/RenderingPathTestShader"
{
    Properties
    {

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

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(1.0, 1.0, 1.0, 1.0);
            }
            ENDCG
        }
    }
}
