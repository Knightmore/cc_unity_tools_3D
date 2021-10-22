Shader "Reallusion/RL_CorneaShader_3D"
{
    Properties
    {
        _ScleraDiffuseMap("Sclera Diffuse Map", 2D) = "white" {}
        _CorneaDiffuseMap("Cornea Diffuse Map", 2D) = "white" {}
        _ColorBlendMap("Color Blend Map", 2D) = "grey" {}
        _MaskMap("Mask Map", 2D) = "gray" {}        
        _AOStrength("Ambient Occlusion Strength", Range(0,1)) = 0.2
        _IrisNormalMap("Iris Normal Map", 2D) = "bump" {}
        _IrisNormalStrength("Iris Normal Strength", Range(0,2)) = 0
        _ScleraNormalMap("Sclera Normal Map", 2D) = "bump" {}
        _ScleraNormalStrength("Sclera Normal Strength", Range(0,1)) = 0.1
        _ScleraNormalTiling("Sclera Normal Tiling", Range(1,10)) = 2        
        _ScleraScale("Sclera Scale", Range(0.25,2)) = 1
        _ScleraHue("Sclera Hue", Range(0,1)) = 0.5
        _ScleraSaturation("Sclera Saturation", Range(0,2)) = 1
        _ScleraBrightness("Sclera Brightness", Range(0,2)) = 0.75
        _IrisScale("Iris Scale", Range(0.25,2)) = 1
        _IrisHue("Iris Hue", Range(0,1)) = 0.5
        _IrisSaturation("Iris Saturation", Range(0,2)) = 1
        _IrisBrightness("Iris Brightness", Range(0,2)) = 1
        _PupilScale("Pupil Scale", Range(0.25,10)) = 0.8
        _IrisRadius("Iris Radius", Range(0.01,0.2)) = 0.15
        _LimbusWidth("Limbus Width", Range(0.01,0.1)) = 0.055
        _LimbusDarkRadius("Limbus Dark Radius", Range(0.01,0.2)) = 0.1
        _LimbusDarkWidth("Limbus Dark Width", Range(0.01,0.1)) = 0.025
        _LimbusColor("Limbus Color", Color) = (0,0,0,0)
        _ShadowRadius("Shadow Radius", Range(0,0.5)) = 0.275
        _ShadowHardness("Shadow Hardness", Range(0.01,0.99)) = 0.5
        _CornerShadowColor("Corner Shadow Color", Color) = (1,0.7333333,0.6980392,1)
        _ColorBlendStrength("Color Blend Strength", Range(0,1)) = 0.2
        _ScleraSmoothness("Sclera Smoothness", Range(0,1)) = 0.8
        _CorneaSmoothness("Cornea Smoothness", Range(0,1)) = 1
        _IrisSmoothness("Iris Smoothness", Range(0,1)) = 0
        _IOR("IOR", Range(1,2)) = 1.4
        _RefractionThickness("Refraction Thickness", Range(0,0.025)) = 0.01
        _IrisDepth("Iris Depth", Range(0,1)) = 0
        _DepthRadius("Depth Radius", Range(0,1)) = 0.8
        _EmissionMap("Emission Map", 2D) = "black" {}
        _EmissiveColor("Emissive Color", Color) = (0,0,0,0)
        [ToggleUI]_IsLeftEye("Is Left Eye", Float) = 0
        [Toggle]BOOLEAN_ISCORNEA("IsCornea", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _ScleraDiffuseMap;
        sampler2D _CorneaDiffuseMap;
        sampler2D _ColorBlendMap;
        sampler2D _MaskMap;
        sampler2D _IrisNormalMap;
        sampler2D _ScleraNormalMap;
        sampler2D _EmissionMap;

        struct Input
        {
            float2 uv_MainTex;
        };
        
        half _AOStrength;
        half _IrisNormalStrength;
        half _ScleraNormalStrength;
        half _ScleraNormalTiling;
        half _ScleraScale;
        half _ScleraHue;
        half _ScleraSaturation;
        half _ScleraBrightness;
        half _IrisScale;
        half _IrisHue;
        half _IrisSaturation;
        half _IrisBrightness;
        half _PupilScale;
        half _IrisRadius;
        half _LimbusWidth;
        half _LimbusDarkRadius;
        half _LimbusDarkWidth;
        fixed4 _LimbusColor;
        half _ShadowRadius;
        half _ShadowHardness;
        fixed4 _CornerShadowColor;
        half _ColorBlendStrength;
        half _ScleraSmoothness;
        half _CorneaSmoothness;
        half _IrisSmoothness;
        half _IOR;
        half _RefractionThickness;
        half _IrisDepth;
        half _DepthRadius;        
        fixed4 _EmissiveColor;
        half _IsLeftEye;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        fixed4 HSV(fixed4 rgba, half hue, half saturation, half brightness)
        {
            // HUE
            half3 c = rgba.rgb;
            // this expects the h offset in normalized form i.e. 0.0 - 1.0, with 0.5 being no offset.
            hue = hue * 360.0 - 180.0;
            half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            half4 P = lerp(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
            half4 Q = lerp(half4(P.xyw, c.r), half4(c.r, P.yzx), step(P.x, c.r));
            half D = Q.x - min(Q.w, Q.y);
            half E = 1e-10;
            half3 hsv = half3(abs(Q.z + (Q.w - Q.y) / (6.0 * D + E)), D / (Q.x + E), Q.x);

            half h = hsv.x + hue / 360.0;
            hsv.x = (h < 0)
                ? h + 1
                : (h > 1)
                ? h - 1
                : h;

            half4 K2 = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            half3 P2 = abs(frac(hsv.xxx + K2.xyz) * 6.0 - K2.www);
            c = hsv.z * lerp(K2.xxx, saturate(P2 - K2.xxx), hsv.y);

            // SATURATION
            half luma = dot(c, half3(0.2126729, 0.7151522, 0.0721750));
            c = luma.xxx + saturation.xxx * (c - luma.xxx);

            // LIGHTNESS
            rgba.rgb = c * brightness;
            return rgba;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            half4 mask = tex2D(_MaskMap, IN.uv_MainTex);
            half irisRadius = _IrisScale * _IrisRadius;
            half limbusWidth = _IrisScale * _LimbusWidth;
            half radial = length(IN.uv_MainTex.xy - half2(0.5, 0.5));
            half scleraMask = smoothstep(irisRadius - limbusWidth, irisRadius, radial);
            half irisMask = 1 - scleraMask;
            half depthRadius = irisRadius * _DepthRadius;
            half depthMask = saturate(1 - radial / depthRadius);
            
            // Base Color
            half pupilScale = _PupilScale * _IrisScale;
            half corneaTiling = 1.0 / lerp(_IrisScale, pupilScale, depthMask);
            half corneaOffset = half2(0.5, 0.5) * (1 - corneaTiling);

            fixed4 cornea = HSV(tex2D(_CorneaDiffuseMap, IN.uv_MainTex * corneaTiling + corneaOffset), 
                                _IrisHue, _IrisSaturation, _IrisBrightness);

            half limbusDarkRadius = _LimbusDarkRadius * _IrisScale;
            half limbusDarkWidth = _LimbusDarkWidth * _IrisScale;
            half limbusMask = smoothstep(limbusDarkRadius, limbusDarkRadius + limbusDarkWidth, radial);

            cornea = lerp(cornea, _LimbusColor, limbusMask);

            half scleraTiling = 1.0 / _ScleraScale;
            half2 scleraOffset = half2(0.5, 0.5) * (1 - scleraTiling);

            fixed4 sclera = HSV(tex2D(_ScleraDiffuseMap, IN.uv_MainTex * scleraTiling + scleraOffset),
                                _ScleraHue, _ScleraSaturation, _ScleraBrightness);

            half shadowRadius = _ShadowRadius * _ScleraScale;
            half shadowMask = smoothstep(shadowRadius * _ShadowHardness, shadowRadius, radial);

            sclera = lerp(sclera, _CornerShadowColor * sclera, shadowMask);

            fixed4 c = lerp(sclera, cornea, irisMask);

            half4 blend = tex2D(_ColorBlendMap, IN.uv_MainTex);
            c = lerp(c, c * blend, _ColorBlendStrength);
            
            // Smoothness
            half smoothness = lerp(_ScleraSmoothness, _CorneaSmoothness, irisMask);

            // remap AO
            half ao = lerp(1.0, mask.g, _AOStrength);

            // Sclera Normal
            half3 scleraNormal = UnpackNormal(tex2D(_ScleraNormalMap, IN.uv_MainTex * _ScleraNormalTiling));
            // apply micro normal strength
            half detailMask = _ScleraNormalStrength * scleraMask;
            scleraNormal = half3(scleraNormal.xy * detailMask, lerp(1, scleraNormal.z, saturate(detailMask)));            

            // outputs
            o.Albedo = c.rgb * ao;
            o.Metallic = mask.r;
            o.Smoothness = smoothness;
            o.Normal = scleraNormal;
            o.Alpha = 1.0;
        }        
        ENDCG
    }
    FallBack "Diffuse"
}
