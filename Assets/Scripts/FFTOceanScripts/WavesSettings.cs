using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SocialPlatforms;

// 创建一个用来管理海洋参数的结构体
public struct SpectrumSettings
{
    public float scale;
    public float angle;
    public float spreadBlend;
    public float swell;
    public float alpha;
    public float peakOmega;
    public float gamma;
    public float shortWavesFade;
}

[System.Serializable]
public struct DisplaySpectrumSettings
{
    [Range(0, 10)]
    public float scale;
    public float windSpeed;
    public float windDirection;
    [Range(0, 1)]
    public float spreadBlend;
    [Range(0, 10)]
    public float peakEnhancement;
    [Range(0, 1)]
    public float shortWavesFade;
}

[CreateAssetMenu(fileName = "New waves settings", menuName = "Ocean/Waves Settings")]
public class WavesSettings : ScriptableObject
{
    public float g;
    [Range(0, 20)]
    public float lambda;
    public DisplaySpectrumSettings waves;

    SpectrumSettings[] spectrums = new SpectrumSettings[1];

    public void SetParametersToShader(ComputeShader shader, int kernelIndex, ComputeBuffer paramsBuffer)
    {
        shader.SetFloat(G_PROP, g);
        shader.SetFloat(DEPTH_PROP, 500.0f);

        FillSettingsStruct(waves, ref spectrums[0]);

        paramsBuffer.SetData(spectrums);
        shader.SetBuffer(kernelIndex, SPECTRUMS_PROP, paramsBuffer);
    }

    void FillSettingsStruct(DisplaySpectrumSettings display, ref SpectrumSettings settings)
    {
        settings.scale = display.scale;
        settings.angle = display.windDirection / 180 * Mathf.PI;
        settings.spreadBlend = display.spreadBlend;
        settings.alpha = JonswapAlpha(g, 30000, display.windSpeed);
        settings.peakOmega = JonswapPeakFrequency(g, 30000, display.windSpeed);
        settings.gamma = display.peakEnhancement;
        settings.shortWavesFade = display.shortWavesFade;
    }

    float JonswapAlpha(float g, float fetch, float windSpeed)
    {
        return 0.076f * Mathf.Pow(g * fetch / windSpeed / windSpeed, -0.22f);
    }

    float JonswapPeakFrequency(float g, float fetch, float windSpeed)
    {
        return 22 * Mathf.Pow(windSpeed * fetch / g / g, -0.33f);
    }

    int G_PROP = Shader.PropertyToID("GravityAcceleration");
    int DEPTH_PROP = Shader.PropertyToID("Depth");
    int SPECTRUMS_PROP = Shader.PropertyToID("Spectrums");
}
