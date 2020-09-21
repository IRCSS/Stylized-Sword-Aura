Shader "Unlit/SwordAura"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AuraColorOne  ("Color", Color) = (1,1,1,1)
        _AuraColorTwo  ("Color", Color) = (1,1,1,1)
        _AuraColorThree("Color", Color) = (1,1,1,1)
        _AuraColorFour ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags  {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        LOD 100
        Cull   Off
        ZWrite Off 
        Blend SrcAlpha OneMinusSrcAlpha


        Pass
        {
            CGPROGRAM
            #pragma vertex   vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv     : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4    _MainTex_ST;
            float4    _AuraColorOne  ;
            float4    _AuraColorTwo  ;
            float4    _AuraColorThree;
            float4    _AuraColorFour ;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv     = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float sinOverLap(float x, float frequenceBase, float speedBase) 
            {
                float sum = 0.;

                for (float f = 1; f < 10; f++) {

                 sum += sin(x * f *12. * frequenceBase +        _Time.y*1.2 * speedBase) / f 
                     +  cos(x * f *14. * frequenceBase + 0.15 + _Time.y*1.8 * speedBase) / f
                     +  cos(x * f *10. * frequenceBase + 0.3 +  _Time.y*1.6 * speedBase) / f;
                }

                return sum/10.;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 col     = float4(0.,0.,0.,0.);
                float2 coord   = float2(i.uv);
                float  side    = coord.y * 2.0 - 1.0;
                float3 noise   = tex2D(_MainTex, float2(i.uv.x*3. + _Time.y*0.1, i.uv.y + max(0., (sign(side)))*0.5 + _Time.y*(sign(side)*-0.1)));
                       coord.y = abs(side);
                       coord.x = 1. - coord.x;

                float  auraOn  =  pow(coord.x,1.35);
                       auraOn  =  abs(frac(auraOn + 0.5) - 0.5)*0.7;
                       auraOn +=  smoothstep(0.25, 1.0, (1.-coord.x))*0.4;
                       auraOn -=  smoothstep(0.,0.2,(max(0., (1.-coord.x) - 0.85)));
                
                       auraOn += (abs(sinOverLap(i.uv.x -   
                           (noise.x *0.05 * smoothstep(0.9, 0.8 , i.uv.x)) + max(0., (sign(side)))*0.5
                           , 2.18, 1.))+ (noise.x*0.02* smoothstep(0.9, 0.8, i.uv.x))
                           )*smoothstep(0., 1., i.uv.x)*1.5* smoothstep(0.9, 0.8, i.uv.x);
                       
                       float dis = abs((coord.y - auraOn));

                       auraOn  =  smoothstep(auraOn- 
                                             abs((sinOverLap(i.uv.x + 0.1  + 
                                                 noise.x *0.1, 1.2, 1.2))*0.7 + noise.x*0.5)
                                                 *smoothstep(0., 1., i.uv.x),
                                             auraOn ,
                                             coord.y);


                

                col.xyz = _AuraColorOne   * (sin(dis*2.5 + _Time.y*0.2)      *0.5 + 0.5)     +
                          _AuraColorTwo   * (cos(dis*3.9+0.521 + _Time.y*0.6)*0.5 + 0.5)     +
                          _AuraColorThree * (sin(1.5* dis +0.1 +_Time.y*0.7) *0.5 + 0.5)     + 
                          _AuraColorFour  * (sin(2.5* dis +0.3 +_Time.y*1.5) *0.5 + 0.5)     ;
                col.a   = 1.-auraOn;
                return col;
            }
            ENDCG
        }
    }
}
