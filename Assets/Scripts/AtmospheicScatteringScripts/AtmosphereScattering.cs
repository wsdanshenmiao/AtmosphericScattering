using System;
using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using Unity.VisualScripting;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UIElements;
using UnityEngine.Video;

public class AtmosphereScattering : MonoBehaviour
{
    public bool renderSun;
    public ComputeShader scatterComputeShader;

    private UnityEngine.Vector3 m_SkyboxLutSize = new UnityEngine.Vector3(32,128,32);
    public RenderTexture m_SumRayleighLut;
    public RenderTexture m_SumMieLut;
    public RenderTexture m_OutDencityLut;
    private UnityEngine.Vector3 m_InscatteringLutSize = new UnityEngine.Vector3(8,8,64);
    private RenderTexture m_InscatteringLut;


    private Material m_OutScatteringMaterial;
    public Material m_SkyboxMaterial;
    public Light m_Sun;

    private Camera m_Camera;
    private UnityEngine.Vector4[] _FrustumCorners = new UnityEngine.Vector4[4];

    public AtmosphereProperties atmosphereProperties;

    private void UpdateMaterialParamerters(Material material)
    {
        if(renderSun){
            material.SetInt("_RenderSun", 1);
        }
        else{
            material.SetInt("_RenderSun", 0);
        }
        material.SetFloat("_SeaLevel", atmosphereProperties.SeaLevel);
        material.SetVector("_PlanetCenter",atmosphereProperties.PlanetCenter);
        material.SetFloat("_PlanetRadius", atmosphereProperties.PlanetRadius);
        material.SetFloat("_AtmosphereHeight",atmosphereProperties.AtmosphereHeight);
        material.SetFloat("_SunLightIntensity", atmosphereProperties.SunLightIntensity);
        material.SetColor("_SunLightColor",atmosphereProperties.SunLightColor);
        material.SetFloat("_RayleighScaling",atmosphereProperties.RayleighScaling);
        material.SetFloat("_RayleighScatteringScalarHeight",atmosphereProperties.RayleighScatteringScalarHeight);
        material.SetFloat("_MieScaling",atmosphereProperties.MieScatteringScale);
        material.SetFloat("_MieAnisotropy",atmosphereProperties.MieAnisotropy);
        material.SetFloat("_MieScatteringScalarHeight",atmosphereProperties.MieScatteringScalarHeight);
        material.SetFloat("_PointScatterCount",atmosphereProperties.PointScatterCount);
        material.SetFloat("_ScatterCount",atmosphereProperties.ScatterCount);
        material.SetTexture("_SumRayleighLut", m_SumRayleighLut);
        material.SetTexture("_SumMieLut",m_SumMieLut);
        material.SetTexture("_OutDencityLut", m_OutDencityLut);
    }
    private void PreComputeOutDencityLut()
    {
        if(m_OutDencityLut == null){
            m_OutDencityLut = new RenderTexture(1024, 1024, 0, RenderTextureFormat.RGFloat, RenderTextureReadWrite.Linear);
            m_OutDencityLut.name = "OutDencityLut";
            m_OutDencityLut.filterMode = FilterMode.Bilinear;
            m_OutDencityLut.Create();
        }

        RenderTexture nullTexture = null;
        Graphics.Blit(nullTexture, m_OutDencityLut, m_OutScatteringMaterial, 0);
        m_OutScatteringMaterial.SetTexture("_OutDencityLut", m_OutDencityLut);
    }

/*
    private void InitInscatteringLut()
    {
        m_InscatteringLut = new RenderTexture((int)m_InscatteringLutSize.x, (int)m_InscatteringLutSize.y, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
        m_InscatteringLut.name = "InscatteringLut";
        m_InscatteringLut.dimension = TextureDimension.Tex3D;
        m_InscatteringLut.volumeDepth = (int)m_InscatteringLutSize.z;
        m_InscatteringLut.enableRandomWrite = true;
        m_InscatteringLut.Create();
    }
*/

    private void UpdateComputeShaderParameters(int kernel)
    {
        scatterComputeShader.SetTexture(kernel, "_OutDencityLut", m_OutDencityLut);
        scatterComputeShader.SetFloat("_SeaLevel", atmosphereProperties.SeaLevel);
        scatterComputeShader.SetVector("_PlanetCenter",atmosphereProperties.PlanetCenter);
        scatterComputeShader.SetFloat("_PlanetRadius", atmosphereProperties.PlanetRadius);
        scatterComputeShader.SetFloat("_AtmosphereHeight",atmosphereProperties.AtmosphereHeight);
        scatterComputeShader.SetFloat("_SunLightIntensity", atmosphereProperties.SunLightIntensity);
        scatterComputeShader.SetVector("_SunLightColor",atmosphereProperties.SunLightColor);
        scatterComputeShader.SetFloat("_RayleighScaling",atmosphereProperties.RayleighScaling);
        scatterComputeShader.SetFloat("_RayleighScatteringScalarHeight",atmosphereProperties.RayleighScatteringScalarHeight);
        scatterComputeShader.SetFloat("_MieScaling",atmosphereProperties.MieScatteringScale);
        scatterComputeShader.SetFloat("_MieAnisotropy",atmosphereProperties.MieAnisotropy);
        scatterComputeShader.SetFloat("_MieScatteringScalarHeight",atmosphereProperties.MieScatteringScalarHeight);
        scatterComputeShader.SetFloat("_PointScatterCount",atmosphereProperties.PointScatterCount);
        scatterComputeShader.SetFloat("_ScatterCount",atmosphereProperties.ScatterCount);
        scatterComputeShader.SetVector("_CameraPos", m_Camera.transform.position);
    }

    private void PreComputeSkyboxLut()
    {
        if(m_SumRayleighLut == null){
            m_SumRayleighLut = new RenderTexture((int)m_SkyboxLutSize.x, (int)m_SkyboxLutSize.y, 0, RenderTextureFormat.RGB111110Float, RenderTextureReadWrite.Linear);
            m_SumRayleighLut.name = "SumRayleighLut";
            m_SumRayleighLut.dimension = TextureDimension.Tex3D;
            m_SumRayleighLut.volumeDepth = (int)m_SkyboxLutSize.z;
            m_SumRayleighLut.enableRandomWrite = true;
            m_SumRayleighLut.Create();
        }
        if(m_SumMieLut == null){
            m_SumMieLut = new RenderTexture((int)m_SkyboxLutSize.x, (int)m_SkyboxLutSize.y, 0, RenderTextureFormat.RGB111110Float, RenderTextureReadWrite.Linear);
            m_SumMieLut.name = "SumRayleighLut";
            m_SumMieLut.dimension = TextureDimension.Tex3D;
            m_SumMieLut.volumeDepth = (int)m_SkyboxLutSize.z;
            m_SumMieLut.enableRandomWrite = true;
            m_SumMieLut.Create();
        }

        int kernel = scatterComputeShader.FindKernel("InscatteringLut");
        scatterComputeShader.SetTexture(kernel, "_SumRayleighLut", m_SumRayleighLut);
        scatterComputeShader.SetTexture(kernel, "_SumMieLut", m_SumMieLut);
        UpdateComputeShaderParameters(kernel);

        scatterComputeShader.Dispatch(kernel, (int)m_SkyboxLutSize.x, (int)m_SkyboxLutSize.y, (int)m_SkyboxLutSize.z);
    }


    private void UpdateInscatteringLut()
    {
        int kernel = scatterComputeShader.FindKernel("InscatteringLut");

        scatterComputeShader.SetTexture(kernel, "_InscatteringLut", m_InscatteringLut);
        scatterComputeShader.SetVector("_BottomLeftCorner", _FrustumCorners[0]);        
        scatterComputeShader.SetVector("_TopLeftCorner", _FrustumCorners[1]);
        scatterComputeShader.SetVector("_TopRightCorner", _FrustumCorners[2]);
        scatterComputeShader.SetVector("_BottomRightCorner", _FrustumCorners[3]);
        scatterComputeShader.SetVector("_LightDir", m_Sun.transform.forward);
        scatterComputeShader.SetVector("_CameraPos", m_Camera.transform.position);

        UpdateComputeShaderParameters(kernel);

        scatterComputeShader.Dispatch(kernel, (int)m_InscatteringLutSize.x, (int)m_InscatteringLutSize.y, 1);
    }

    void Awake()
    {
        m_Camera = GetComponent<Camera>();
    }

    void Start()
    {
        Shader shader = Shader.Find("Atmosphere/AtmosphereScattering");
        if(shader == null){
            throw new Exception("Miss AtmosphereScatteringShader");
        }
        m_OutScatteringMaterial = new Material(shader);
        UpdateMaterialParamerters(m_OutScatteringMaterial);
        UpdateMaterialParamerters(m_SkyboxMaterial);
        PreComputeOutDencityLut();
        PreComputeSkyboxLut();
        //InitInscatteringLut();
    }

    void Update()
    {
        UpdateMaterialParamerters(m_OutScatteringMaterial);
        UpdateMaterialParamerters(m_SkyboxMaterial);
    }

    void OnPreRender()
    {
        //_FrustumCorners[0] = m_Camera.ViewportToWorldPoint(new Vector3(0, 0, m_Camera.farClipPlane));        
        //_FrustumCorners[1] = m_Camera.ViewportToWorldPoint(new Vector3(0, 1, m_Camera.farClipPlane));
        //_FrustumCorners[2] = m_Camera.ViewportToWorldPoint(new Vector3(1, 1, m_Camera.farClipPlane));
        //_FrustumCorners[3] = m_Camera.ViewportToWorldPoint(new Vector3(1, 0, m_Camera.farClipPlane));

        //UpdateInscatteringLut();
        //m_OutScatteringMaterial.SetTexture("_InscatteringLut", m_InscatteringLut);
    }

    void Destroy()
    {
        Destroy(m_OutDencityLut);
    }
}
