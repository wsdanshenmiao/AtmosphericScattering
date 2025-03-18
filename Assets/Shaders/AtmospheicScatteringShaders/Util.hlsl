#ifndef __UTIL__HLSL__
#define __UTIL__HLSL__

#include "Scattering.hlsl"

// 射线与球相交
float2 RayInsertSphere(float3 rayOrigin, float3 rayDir, float3 center, float radius)
{
    rayDir = normalize(rayDir);

    float3 oToC = center - rayOrigin;    // 起点到球心
    float a = length(oToC);
    float b = dot(oToC, rayDir);
    float c = pow(a, 2) - pow(b, 2);
    if(pow(radius, 2) - c < 0) { // 不相交
        return float2(-1, -1);
    }
    
    float d = sqrt(pow(radius, 2) - c);

    return float2(b - d, b + d);
}


float Sun(float cos)
{
    float g = 0.98;
    float gg = g * g;

    float sun = pow(1.0 - g, 2.0) / (4.0 * M_PI * pow(abs(1.0 + gg - 2.0 * g * cos), 1.5));
	return sun * 0.001;
}

float3 RenderSun(float3 mie, float cos)
{
    return mie * Sun(cos);
}

void TransCoordsToParameters(float3 coords, out float3 lightDir, out float3 viewDir, out float height)
{
    height = coords.x * coords.x * _AtmosphereHeight;
    
    float ch = -(sqrt(height * (2 * _PlanetRadius + height)) / (_PlanetRadius + height));
    float viewZenith = coords.y;
    if (viewZenith > 0.5) {
		viewZenith = ch + pow((viewZenith - 0.5) * 2, 5) * (1 + ch);
	}
	else {
		viewZenith = ch - pow(viewZenith * 2, 5) * (1 - ch);
	}
    viewDir = float3(sqrt(saturate(1 - viewZenith * viewZenith)), viewZenith, 0);
    
    float sunZenith = (tan((2 * coords.z - 1 + 0.26) * 0.75)) / (tan(1.26 * 1.1));
    lightDir = -float3(sqrt(saturate(1 - sunZenith * sunZenith)), sunZenith, 0);
}

void TransParametersTocoords(float3 planetCenterToViewPos, float3 lightDir, float3 viewDir, float height, out float3 coords)
{
    float3 normal = planetCenterToViewPos;
    float viewZenith = dot(normal, viewDir);
    float sunZenith = dot(normal, -lightDir);

    coords = float3(height / _AtmosphereHeight, viewZenith * 0.5 + 0.5, sunZenith * 0.5 + 0.5);
    coords.x = sqrt(height / _AtmosphereHeight);
    float ch = -(sqrt(height * (2 * _PlanetRadius + height)) / (_PlanetRadius + height));
    if (viewZenith > ch) {
        coords.y = 0.5 * pow((viewZenith - ch) / (1 - ch), 0.2) + 0.5;
    }
    else {
        coords.y = 0.5 * pow((ch - viewZenith) / (ch + 1), 0.2);
    }
    coords.z = 0.5 * ((atan(max(sunZenith, -0.1975) * tan(1.26 * 1.1)) / 1.1) + (1 - 0.26));
}

void UvToDensity(float2 uv, out float cos, out float h)
{
    cos = 2.0 * uv.x - 1.0;
    h = _AtmosphereHeight * uv.y;
}

float2 GetDensityFromUv(float cos, float h)
{
    float2 uv;
    uv.x = (cos + 1) / 2;
    uv.y = h / _AtmosphereHeight;
    return uv;
}


#endif