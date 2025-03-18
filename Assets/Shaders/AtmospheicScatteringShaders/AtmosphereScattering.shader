Shader "Atmosphere/AtmosphereScattering"
{
    Properties
    {
        /*
        _MainTex ("Texture", 2D) = "white" {}
        // 海平面
        _SeaLevel ("Sea Level", Float) = 0.0
        // 地球中心
        _PlanetCenter ("Planet Center", Color) =(0,0,0,0)
        // 地球半径
        _PlanetRadius ("Planet Radius", Float) = 6356000.0
        // 大气层高度
        _AtmosphereHeight ("Atmosphere Height", Float) = 60000.0
        // 太阳光强度
        _SunLightIntensity ("Sun Light Intensity", Float) = 32.0
        // 太阳光
        _SunLightColor ("Sun Light Color", Color) = (1.0, 1.0, 1.0, 1.0)
        // 瑞利散射缩放比
        _RayleighScaling ("Rayleigh Scaling", Float) = 1.0
        // 发生瑞利散射的层数
        _RayleighScatteringScalarHeight ("Rayleigh Scattering Scalar Height", Float) = 8000.0
        // 米氏散射缩放比
        _MieScaling ("Mie Scaling", Float) = 1.0
        // 米氏散射各向异性
        _MieAnisotropy ("Mie Aniisotropy" ,Float) = 0.7
        // 发生米氏散射的层数
        _MieScatteringScalarHeight ("Mie Scattering Scalar Height", Float) = 1200.0
        // 贡献点采样次数
        _PointScatterCount ("Point Scatter Count", Float) = 100
        // AB段采样次数
        _ScatterCount ("Scatter Count", Float) = 100
        */
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			ZTest Off
			Cull Off
			ZWrite Off
			Blend Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Scattering.hlsl"
            #include "AtmosphereScattering.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord :TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                return o;
            }

            float2 frag (v2f i) : SV_Target
            {
                float cos = 0;
                float h =0;
                UvToDensity(i.uv, cos, h);
                float sin = sqrt(saturate(1 - cos * cos));
                float3 lightDir = float3(sin, cos, 0);
                float3 pos = float3(0, h, 0);

                return DensityCP(pos, lightDir);
            }
            ENDCG
        }
    }
}
