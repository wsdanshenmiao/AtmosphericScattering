#ifndef __RAYMARCHING__HLSL__
#define __RAYMARCHING__HLSL__

#include "Util.hlsl"
#include "Scattering.hlsl"

#ifndef COMPUTESHADER
sampler2D _OutDencityLut;
sampler3D _SumRayleighLut;
sampler3D _SumMieLut;
#endif


/*
    光线从太阳出发，到达大气边缘的C点
    经过路径CP上的衰减到达P点（0级散射）
    在P点发生一次散射，将一部分光散射到了观察方向上（1级散射）
    这部分光又经过AP路径上的衰减最终到达了我们的眼睛
*/

// 对外散射的光学距离进行积分 D(CP)
float2 DensityCP(float3 currentPoint, float3 lightDir)
{
    float rayleighDcp = 0.0;
    float mieDcp = 0.0;
    float2 insertPoint = RayInsertSphere(currentPoint, lightDir, _PlanetCenter.xyz, _PlanetRadius + _AtmosphereHeight);
    float3 exitPoint = currentPoint + lightDir * insertPoint.y;

    float step = length(exitPoint - currentPoint) / _PointScatterCount;
    float3 stepDir = step * lightDir;

    for(int i = 0; i < _PointScatterCount; ++i, currentPoint += stepDir){
        float h = length(currentPoint - _PlanetCenter.xyz) - _PlanetRadius;
        rayleighDcp += AtmosphericDensityRatio(h, _RayleighScatteringScalarHeight) * step;
        mieDcp += AtmosphericDensityRatio(h, _MieScatteringScalarHeight) * step;
    }

    return float2(rayleighDcp, mieDcp);
}

//Ipa = Is * β(λ) * P(theta) * p(h) * exp(−β(λ) * (D(CP) + D(PA)))
//Ia = Is * β(λ) * P(theta) * f exp(−β(λ) * (D(CP) + D(PA))) * p(h) ds
// 计算AB路径上所有的贡献点,与颜色计算分离，方便再计算着色器中复用
void Inscattering(float3 pos, float3 viewDir, float3 lightDir, out float3 sumRayleigh, out float3 sumMie)
{
    float rayleighDensityPA = 0, mieDensityPA = 0;
    
    // 获取光线与大气的交点
    float2 insertPoint = RayInsertSphere(pos, viewDir, _PlanetCenter.xyz, _PlanetRadius + _AtmosphereHeight);
    float2 insertPoint1 = RayInsertSphere(pos, viewDir, _PlanetCenter.xyz, _PlanetRadius);

    if(insertPoint1.x > 0){
        insertPoint = insertPoint.y < insertPoint1.x ? insertPoint : insertPoint1;
    }

    float step = (insertPoint.y - insertPoint.x) / _ScatterCount;
    float3 stepDir = step * viewDir;
    float3 currentPoint = pos + viewDir * insertPoint.x;        //实现与球面相交的点

    [loop]
    for(int i = 0; i < _ScatterCount; ++i, currentPoint += stepDir) {
        float h = length(currentPoint - _PlanetCenter.xyz) - _PlanetRadius;
        
        float pointRayleighDensity = AtmosphericDensityRatio(h, _RayleighScatteringScalarHeight);
        float pointMieDensity = AtmosphericDensityRatio(h, _MieScatteringScalarHeight);

        rayleighDensityPA += pointRayleighDensity;
        mieDensityPA += pointMieDensity;

        float cos = dot(normalize(currentPoint - _PlanetCenter.xyz), -lightDir);
        float2 uv = GetDensityFromUv(cos, h);
#ifdef COMPUTESHADER
        //float2 densityCP = DensityCP(currentPoint ,lightDir);
        float2 densityCP = _OutDencityLut.SampleLevel(LinearClampSampler, uv, 0.0).xy;
#else
        //float2 densityCP = DensityCP(currentPoint ,lightDir);
        float2 densityCP = tex2D(_OutDencityLut , uv).xy;
#endif
        float3 ray = exp(-RayleighCoefficient() * (densityCP.x + rayleighDensityPA)) * pointRayleighDensity;
        float3 mie = exp(-RayleighCoefficient() * (densityCP.y + mieDensityPA)) * pointMieDensity;

        sumRayleigh += ray * step;
        sumMie += mie * step;
    }
}


#endif