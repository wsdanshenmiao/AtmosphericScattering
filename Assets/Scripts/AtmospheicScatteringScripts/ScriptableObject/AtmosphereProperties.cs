using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using Unity.Mathematics;
using System.Numerics;

[Serializable]
[CreateAssetMenu(fileName = "Atmosphere", menuName = "AtmosphereSettings")]
public class AtmosphereProperties : ScriptableObject
{
    [SerializeField]
    public float SeaLevel = 0.0f;

    [SerializeField]
    public float PlanetRadius = 6360000.0f;

    [SerializeField]
    public UnityEngine.Vector4 PlanetCenter = new UnityEngine.Vector4(0,0,0,0);

    [SerializeField]
    public float AtmosphereHeight = 60000.0f;

    [SerializeField]
    public float SunLightIntensity = 31.4f;

    [SerializeField]
    public Color SunLightColor = Color.white;

    [SerializeField]
    public float RayleighScaling = 1.0f;

    [SerializeField]
    public float RayleighScatteringScale = 1.0f;

    [SerializeField]
    public float RayleighScatteringScalarHeight = 8000.0f;

    [SerializeField]
    public float MieScatteringScale = 1.0f;

    [SerializeField]
    public float MieAnisotropy = 0.8f;

    [SerializeField]
    public float MieScatteringScalarHeight = 1200.0f;

    [SerializeField]
    public float PointScatterCount = 100;

    [SerializeField]
    public float ScatterCount = 100;
}
