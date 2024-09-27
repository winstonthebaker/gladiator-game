Shader "Unlit/Test"
{
    Properties
    {
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _WaterColor ("Water Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _FogMultiplier ("Fog Multiplier", float) = 0.1
        _DepthMultiplier ("Depth Multiplier", float) = 0.1
        _ViewDistance ("View distance", float) = 40.0
        _SpecColor ("Specular Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _Shininess ("Shininess", float) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            //User Defined
            uniform float4 _Color;
            uniform float4 _WaterColor;
            uniform float _FogMultiplier;
            uniform float _DepthMultiplier;
            uniform float4 _SpecColor;
            uniform float _Shininess;
            uniform float _ViewDistance;
            //Unity defined
            uniform float4 _LightColor0;
            

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 posWorld : TEXCOORD0;
                float3 normalDir : TEXCOORD1;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.pos = UnityObjectToClipPos(v.vertex);



                return o;
            }

            float3 falloff(float3 col, float3 waterCol, float dist, float d){

                float depth = max(0.0, dist);
                float3 colorFactor = (float3(1.0, 1.0, 1.0) - waterCol);
                float r = col.r * 1.0/(exp(pow(dist * colorFactor.r * d, 2)));
                float g = col.g * 1.0/(exp(pow(dist * colorFactor.g * d, 2)));
                float b = col.b * 1.0/(exp(pow(dist * colorFactor.b * d, 2)));
                return float3(r, g, b);

            }

            float3 scaleTo1(float3 col){
                float maxComponent = max(col.r, (max(col.g, col.b)));
                return col/maxComponent;
            }

            float4 frag (v2f i) : COLOR
            {
                float3 normalDir = normalize(i.normalDir);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);
                float distanceToCam = min(_ViewDistance, length(_WorldSpaceCameraPos - i.posWorld.xyz));

                float3 viewEndPos = _WorldSpaceCameraPos+ (-viewDir * _ViewDistance);
                float viewEndPosWaterDepth = max(0.0, 0.0-viewEndPos.y);

                float3 colorAtViewEnd = falloff(_WaterColor, _WaterColor, viewEndPosWaterDepth, _DepthMultiplier);



                float fogFactor = 1.0 - 1.0/(exp(pow(distanceToCam * _FogMultiplier, 2)));

                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                float atten = 1.0;

                float3 diffuseReflection = atten * _LightColor0.xyz * saturate(dot(normalDir, lightDir));
                float3 specularReflection = atten * _LightColor0.xyz * saturate(dot(normalDir, lightDir)) * pow(1.0 + saturate(dot((reflect(-lightDir, normalDir)), viewDir)), _Shininess * 0.1);

                float3 ambientLighting = ShadeSH9(float4(normalize(normalDir.xyz), 1.0));
                float3 lightFinal = (diffuseReflection + specularReflection + ambientLighting)/3.0;

                float waterDepth = max(0.0, 0.0 - i.posWorld.y);
                
                
                float3 colorFinal = _Color * falloff(lightFinal, _WaterColor, waterDepth, _DepthMultiplier);
                float3 colorFog = lerp(colorFinal, colorAtViewEnd, fogFactor);
                return float4(colorFog, 1.0);
            }
            ENDHLSL
        }
    }
}
