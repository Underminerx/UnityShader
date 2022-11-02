using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// ��ȡ��ʹ������뷨������:
// 
// Unity��ȡ�������:
// 1.ֱ�Ӵ���Ȼ����л�ȡ(�ӳ���ȾG - buffer)
// 
//         2.�ӵ�������Ⱦpass�л�ȡ: ͨ����ɫ���滻����ѡ��RenderTypeΪOpaque������,�ж���ʹ�õ���Ⱦ�����Ƿ�С�ڵ���2500,��������Ⱦ����Ⱥͷ���������
//             ���Ҫ���������ܹ���������Ⱥͷ���������, �ͱ�����Shader��������ȷ��RenderType��ǩ
// 
// 	������Ϣ�Ļ�ȡ���ӳ���Ⱦ�����׵õ�, Unityֻ��Ҫ�ϲ���Ⱥͷ��߻��漴��
// 					����ǰ����Ⱦ��, Ĭ���²��������߻���, ���Unityʹ��һ������Pass�����������ٴ���Ⱦһ�������
// 
// 	��ȡ�������:
// 		camera.depthTextureMode = DepthTextureMode.DepthNormals;
// 
// ��һ�������ͬʱ����һ����Ⱥ���� + ��������:
// 		camera.depthTextureMode |= DepthTextureMode.Depth;
// camera.depthTextureMode |= DepthTextureMode.DepthNormals;
// 
// ����������ֱ��ʹ��tex2D�����������������в���
//     ƽ̨���컯����: ��
//                 float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
// 
// 
// ��������õ������ֵ�����Ƿ����Ե�,������������͸��ͶӰʹ�õĲü�����
//     Ϊ�˵õ��������ֵ, ��Ҫ���ƶ���仯
// 			���ú���:(ʹ�������ñ���_ZBufferParams�õ�Զ���ü�ƽ��ľ���)
//                 LinearEyeDepth  ������������Ĳ������ת�����ӽǿռ��µ����ֵ
//                 Linear01Depth	����һ����Χ��[0, 1] ���������ֵ
// 
//     ����������ֵ:
// 		float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
// float linearDepth = Linear01Depth(depth);
// return fixed4(linearDepth, linearDepth, linearDepth, 1.0);
// ������߷���:
// fixed3 normal = DecodeViewNormalStereo(tex2D(_CameraDepthNormalTexture, i.uv).xy);
// return fixed4(normal * 0.5 + 0.5, 1.0);
// 
// ֮ǰʹ�õ��ǻ�϶�����Ļͼ��ʵ���˶�ģ��,��һ��Ӧ�ø��ӹ㷺�ļ������ٶ�ӳ��ͼ
//     �ٶ�ӳ��ͼ�洢��ÿ�����ص��ٶ�, Ȼ��ʹ������ٶ�������ģ���ķ������С
// 		�ٶȻ���
// 			ʵ�ַ���1:�ѳ���������������ٶ���Ⱦ��һ��������,������Ҫ�޸ĳ��������������shader����,ʹ����Ӽ����ٶȵĴ��벢�����һ����Ⱦ������
//             ʵ�ַ���2:�������������ƬԪ��ɫ����Ϊÿ�����ؼ�����������ռ��µ�λ��,�õ�����ռ��еĶ��������ʹ��ǰһ֡���ӽ�* ͶӰ���������б任,
//                         �õ���ǰһ֡�е�NDC(Normalized Device Coordinates)����, Ȼ�����ǰһ֡�뵱ǰ֡��λ�ò�, ���ɸ����ص��ٶ�,
//                             ������һ����Ļ���������������Ч����ģ��, ����ȱ������Ҫ��ƬԪ��ɫ���н������ξ���˷�, ������

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

    // ��һ֡��������ӽ�*ͶӰ����
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
            Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;       // �ӽǾ����ͶӰ����
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
