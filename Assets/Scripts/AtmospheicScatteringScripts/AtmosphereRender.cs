using System.Collections;
using System.Collections.Generic;
using UnityEditorInternal;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class AtmosphereRender : ScriptableRendererFeature
{
    public class CustomRenderPass : ScriptableRenderPass
{
    RenderTexture m_SkyColorLut;
    RenderTexture m_OutDencityLut;

    public Material m_SkyColorLutMaterial;
    public Material m_OutDencityLutmaterial;
    public AtmosphereProperties atmosphereProperties;

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        m_SkyColorLut = RenderTexture.GetTemporary(256,128,0,RenderTextureFormat.RGB111110Float);
        m_OutDencityLut = RenderTexture.GetTemporary(256,64,0,RenderTextureFormat.RGFloat);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get();
        cmd.SetGlobalTexture("_SkyColorLut", m_SkyColorLut);
        cmd.SetGlobalTexture("_OutDencityLut", m_OutDencityLut);
        cmd.SetGlobalFloat("_SeaLevel", atmosphereProperties.SeaLevel);
        cmd.SetGlobalVector("_Planetcenter",atmosphereProperties.PlanetCenter);
        cmd.SetGlobalFloat("_PlanetRadius", atmosphereProperties.PlanetRadius);
        cmd.SetGlobalFloat("_AtmosphereHeight",atmosphereProperties.AtmosphereHeight);
        cmd.SetGlobalFloat("_SunLightIntensity", atmosphereProperties.SunLightIntensity);
        cmd.SetGlobalColor("_SunLightColor",atmosphereProperties.SunLightColor);
        cmd.SetGlobalFloat("_RayleighScaling",atmosphereProperties.RayleighScaling);
        cmd.SetGlobalFloat("_RayleighScatteringScalarHeight",atmosphereProperties.RayleighScatteringScalarHeight);
        cmd.SetGlobalFloat("_MieScaling",atmosphereProperties.MieScatteringScale);
        cmd.SetGlobalFloat("_MieAnisotropy",atmosphereProperties.MieAnisotropy);
        cmd.SetGlobalFloat("_MieScatteringScalarHeight",atmosphereProperties.MieScatteringScalarHeight);
        cmd.SetGlobalFloat("_PointScatterCount",atmosphereProperties.PointScatterCount);
        cmd.SetGlobalFloat("_ScatterCount",atmosphereProperties.ScatterCount);

        cmd.Blit(null, m_SkyColorLut, m_SkyColorLutMaterial);
        cmd.Blit(null, m_OutDencityLut, m_OutDencityLutmaterial);

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
        RenderTexture.ReleaseTemporary(m_SkyColorLut);
        RenderTexture.ReleaseTemporary(m_OutDencityLut);
    }

}

    private CustomRenderPass m_customRenderPass;

    public Material m_SkyColorLutMaterial;
    public Material m_OutScaterLutmaterial;
    public AtmosphereProperties atmosphereProperties;

    public override void Create()
    {
        m_customRenderPass = new CustomRenderPass();

        m_customRenderPass.renderPassEvent = RenderPassEvent.BeforeRendering;
        m_customRenderPass.m_SkyColorLutMaterial = m_SkyColorLutMaterial;
        m_customRenderPass.m_OutDencityLutmaterial = m_OutScaterLutmaterial;
        m_customRenderPass.atmosphereProperties = atmosphereProperties;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_customRenderPass);
    }


}
