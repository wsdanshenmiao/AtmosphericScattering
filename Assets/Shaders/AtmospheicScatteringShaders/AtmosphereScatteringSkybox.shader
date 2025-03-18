Shader "Atmosphere/AtmosphereScatteringSkybox"
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
        Pass
        {
            Tags{ "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" }
    
            Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "Util.hlsl"
            #include "Scattering.hlsl"
            #include "AtmosphereScattering.hlsl"
            
            int _RenderSun;

            // 计算天空盒颜色
            float3 GetAtmosphereColor(float3 pos, float3 viewDir, float3 lightDir)
            {
                float3 sumRayleigh, sumMie;

            #define COMPUTELUT 1
            #if COMPUTELUT
                float3 coords;
                float3 normal = pos - _PlanetCenter.xyz;
                float height = length(normal) - _PlanetRadius;
                normal = normalize(normal);
                TransParametersTocoords(normal, lightDir, viewDir, height, coords);
                sumRayleigh = tex3D(_SumRayleighLut, coords).xyz;
                sumMie = tex3D(_SumMieLut, coords).xyz;
            #else
                Inscattering(pos, viewDir, lightDir, sumRayleigh, sumMie);
            #endif

                float cos = dot(viewDir, -lightDir);
                float3 rayleigh = RayleighCoefficient() * RayleighPhase(cos) * sumRayleigh * _RayleighScaling;
                float3 mie = MieCoefficient() * MiePhase(cos, _MieAnisotropy) * sumMie * _MieScaling;
                
                float3 skyColor = (rayleigh + mie) * _SunLightColor.xyz * _SunLightIntensity;
                if(_RenderSun == 1){
                    skyColor += RenderSun(sumMie, cos);
                }

                return skyColor;
            }
                

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 posW : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f vOut;
                vOut.pos = UnityObjectToClipPos(v.vertex);
                vOut.posW = mul(unity_ObjectToWorld, v.vertex).xyz;
                return vOut;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 cameraPos = _WorldSpaceCameraPos.xyz;
                float3 viewDir = normalize(i.posW);
                float3 lightDir = -_WorldSpaceLightPos0.xyz; // 方向光
                _PlanetCenter = (0, -_PlanetRadius, 0);

                float3 atmosphereColor = GetAtmosphereColor(cameraPos, viewDir, lightDir);
                
                return fixed4(atmosphereColor * _LightColor0.xyz, 1);
            }

            ENDCG
        }
    }
}