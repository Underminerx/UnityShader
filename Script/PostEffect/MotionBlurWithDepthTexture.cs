using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// 获取及使用深度与法线纹理:
// 
// Unity获取深度纹理:
// 1.直接从深度缓存中获取(延迟渲染G - buffer)
// 
//         2.从单独的渲染pass中获取: 通过着色器替换技术选择RenderType为Opaque的物体,判断其使用的渲染队列是否小于等于2500,满足则渲染到深度和法线纹理中
//             因此要想让物体能够出现再深度和法线纹理中, 就必须再Shader中设置正确的RenderType标签
// 
// 	法线信息的获取在延迟渲染中容易得到, Unity只需要合并深度和法线缓存即可
// 					而在前向渲染中, 默认下不创建法线缓存, 因此Unity使用一个单独Pass把整个场景再次渲染一次来完成
// 
// 	获取深度纹理:
// 		camera.depthTextureMode = DepthTextureMode.DepthNormals;
// 
// 让一个摄像机同时产生一张深度和深度 + 法线纹理:
// 		camera.depthTextureMode |= DepthTextureMode.Depth;
// camera.depthTextureMode |= DepthTextureMode.DepthNormals;
// 
// 大多数情况下直接使用tex2D函数来对深度纹理进行采样
//     平台差异化处理: 宏
//                 float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
// 
// 
// 纹理采样得到的深度值往往是非线性的,非线性来自于透视投影使用的裁剪矩阵
//     为了得到线性深度值, 需要倒推定点变化
// 			内置函数:(使用了内置变量_ZBufferParams得到远近裁剪平面的距离)
//                 LinearEyeDepth  负责把深度纹理的采样结果转换到视角空间下的深度值
//                 Linear01Depth	返回一个范围在[0, 1] 的线性深度值
// 
//     输出线性深度值:
// 		float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
// float linearDepth = Linear01Depth(depth);
// return fixed4(linearDepth, linearDepth, linearDepth, 1.0);
// 输出法线方向:
// fixed3 normal = DecodeViewNormalStereo(tex2D(_CameraDepthNormalTexture, i.uv).xy);
// return fixed4(normal * 0.5 + 0.5, 1.0);
// 
// 之前使用的是混合多张屏幕图像实现运动模糊,另一种应用更加广泛的技术是速度映射图
//     速度映射图存储了每个像素的速度, 然后使用这个速度来决定模糊的方向与大小
// 		速度缓冲
// 			实现方法1:把场景中所有物体的速度渲染到一张纹理中,但是需要修改场景中所有物体的shader代码,使其添加计算速度的代码并输出到一个渲染纹理中
//             实现方法2:利用深度纹理在片元着色器中为每个像素计算其在世界空间下的位置,得到世界空间中的顶点坐标后使用前一帧的视角* 投影矩阵对其进行变换,
//                         得到在前一帧中的NDC(Normalized Device Coordinates)坐标, 然后计算前一帧与当前帧的位置差, 生成该像素的速度,
//                             可以在一个屏幕后处理步骤中完成整个效果的模拟, 但是缺点是需要在片元着色器中进行两次矩阵乘法, 开销大

public class MotionBlurWithDepthTexture : PostEffectsBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial = null;
    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    [Range(0.0f, 1.0f)]
    public float blurSize = 0.5f;

    private Camera myCamera;
    public Camera camera
    {
        get
        {
            if (!myCamera)
            {
                myCamera = GetComponent<Camera>();
            }
            return myCamera;
        }
    }

    // 上一帧摄像机的视角*投影矩阵
    private Matrix4x4 previousViewProjectionMatrix;

    private void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material)
        {
            material.SetFloat("_BlurSize", blurSize);

            material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
            Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;       // 视角矩阵和投影矩阵
            Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
            material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
            previousViewProjectionMatrix = currentViewProjectionMatrix;

            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

}
