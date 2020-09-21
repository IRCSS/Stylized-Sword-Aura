Shader "Unlit/SwordAura"
{
    // ---------------------------------------------------------------------------------------
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AuraColorOne  ("Color", Color) = (1,1,1,1)
        _AuraColorTwo  ("Color", Color) = (1,1,1,1)
        _AuraColorThree("Color", Color) = (1,1,1,1)
        _AuraColorFour ("Color", Color) = (1,1,1,1)
    }
    // ---------------------------------------------------------------------------------------
    SubShader
    {
        // ____________________________________________________________________________________
        Tags  {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        LOD 100
        Cull   Off
        ZWrite Off 
        Blend SrcAlpha OneMinusSrcAlpha

        // ____________________________________________________________________________________
        Pass
        {
            CGPROGRAM
            #pragma vertex   vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // ================================
            // DECLARATIONS
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

            sampler2D _MainTex;           // This noise texture is used to add variation to the aura behaivour
            float4    _MainTex_ST;        // Unity boiler plate code
            float4    _AuraColorOne  ;    // used to styliz the color of the aura
            float4    _AuraColorTwo  ;    // used to styliz the color of the aura
            float4    _AuraColorThree;    // used to styliz the color of the aura
            float4    _AuraColorFour ;    // used to styliz the color of the aura

            // ================================
            // VERTEX SHADER
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv     = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // ================================
            // HELPER FUNCTIONS

            float sinOverLap(float x, float frequenceBase, float speedBase) 
            {
                float sum = 0.;

                for (float f = 1; f < 10; f++) {         // Add a bunch of waves on top of eachother with ever increasing frequency and decreasing amplitude

                 sum += sin(x * f *12. * frequenceBase +        _Time.y*1.2 * speedBase) / f 
                     +  cos(x * f *14. * frequenceBase + 0.15 + _Time.y*1.8 * speedBase) / f
                     +  cos(x * f *10. * frequenceBase + 0.3 +  _Time.y*1.6 * speedBase) / f;
                }

                return sum/10.;
            }

            // ================================

            fixed4 frag (v2f i) : SV_Target
            {
                float4 col     = float4(0.,0.,0.,0.);
                float2 coord   = float2(i.uv);                             // Save this for manipulation
                float  side    = coord.y * 2.0 - 1.0;                      // This divides the plane in two, instead of the coordinates going from button to the top, they go from the middles to the edges in the y axis
                float3 noise   = tex2D(_MainTex, 
                                       float2(i.uv.x*3. + _Time.y*0.1,     // panning the texture in the x direction. the *3 makes the tiling tighter
                                       i.uv.y + max(0., (sign(side)))*0.5  // For the upper half of the plane, offset the noise. This breaks the symmery between the lower and upper part of the aura of the sword
                                       + _Time.y*(sign(side)*-0.1)));      // Pan the noise in the y direction. Below the sword pan it down, above it pan it up
                       coord.y = abs(side);                                // From this point on, treat the lower and upper part the same, baiscily symmetry. The side variable is used later whenever it is nessery to differentiate between the upper and lower half
                       coord.x = 1. - coord.x;                             // My uv was going from right to left, I flipped it so that it goes from the hilt of the sword to the tip

                //--------------------
                // Base aura shape

                float  auraOn  =  pow(coord.x,1.35);                       // The uv goes between 0-1. This causes the 0.5 to shift to the left a bit and causes a curvy like distortation
                       auraOn  =  abs(frac(auraOn + 0.5) - 0.5)*0.7;       // This creates a triangle around the sword
                       auraOn +=  smoothstep(0.25, 1.0, (1.-coord.x))*0.4; // This creates the round shape around the hilt of the sword
                       auraOn -=  smoothstep(0.,0.2,                       // This creates the sharp edge of the aura at the end of the tip. The 0. to 0.2 area on a flipped x coordinate are the area where this effect is active
                                  (max(0., (1.-coord.x) - 0.85)));         // The -0.85 and max ensure that this function returns zero on the rest of the sword, where the sharp aura part of the effect is irrelavant
                
                //--------------------
                // Wave effect
                       auraOn += (abs(sinOverLap(i.uv.x -                  // Creates the wave effect, which comes on top of the based aura shape defined above   
                           (noise.x *0.05 * smoothstep(0.9, 0.8 , i.uv.x)) // This makes the noise texture being less active and moving on the hilt of the sword
                           + max(0., (sign(side)))*0.5 , 2.18, 1.))        // Differentating between the lower and upper part to add some variation
                           + (noise.x*0.02 * smoothstep(0.9, 0.8, i.uv.x)) // Same as above, add the noise for variation, but make it less wavy and curly on the hilt of the sword
                           )*smoothstep(0., 1., i.uv.x)*1.5                // Reduce the whole effect on the tip of the sword so that the aura there remains sharp
                           * smoothstep(0.9, 0.8, i.uv.x);                 // Reduce the whole effect, on the tilt, so that it looks more soft and smooky, the two lines basicly make the effect strongest on the blade
                       
                       float dis = abs((coord.y - auraOn));                // This is used for coloring, how far off are you from the edge of the aura

                       auraOn  =  smoothstep(auraOn- abs(
                                             (sinOverLap(i.uv.x + 0.1 +    // This is the part that makes the aura soft on some areas and hard on others. 
                                              noise.x *0.1, 1.2, 1.2))     // The noise varies for different y in the same x, this cause the softness to also have some twirly, rotating effect
                                              *0.7 + noise.x*0.5)          // Again use the noise directly to soften certain areas
                                              *smoothstep(0., 1., i.uv.x), // Simlar as above, make sure the tip of the blade is always sharp, and that it gets softer the closer you getto the hilt
                                             auraOn ,                      // This is where the actual drawing of the aura happens, This is baisicly a visualsation of the area under the function auraOn
                                             coord.y);


                //--------------------
                // Coloring
                // I actually wnated to make a bunch of orthonormal functions bases, with zero inner products
                // This would make it so that each color would define a range of distance to the value of the auraOn 
                // function for that coord.x, however I like how the sword looks atm, so I left it like this

                col.xyz = _AuraColorOne   * (sin(dis*2.5 + _Time.y*0.2)      *0.5 + 0.5) +
                          _AuraColorTwo   * (cos(dis*3.9+0.521 + _Time.y*0.6)*0.5 + 0.5) +
                          _AuraColorThree * (sin(1.5* dis +0.1 +_Time.y*0.7) *0.5 + 0.5) + 
                          _AuraColorFour  * (sin(2.5* dis +0.3 +_Time.y*1.5) *0.5 + 0.5) ;
                col.a   = 1.-auraOn;
                return col;
            }
            ENDCG
        }
    }
    // ---------------------------------------------------------------------------------------
}
