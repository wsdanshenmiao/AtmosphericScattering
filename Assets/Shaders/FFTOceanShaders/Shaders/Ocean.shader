Shader "Unlit/Ocean"
{
    Properties
    {
        _Color("海浪颜色", Color) = (0,0,1,1)
        _FoamColor("泡沫颜色", Color) = (1,1,1,1)

        [Header(Cascade 0)]
        [HideInInspector]_Displacement_c0("Displacement C0", 2D) = "black" {}
        [HideInInspector]_Derivatives_c0("Derivatives C0", 2D) = "black" {}
        [HideInInspector]_Turbulence_c0("Turbulence C0", 2D) = "white" {}
        [Header(Cascade 1)]
        [HideInInspector]_Displacement_c1("Displacement C1", 2D) = "black" {}
        [HideInInspector]_Derivatives_c1("Derivatives C1", 2D) = "black" {}
        [HideInInspector]_Turbulence_c1("Turbulence C1", 2D) = "white" {}
        [Header(Cascade 2)]
        [HideInInspector]_Displacement_c2("Displacement C2", 2D) = "black" {}
        [HideInInspector]_Derivatives_c2("Derivatives C2", 2D) = "black" {}
        [HideInInspector]_Turbulence_c2("Turbulence C2", 2D) = "white" {}
    }
        SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Opaque" }
        LOD 200

        CGPROGRAM
        #pragma multi_compile _ MID CLOSE
        //#pragma surface surf Standard fullforwardshadows vertex:vert addshadow
        #pragma surface surf Standard vertex:vert
        #pragma target 4.0


        struct Input
        {
            float2 worldUV;
            float4 lodScales;
            float3 viewVector;
            float3 worldNormal;
            float4 screenPos;
            INTERNAL_DATA
        };

        sampler2D _Displacement_c0;
        sampler2D _Derivatives_c0;
        sampler2D _Turbulence_c0;

        sampler2D _Displacement_c1;
        sampler2D _Derivatives_c1;
        sampler2D _Turbulence_c1;

        sampler2D _Displacement_c2;
        sampler2D _Derivatives_c2;
        sampler2D _Turbulence_c2;

        float LengthScale0;
        float LengthScale1;
        float LengthScale2;
        float _SSSBase;

        void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
            float4 worldUV = float4(worldPos.xz, 0, 0);
            o.worldUV = worldUV.xy;

            o.viewVector = _WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz;
            float viewDist = length(o.viewVector);
            
            float lod_c0 = min(LengthScale0 / viewDist, 1);
            float lod_c1 = min(LengthScale1 / viewDist, 1);
            float lod_c2 = min(LengthScale2 / viewDist, 1);
            

            float3 displacement = 0;
            float largeWavesBias = 0;

            
            displacement += tex2Dlod(_Displacement_c0, worldUV / LengthScale0) * lod_c0;
            largeWavesBias = displacement.y;
            displacement += tex2Dlod(_Displacement_c1, worldUV / LengthScale1) * lod_c1;
            displacement += tex2Dlod(_Displacement_c2, worldUV / LengthScale2) * lod_c2;
            v.vertex.xyz += mul(unity_WorldToObject,displacement);

            o.lodScales = float4(lod_c0, lod_c1, lod_c2, max(displacement.y - largeWavesBias * 0.8, 0) /4);
        }

        fixed4 _Color, _FoamColor = (1,1,1,1);
        sampler2D _CameraDepthTexture;
        sampler2D _FoamTexture;

        // 计算从世界空间法线到切线空间法线的转换向量
        float3 WorldToTangentNormalVector(Input IN, float3 normal) {
            float3 t2w0 = WorldNormalVector(IN, float3(1, 0, 0));
            float3 t2w1 = WorldNormalVector(IN, float3(0, 1, 0));
            float3 t2w2 = WorldNormalVector(IN, float3(0, 0, 1));
            float3x3 t2w = float3x3(t2w0, t2w1, t2w2);
            return normalize(mul(t2w, normal));
        }

        float pow5(float f)
        {
            return f * f * f * f * f;
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float4 derivatives = tex2D(_Derivatives_c0, IN.worldUV / LengthScale0);
            derivatives += tex2D(_Derivatives_c1, IN.worldUV / LengthScale1) * IN.lodScales.y;

            derivatives += tex2D(_Derivatives_c2, IN.worldUV / LengthScale2) * IN.lodScales.z;

            float2 slope = float2(derivatives.x / (1 + derivatives.z),
                derivatives.y / (1 + derivatives.w));
            float3 worldNormal = normalize(float3(-slope.x, 1, -slope.y));

            o.Normal = WorldToTangentNormalVector(IN, worldNormal);
            
            float j = tex2D(_Turbulence_c0, IN.worldUV / LengthScale0).x
                + tex2D(_Turbulence_c1, IN.worldUV / LengthScale1).x
                + tex2D(_Turbulence_c2, IN.worldUV / LengthScale2).x;
            j = min(1, max(0, -j + 1 ));

            float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
            float backgroundDepth =
                LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));
            float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(IN.screenPos.z);
            float depthDifference = max(0, backgroundDepth - surfaceDepth - 0.1);
            float foam = tex2D(_FoamTexture, IN.worldUV * 0.5 + _Time.r).r;
            j += saturate(max(0, foam - depthDifference) * 5) * 0.9;

            o.Albedo = lerp(0, _FoamColor, j);
            float distanceGloss = lerp(1 , 0, 1 / (1 + length(IN.viewVector) * 0.1));
            o.Smoothness = lerp(distanceGloss, 0, j);
            o.Metallic = 0;

            float3 viewDir = normalize(IN.viewVector);
            float3 H = normalize(-worldNormal + _WorldSpaceLightPos0);

            float f = dot(worldNormal, viewDir);
            f = saturate(1 - f);
            f = pow5(f);

            o.Emission = lerp(_Color * (1 - f), 0, j);
        }
        ENDCG
    }
        FallBack "Diffuse"
}