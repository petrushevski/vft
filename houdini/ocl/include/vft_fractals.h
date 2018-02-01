#ifndef _VFT_FRACTALS
#define _VFT_FRACTALS

// mapping of variables
// aux.r_dz -> dr
// aux.r -> r
// dr -> de
// r -> distance
// Bailout -> max_distance
// Iterations -> max_iterations
// positive log_lin -> log, negative -> lin

// fractal formula sources:
// [M2] - Mandelbulber v2
// [M3D] - Mandelbulb 3D
// [WEB] - From the web

////////////// primitives
// [WEB] - http://iquilezles.org/www/articles/distfunctions/distfunctions.htm

// sphere: position, radius, center
static float sphere( float3 P, float rad, float3 center )
{
    float dist = length(P - center) - rad;
    return dist;
}

// box: position, size
static float box( float3 P, float3 b )
{
  float3 d = fabs(P) - b;
  return min( max( d.x, max(d.y, d.z) ), 0.0f) + length( max(d, 0.0f) );
}

// round box: position, size, roundness
static float roundBox( float3 P, float3 b, float r )
{
  return length( max( fabs(P) - b, 0.0f ) )-r;
}

// torus: position, size (radius, thickness)
static float torus( float3 P, float2 t )
{
  float2 q = (float2)(length(P.xz)-t.x,P.y);
  return length(q)-t.y;
}

// infinite cone
static float cone( float3 P, float2 c )
{
    c = normalize(c);
    float q = length(P.xy);
    return dot( c, (float2)(q, P.z) );
}


////////////// fractals

// [WEB] - http://blog.hvidtfeldts.net/index.php/2011/09/
static void mandelbulbIter(float3* Z, float* de, const float3* P_in, int* log_lin, const float weight, const float4 julia, const float power)
{
    float3 Z_orig = *Z;
    float de_orig = *de;
    
    float distance = length(*Z);

    // convert to polar coordinates
    float theta = acos(Z->z/distance);
    float phi = atan2(Z->y, Z->x);

    *de =  pow(distance, power-1) * power * (*de) + 1;
    
    // scale and rotate the point
    float zr = pow(distance, power);
    theta *= power;
    phi *= power;
    
    // convert back to cartesian coordinates
    float3 newZ = zr * (float3)( sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta) );

    if (julia.x == 0)
    {
        *Z = newZ + *P_in;
    }
    else {
        *Z = newZ + julia.yzw;
    }

    *Z = mix(Z_orig, *Z, weight);
    *de = mix(de_orig, *de, weight);
    (*log_lin)++;
}

// [WEB] - http://www.fractalforums.com/index.php?topic=2785.msg14893#msg14893
static void mandelboxIter(float3* Z, float* de, const float3* P_in, int* log_lin, const float weight, const float4 julia, const float scale)
{
    float3 Z_orig = *Z;
    float de_orig = *de;
    
    float distance = length(*Z);

    float fixedRadius = 1.0;
    float fR2 = fixedRadius * fixedRadius;
    float minRadius = 0.5;
    float mR2 = minRadius * minRadius;

    if (Z->x > 1.0) Z->x = 2.0 - Z->x;
    else if (Z->x < -1.0) Z->x = -2.0 - Z->x;

    if (Z->y > 1.0) Z->y = 2.0 - Z->y;
    else if (Z->y < -1.0) Z->y = -2.0 - Z->y;

    if (Z->z > 1.0) Z->z = 2.0 - Z->z;
    else if (Z->z < -1.0) Z->z = -2.0 - Z->z;

    float r2 = Z->x*Z->x + Z->y*Z->y + Z->z*Z->z;

    if (r2 < mR2)
    {
        *Z = *Z * fR2 / mR2;
        *de = *de * fR2 / mR2;
    }
    else if (r2 < fR2)
    {
        *Z = *Z * fR2 / r2;
        *de *= fR2 / r2;
    }

    *de *= scale;

    if (julia.x == 0)
    {
        *Z = *Z * scale + *P_in;
    }
    else
    {
        *Z = *Z * scale + julia.yzw;
    }

    *Z = mix(Z_orig, *Z, weight);
    *de = mix(de_orig, *de, weight);
    (*log_lin)--;
}

// [M2] - Classic Mandelbulb Power 2 fractal - MandelbulbPower2Iteration
static void mandelbulbPower2Iter(float3* Z, float* de, const float3* P_in, int* log_lin, const float weight, const float4 julia) 
{
    float3 Z_orig = *Z;
    float de_orig = *de;
    
    float distance = length(*Z);

    *de = *de * 2.0f * distance;
    float x2 = Z->x * Z->x;
    float y2 = Z->y * Z->y;
    float z2 = Z->z * Z->z;
    float temp = 1.0 - z2 / (x2 + y2);
    float3 new;
    new.x = (x2 - y2) * temp;
    new.y = 2.0 * Z->x * Z->y * temp;
    new.z = -2.0 * Z->z * sqrt(x2 + y2);

    if (julia.x == 0)
    {
        *Z = new + *P_in;
    }
    else
    {
        *Z = new + julia.yzw;
    }

    *Z = mix(Z_orig, *Z, weight);
    *de = mix(de_orig, *de, weight);
    (*log_lin)++;
}

// [M2] - Menger Sponge formula created by Knighty - MengerSpongeIteration
static void mengerSpongeIter(float3* Z, float* de, const float3* P_in, int* log_lin, const float weight, const float4 julia)
{
    float3 Z_orig = *Z;
    float de_orig = *de;
    
    float distance = length(*Z);

    Z->x = fabs(Z->x);
    Z->y = fabs(Z->y);
    Z->z = fabs(Z->z);

    if (Z->x - Z->y < 0.0f) Z->xy = Z->yx;
    if (Z->x - Z->z < 0.0f) Z->xz = Z->zx;
    if (Z->y - Z->z < 0.0f) Z->yz = Z->zy;

    *Z *= 3.0f;

    Z->x -= 2.0f;
    Z->y -= 2.0f;
    if (Z->z > 1.0f) Z->z -= 2.0f;

    *de *= 3.0;

    if (julia.x == 1)
    {
        *Z += julia.yzw;
    }

    *Z = mix(Z_orig, *Z, weight);
    *de = mix(de_orig, *de, weight);
    (*log_lin)--;
}

// [M2] - Bristorbrot formula - BristorbrotIteration
static void bristorbrotIter(float3* Z, float* de, const float3* P_in, int* log_lin, const float weight, const float4 julia)
{
    float3 Z_orig = *Z;
    float de_orig = *de;
    
    float distance = length(*Z);

    float3 new;
    new.x = Z->x * Z->x - Z->y * Z->y - Z->z * Z->z;
    new.y = Z->y * (2.0f * Z->x - Z->z);
    new.z = Z->z * (2.0f * Z->x + Z->y);
    
    *de = *de * 2.0f * distance;
    *Z = new;

    if (julia.x == 0)
    {
        *Z += *P_in;
    }
    else {
        *Z += julia.yzw;
    }

    *Z = mix(Z_orig, *Z, weight);
    *de = mix(de_orig, *de, weight);
    (*log_lin)++;
}

// [M2] - Xenodreambuie - XenodreambuieIteration
static void xenodreambuieIter(float3* Z, float* de, const float3* P_in, int* log_lin, const float weight, const float4 julia, const float power, float alpha, float beta)
{
    float3 Z_orig = *Z;
    float de_orig = *de;
    
    float distance = length(*Z);

    alpha = radians(alpha);
    beta = radians(beta);

    float rp = pow(distance, power - 1.0f);
    *de = rp * (*de) * power + 1.0f;
    rp *= distance;

    float th = atan2(Z->y, Z->x) + beta;
    float ph = acos(Z->z / distance) + alpha;

    if (fabs(ph) > 0.5f * M_PI_F) ph = sign(ph) * M_PI_F - ph;

    Z->x = rp * cos(th * power) * sin(ph * power);
    Z->y = rp * sin(th * power) * sin(ph * power);
    Z->z = rp * cos(ph * power);

    if (julia.x == 0)
    {
        *Z += *P_in;
    }
    else {
        *Z += julia.yzw;
    }

    *Z = mix(Z_orig, *Z, weight);
    *de = mix(de_orig, *de, weight);
    (*log_lin)++;
}

// [M2] - Sierpinski3D. made from Darkbeam's Sierpinski code from M3D - Sierpinski3dIteration
static void sierpinski3dIter(float3* Z, float* de, const float3* P_in, int* log_lin, const float weight, const float4 julia, const float scale, const float3 offset, const float3 rot)
{
    float3 Z_orig = *Z;
    float de_orig = *de;
    
    float distance = length(*Z);

    float3 temp = *Z;

    if (Z->x - Z->y < 0.0f) Z->xy = Z->yx;
    if (Z->x - Z->z < 0.0f) Z->xz = Z->zx;
    if (Z->y - Z->z < 0.0f) Z->yz = Z->zy;
    if (Z->x + Z->y < 0.0f)
    {
        temp.x = -Z->y;
        Z->y = -Z->x;
        Z->x = temp.x;
    }
    if (Z->x + Z->z < 0.0f)
    {
        temp.x = -Z->z;
        Z->z = -Z->x;
        Z->x = temp.x;
    }
    if (Z->y + Z->z < 0.0f)
    {
        temp.y = -Z->z;
        Z->z = -Z->y;
        Z->y = temp.y;
    }

    *Z *= scale;
    *de *= scale;

    *Z -= offset;

    *Z = mtxPtMult( mtxRotate(rot) , *Z );

    if (julia.x == 1)
    {
        *Z += julia.yzw;
    }

    *Z = mix(Z_orig, *Z, weight);
    *de = mix(de_orig, *de, weight);
    (*log_lin)--;
}



#endif