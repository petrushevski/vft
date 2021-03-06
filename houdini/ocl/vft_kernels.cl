/*
-----------------------------------------------------------------------------
This source file has been developed within the scope of the
Technical Director course at Filmakademie Baden-Wuerttemberg.
http://technicaldirector.de
    
Written by Juraj Tomori.
Copyright (c) 2019 Animationsinstitut of Filmakademie Baden-Wuerttemberg
-----------------------------------------------------------------------------
*/

#include "xnoise.h"
#include "vft_defines.h"
#include "vft_utils.h"
#include "vft_math.h"
#include "vft_fractals.h"
#include "vft_shading.h"

// contains primitives 
float primitive_stack(float3 P, const int stack)
{
    float out_distance;
    switch (stack)
    {
        case 0:
        {
            out_distance = sphere(P, 1.0f);

            break;
        }
        case 1:
        {
            out_distance = torus(P, (float2)(1.0f, 0.5f));

            break;
        }
    }

    return out_distance;
}

void pre_transform_stack(float3* Z, global const void* theXNoise)
{
    #define PY_PRE_TRANSFORM_STACK
}

// contains fractal combinations for all shapes
void fractal_stack(float3* Z, float* de, const float3* P_in, int* log_lin, const int stack, global const void* theXNoise)
{
    switch (stack)
    {
        case 0:
        {
            iqBulbIter(Z, de, P_in, log_lin, 1.0f, (float4)(0.0f, 0.0f, 0.0f, 0.0f), 8.0f, 8.0f);
            //idesIter(Z, de, P_in, log_lin, 1.0f, (float4)(0.0f, 0.0f, 0.0f, 0.0f), (float3)(1.0f, 2.0f, 1.0f), (float2)(0.5f, 0.5f));
            //benesiIter(Z, de, P_in, log_lin, 1.0f, (float4)(0.0f, 0.0f, 0.0f, 0.0f));
            //hypercomplexIter(Z, de, P_in, log_lin, 1.0f, (float4)(0.0f, 0.0f, 0.0f, 0.0f));            
            //josKleinianIter(Z, de, P_in, log_lin, 1.0f, (float4)(0.0f, 1.0f, 1.0f, 3.0f), 2.0f, 0.0f, (float3)(1.0f, 1.0f, 1.0f));            
            //amazingSurfIter(Z, de, P_in, log_lin, 1.0f, (float4)(1.0f, 0.0f, 0.0f, 0.0f), 1.0f, 1.0f, 0, 0.5f, 2.0f, 1.0f, (float3)(0.0f, 0.0f, 0.0f), 1, (float3)(1.0f, 1.0f, 1.0f));
            //mandelbulbPower2Iter(Z, de, P_in, log_lin, 1.0f, (float4)(1.0f, 0.3f, 0.5f, 0.2f)); // log
            //bristorbrotIter(Z, de, P_in, log_lin, 1.0f, (float4)(0.0f, 1.3f, 3.3f, 0.0f)); // log
            //xenodreambuieIter(Z, de, P_in, log_lin, 1.0f, (float4)(1.0f, 1.0f, 0.0f, 0.0f), 9.0f, 0.0f, 0.0f); // log
            //mandelboxIter(Z, de, P_in, log_lin, 1.0f, (float4)(0.0f, 1.0f, 3.0f, 4.0f), 3.1f); // lin
            //mandelbulbIter(Z, de, P_in, log_lin, 1.0f, (float4)(0.0f, 1.0f, 0.0f, 0.0f), 8.0f); // log
            //mengerSpongeIter(Z, de, P_in, log_lin, 1.0f, (float4)(0.0f, 0.0f, 1.0f, 0.0f)); // lin
            //sierpinski3dIter(Z, de, P_in, log_lin, 1.0f, (float4)(0.0f, 0.0f, 0.0f, 0.5f), 2.0f, (float3)(1.0f, 1.0f, 1.0f), (float3)(0.0f, 0.0f, 0.0f) ); // lin

            break;
        }

        case 1:
        {
            sierpinski3dIter(Z, de, P_in, log_lin, 1.0f, (float4)(0.0f, 0.0f, 0.0f, 0.5f), 2.0f, (float3)(1.0f, 1.0f, 1.0f), (float3)(0.0f, 0.0f, 0.0f) ); // lin

            break;
        }

        case 2:
        {
            mandelbulbPower2Iter(Z, de, P_in, log_lin, 1.0f, (float4)(1.0f, 0.3f, 0.5f, 0.2f)); // log

            break;
        }
        case 3:
        {
            #define PY_FRACTAL_STACK

            break;
        }
    }
}

// scene setup - setting of coordinates and shapes in them

// scene with multiple unions of prims and fractals
/*float scene( float3 P, const int final, float* orbit_colors, float3* N ) {
    float dist_out;
    float orbit_closest = LARGE_NUMBER;

    float shape1 = hybrid(P,                  10, 10.0f, 1.0f, final, &orbit_closest, orbit_colors, N, 0);
    float shape2 = hybrid(P - (float3)(2.0f), 10, 10.0f, 1.0f, final, &orbit_closest, orbit_colors, N, 1);
    float shape3 = hybrid(P + (float3)(2.0f), 10, 10.0f, 1.0f, final, &orbit_closest, orbit_colors, N, 2);

    float shape4 = primitive(P - (float3)(2.0f, 0.0f, 0.0f), 0.3f,      final, &orbit_closest, orbit_colors, (float3)(1.0f,0.0f,1.0f),  N, 0);
    float shape5 = primitive(P - (float3)(-2.0f, 0.0f, 0.0f), 0.6f,     final, &orbit_closest, orbit_colors, (float3)(1.0f,1.0f,0.0f), N, 1);

    dist_out = sdfUnion( sdfUnion( sdfUnion( sdfUnion(shape1, shape2) , shape3 ) , shape4 ) , shape5 );

    return dist_out;
}*/

// scene showing unions and subtractions
/*float scene( float3 P, const int final, float* orbit_colors, float3* N ) {
    float dist_out;
    float orbit_closest = LARGE_NUMBER;

    float shape1 = hybrid(P,                  10, 10.0f, 1.0f, final, &orbit_closest, orbit_colors, N, 0);
    float shape2 = hybrid(P - (float3)(0.4f), 10, 10.0f, 1.0f, final, &orbit_closest, orbit_colors, N, 1);
    //float shape3 = hybrid(P - (float3)(-0.5f, 0.0f, 0.5f), 10, 10.0f, 1.0f, final, &orbit_closest, orbit_colors, N, 2);

    float shape4 = primitive(P - (float3)(0.7f, 0.0f, 0.0f), 1.0f,      final, &orbit_closest, orbit_colors, (float3)(1.0f,0.0f,1.0f),  N, 0);

    dist_out = sdfSubtract( sdfUnion(shape1, shape2) , shape4 );

    return dist_out;
}*/

float scene( float3 P, const int final, float* orbit_colors, float3* N, global const void* theXNoise ) {
    float dist_out;
    float orbit_closest = LARGE_NUMBER;
    int iterations = 0;

    pre_transform_stack(&P, theXNoise);

    float shape1 = hybrid(P, 25, 10.0f, 1.0f, final, &orbit_closest, orbit_colors, N, 3, theXNoise, &iterations);

    dist_out = shape1;

    return dist_out;
}

float scene_fog( float3 P, const int final, float* orbit_colors, float3* N, global const void* theXNoise, const int max_iter, const float max_dist ) {
    float dist_out;
    float orbit_closest = LARGE_NUMBER;
    int iterations = 0;

    pre_transform_stack(&P, theXNoise);

    float shape1 = hybrid(P, max_iter, max_dist, 1.0f, final, &orbit_closest, orbit_colors, N, 3, theXNoise, &iterations);

    dist_out = iterations == max_iter ? 1.0f : 0.0f;

    return dist_out;
}

kernel void marchPerspCam(
        global const void* theXNoise,
        int P_length, global float* P,
        int planeZ_length, global float* planeZ,
        int width_length, global float* width,
        int height_length, global float* height,
        int px_length, global float* px,
        int camXform_length, global float* camXform,
        int camPos_length, global float* camPos,
        int N_length, global float* N,
        int iRel_length, global float* iRel,
        int Cd_length, global float* Cd,
        int orbits_length, global int* orbits_index, global float* orbits
        )
{
    // get current point id
    const long idx = get_global_id(0);

    // if current point is not valid, then end
    if ( idx >= P_length ) return;

    // read in P attrib
    const float3 pixel_P_origin = vload3(idx, P);
    float3 pixel_P_world = pixel_P_origin;

    //// transforming to near img plane

    // move to near img plane
    pixel_P_world.z = planeZ[0];

    // compute scale of near img plane
    const float16 near_plane_scale = mtxScale( (float3)(width[0]-px[0], height[0]-px[0], 1.0f) );

    // read in cam world matrix
    const float16 cam_xform_world = (float16)(camXform[0],camXform[1],camXform[2],camXform[3],
                                              camXform[4],camXform[5],camXform[6],camXform[7],
                                              camXform[8],camXform[9],camXform[10],camXform[11],
                                              camXform[12],camXform[13],camXform[14],camXform[15] );

    // create a mtx to hold transformations
    float16 near_plane_xform = mtxIdent();

    // apply transformations, also produce alternative matrix with scaled near plane
    near_plane_xform = mtxMult(near_plane_xform, near_plane_scale);
    float16 near_plane_xform_scaled = mtxMult(near_plane_xform, mtxScale( (float3)(10000000.0f) ) );
    near_plane_xform = mtxMult(near_plane_xform, cam_xform_world);
    near_plane_xform_scaled = mtxMult(near_plane_xform_scaled, cam_xform_world);

    // create a scaled near plane position for more accurate ray_dir calculation
    float3 pixel_P_world_scaled = mtxPtMult(near_plane_xform_scaled, pixel_P_world);

    // transform pixels into near img plane
    pixel_P_world = mtxPtMult(near_plane_xform, pixel_P_world);

    // get camera world space position and compute ray direction vector
    const float3 cam_P_world = (float3)(camPos[0], camPos[1], camPos[2]);
    const float3 ray_dir = NORMALIZE(pixel_P_world_scaled - cam_P_world);

    //// raymarching

    // raymarch settings, initialize variables
    float3 color = (float3)(0.0f);
    float AO = 1.0f;
    float orbit_colors[ORBITS_ARRAY_LENGTH];
    float3 Cd_out = (float3)(1.0f);
    float3 N_grad;

    float3 ray_P_world = pixel_P_world;
    float cam_dist = scene(cam_P_world, 0, NULL, NULL, theXNoise);
    float de = 0.0f;
    int i = 0;

    // quality settings
    float step_size = 0.35f;
    float iso_limit_mult = 0.5f;
    float ray_dist = planeZ[0];
    const int max_steps = 2500;
    const float max_dist = 1000.0f;

    float iso_limit = cam_dist * 0.0001f * iso_limit_mult;  

    // raymarching loop
    #pragma unroll
    for (i=0; i<max_steps; i++)
    {
        de = scene(ray_P_world, 0, NULL, NULL, theXNoise) * step_size;

        if ( de <= iso_limit || ray_dist >= max_dist )
        {
            de = scene(ray_P_world, 1, orbit_colors, &N_grad, theXNoise) * step_size;
            break;
        }

        ray_dist += de;
        ray_P_world += ray_dir * de;
    }

    // relative amount of steps
    float i_rel = DIV((float)(i), (float)(max_steps));
    i_rel = 1.0f-POWR(i_rel, DIV(1.0f, 3.0f));

    // remove missed
    if ( de > iso_limit )
    {
        i_rel = -1.0f;
    }
    else
    {
        // compute N and AO only when not using DELTA DE mode
        #if !ENABLE_DELTA_DE
            N_grad = compute_N(&iso_limit, &ray_P_world, theXNoise);
            AO = compute_AO(&N_grad, &ray_P_world, theXNoise);
        #endif

        // output shading for viewport preview
        color.x = AO;
        color.y = orbit_colors[0];
        color.z = 1.0f;

        Cd_out = color;
    }

    // export attribs
    vstore3(ray_P_world, idx, P);
    vstore3(N_grad, idx, N);
    vstore3(Cd_out, idx, Cd);
    vstore1(i_rel, idx, iRel);

    long orbits_idx_start = orbits_index[idx];
    long orbits_idx_end = orbits_idx_start + ORBITS_ARRAY_LENGTH;
    #pragma unroll
    for (long j=orbits_idx_start; j<orbits_idx_end; j++)
    {
        orbits[j] = orbit_colors[j-orbits_idx_start];
    }
}

kernel void marchPoints(
        global const void* theXNoise,
        int P_length, global float* P,
        int N_length, global float* N,
        int iRel_length, global float* iRel,
        int Cd_length, global float* Cd,
        int orbits_length, global int* orbits_index, global float* orbits
        )
{
    // get current point id
    const long idx = get_global_id(0);

    // if current point is not valid, then end
    if ( idx >= P_length ) return;

    // read in P, N attribs
    const float3 point_P_origin = vload3(idx, P);
    const float3 point_N = vload3(idx, N);

    //// raymarching

    // raymarch settings, initialize variables
    float3 color = (float3)(0.0f);
    float AO = 1.0f;
    float orbit_colors[ORBITS_ARRAY_LENGTH];
    float3 Cd_out = (float3)(1.0f);
    float3 N_grad;

    float3 ray_P_world = point_P_origin;
    float cam_dist = scene(point_P_origin, 0, NULL, NULL, theXNoise);
    float de = 0.0f;
    int i = 0;

    // quality settings
    float step_size = 0.9f;
    float iso_limit_mult = 0.4f;
    float ray_dist = 0.0f;
    const int max_steps = 150;
    const float max_dist = 100.0f;

    float iso_limit = cam_dist * 0.0001f * iso_limit_mult;  

    // raymarching loop
    #pragma unroll
    for (i=0; i<max_steps; i++)
    {
        de = scene(ray_P_world, 0, NULL, NULL, theXNoise) * step_size;

        if ( de <= iso_limit || ray_dist >= max_dist )
        {
            de = scene(ray_P_world, 1, orbit_colors, &N_grad, theXNoise) * step_size;
            break;
        }

        ray_dist += de;
        ray_P_world += point_N * de;
    }

    // relative amount of steps
    float i_rel = DIV((float)(i), (float)(max_steps));
    i_rel = 1.0f-POWR(i_rel, DIV(1.0f, 3.0f));

    // remove missed
    if ( de > iso_limit )
    {
        i_rel = -1.0f;
    }
    else
    {
        // compute N and AO only when not using DELTA DE mode
        #if !ENABLE_DELTA_DE
            N_grad = compute_N(&iso_limit, &ray_P_world, theXNoise);
            AO = compute_AO(&N_grad, &ray_P_world, theXNoise);
        #endif

        // output shading for viewport preview
        color.x = AO;
        color.y = orbit_colors[0];
        color.z = 1.0f;

        Cd_out = color;
    }

    // export attribs
    vstore3(ray_P_world, idx, P);
    vstore3(N_grad, idx, N);
    vstore3(Cd_out, idx, Cd);
    vstore1(i_rel, idx, iRel);

    long orbits_idx_start = orbits_index[idx];
    long orbits_idx_end = orbits_idx_start + ORBITS_ARRAY_LENGTH;
    #pragma unroll
    for (long j=orbits_idx_start; j<orbits_idx_end; j++)
    {
        orbits[j] = orbit_colors[j-orbits_idx_start];
    }
}

kernel void computeSdf( 
    global const void* theXNoise,
    int surface_stride_x, 
    int surface_stride_y, 
    int surface_stride_z, 
    int surface_stride_offset, 
    float16 surface_xformtoworld, 
    global float * surface
    )
{
    const long gidx = get_global_id(0);
    const long gidy = get_global_id(1);
    const long gidz = get_global_id(2);   
    const long idx = surface_stride_offset + surface_stride_x * gidx + surface_stride_y * gidy + surface_stride_z * gidz;

    float3 P_vol = (float3)(gidx, gidy, gidz);
    float3 P_world = mtxPtMult(surface_xformtoworld, P_vol);

    float de = 0.0f;
    de = scene(P_world, 0, NULL, NULL, theXNoise);
    vstore1(de, idx, surface);
}

kernel void computeSdfColors( 
    global const void* theXNoise,
    int color_0_stride_x, 
    int color_0_stride_y, 
    int color_0_stride_z, 
    int color_0_stride_offset, 
    float16 color_0_xformtoworld, 
    global float* color_0,
    global float* color_1,
    global float* color_2,
    global float* color_3,
    global float* color_4,
    global float* color_5,
    global float* color_6,
    global float* color_7,
    global float* color_8
    )
{
    const long gidx = get_global_id(0);
    const long gidy = get_global_id(1);
    const long gidz = get_global_id(2);
    const long idx = color_0_stride_offset + color_0_stride_x * gidx + color_0_stride_y * gidy + color_0_stride_z * gidz;

    float3 P_vol = (float3)(gidx, gidy, gidz);
    float3 P_world = mtxPtMult(color_0_xformtoworld, P_vol);

    float orbit_colors[ORBITS_ARRAY_LENGTH];    
    float de = 0.0f;

    de = scene(P_world, 1, orbit_colors, NULL, theXNoise);
    
    vstore1(orbit_colors[0], idx, color_0);
    vstore1(orbit_colors[1], idx, color_1);
    vstore1(orbit_colors[2], idx, color_2);
    vstore1(orbit_colors[3], idx, color_3);
    vstore1(orbit_colors[4], idx, color_4);
    vstore1(orbit_colors[5], idx, color_5);
    vstore1(orbit_colors[6], idx, color_6);
    vstore1(orbit_colors[7], idx, color_7);
    vstore1(orbit_colors[8], idx, color_8);
}

kernel void computeFog( 
    global const void *theXNoise, 
    int density_stride_x, 
    int density_stride_y, 
    int density_stride_z, 
    int density_stride_offset, 
    float16 density_xformtoworld, 
    global float* density,
    float max_dist,
    int max_iter
    )
{
    const long gidx = get_global_id(0);
    const long gidy = get_global_id(1);
    const long gidz = get_global_id(2);   
    const long idx = density_stride_offset + density_stride_x * gidx + density_stride_y * gidy + density_stride_z * gidz;

    float3 P_vol = (float3)(gidx, gidy, gidz);
    float3 P_world = mtxPtMult(density_xformtoworld, P_vol);

    float fog = 0.0f;
    fog = scene_fog(P_world, 0, NULL, NULL, theXNoise, max_iter, max_dist);
    vstore1(fog, idx, density);
}

kernel void computeFogColors( 
    global const void* theXNoise,
    int color_0_stride_x, 
    int color_0_stride_y, 
    int color_0_stride_z, 
    int color_0_stride_offset, 
    float16 color_0_xformtoworld, 
    global float* color_0,
    global float* color_1,
    global float* color_2,
    global float* color_3,
    global float* color_4,
    global float* color_5,
    global float* color_6,
    global float* color_7,
    global float* color_8,
    float max_dist,
    int max_iter
    )
{
    const long gidx = get_global_id(0);
    const long gidy = get_global_id(1);
    const long gidz = get_global_id(2);
    const long idx = color_0_stride_offset + color_0_stride_x * gidx + color_0_stride_y * gidy + color_0_stride_z * gidz;

    float3 P_vol = (float3)(gidx, gidy, gidz);
    float3 P_world = mtxPtMult(color_0_xformtoworld, P_vol);

    float orbit_colors[ORBITS_ARRAY_LENGTH];    
    float fog = 0.0f;

    fog = scene_fog(P_world, 1, orbit_colors, NULL, theXNoise, max_iter, max_dist);
    
    vstore1(orbit_colors[0], idx, color_0);
    vstore1(orbit_colors[1], idx, color_1);
    vstore1(orbit_colors[2], idx, color_2);
    vstore1(orbit_colors[3], idx, color_3);
    vstore1(orbit_colors[4], idx, color_4);
    vstore1(orbit_colors[5], idx, color_5);
    vstore1(orbit_colors[6], idx, color_6);
    vstore1(orbit_colors[7], idx, color_7);
    vstore1(orbit_colors[8], idx, color_8);
}

kernel void computeFogAndColors( 
    global const void* theXNoise,
    int density_stride_x,
    int density_stride_y,
    int density_stride_z,
    int density_stride_offset,
    float16 density_xformtoworld,
    global float* density,
    float max_dist,
    int max_iter,
    global float* color_0,
    global float* color_1,
    global float* color_2,
    float3 orbits_select 
    )
{
    const long gidx = get_global_id(0);
    const long gidy = get_global_id(1);
    const long gidz = get_global_id(2);   
    const long idx = density_stride_offset + density_stride_x * gidx + density_stride_y * gidy + density_stride_z * gidz;

    float3 P_vol = (float3)(gidx, gidy, gidz);
    float3 P_world = mtxPtMult(density_xformtoworld, P_vol);

    float orbit_colors[ORBITS_ARRAY_LENGTH];
    float fog = 0.0f;
    fog = scene_fog(P_world, 1, orbit_colors, NULL, theXNoise, max_iter, max_dist);

    vstore1(fog, idx, density);
    vstore1(orbit_colors[ (int)orbits_select.x ] * fog, idx, color_0);
    vstore1(orbit_colors[ (int)orbits_select.y ] * fog, idx, color_1);
    vstore1(orbit_colors[ (int)orbits_select.z ] * fog, idx, color_2);
}

kernel void computeFogAndColorsFrustum( 
    global const void* theXNoise,
    int density_stride_x,
    int density_stride_y,
    int density_stride_z,
    int density_stride_offset,
    global float* density,
    float max_dist,
    int max_iter,
    global float* color_0,
    global float* color_1,
    global float* color_2,
    float3 orbits_select,
    int cam_xform_length,
    global float* camXform,
    int fov_length,
    global float* fov,
    int vol_res_length,
    global float* vol_res,
    int planes_length,
    global float* planes
    )
{
    const long gidx = get_global_id(0);
    const long gidy = get_global_id(1);
    const long gidz = get_global_id(2);   
    const long idx = density_stride_offset + density_stride_x * gidx + density_stride_y * gidy + density_stride_z * gidz;

    float3 P_vol = (float3)(gidx, gidy, gidz);


    // frustum world position setup
    float3 P_norm = P_vol / (float3)(vol_res[0], vol_res[1], vol_res[2]);
    P_norm.xy -= (float2)(0.5f);
    P_norm.z = -mix(planes[0], planes[1], P_norm.z);

    float width = 2.0f * TAN(fov[0] / 2.0f) * P_norm.z;
    float height = width / (vol_res[0] / vol_res[1]);
    float px = width / vol_res[0];

    // compute scale of near img plane
    const float16 scale_xform = mtxScale( (float3)(width - px, height - px, 1.0f) );

    // read in cam world matrix
    const float16 cam_xform = (float16)(camXform[0],camXform[1],camXform[2],camXform[3],
                                        camXform[4],camXform[5],camXform[6],camXform[7],
                                        camXform[8],camXform[9],camXform[10],camXform[11],
                                        camXform[12],camXform[13],camXform[14],camXform[15]);

    float16 frustum_xform = mtxIdent();
    frustum_xform = mtxMult(frustum_xform, scale_xform);
    frustum_xform = mtxMult(frustum_xform, cam_xform);

    float3 P_world = mtxPtMult(frustum_xform, P_norm);


    float orbit_colors[ORBITS_ARRAY_LENGTH];
    float fog = 0.0f;
    fog = scene_fog(P_world, 1, orbit_colors, NULL, theXNoise, max_iter, max_dist);
    //if ( LENGTH(P_world) < 2.0f ) fog = 1.0f;

    vstore1(fog, idx, density);
    vstore1(orbit_colors[ (int)orbits_select.x ] * fog, idx, color_0);
    vstore1(orbit_colors[ (int)orbits_select.y ] * fog, idx, color_1);
    vstore1(orbit_colors[ (int)orbits_select.z ] * fog, idx, color_2);
}

kernel void testFrustumVolume( 
    global const void* theXNoise,
    int density_stride_x,
    int density_stride_y,
    int density_stride_z,
    int density_stride_offset,
    float16 density_xformtoworld,
    global float* density,
    float max_dist,
    int max_iter,
    float3 orbits_select 
    )
{
    const long gidx = get_global_id(0);
    const long gidy = get_global_id(1);
    const long gidz = get_global_id(2);
    const long idx = density_stride_offset + density_stride_x * gidx + density_stride_y * gidy + density_stride_z * gidz;

    float3 P_vol = (float3)(gidx, gidy, gidz);

    float16 taper_mtx = density_xformtoworld;
    //float16 density_xformtoworld_inverted = mtxInvert(density_xformtoworld);

    if (gidx < 50) taper_mtx.s8 *= -1;
    //if (gidy > 50) taper_mtx[9] *= -1;

    //density_xformtoworld_inverted = mtxInvert(density_xformtoworld_inverted);

    //float3 P_taper = mtxPtMult(density_xformtoworld_inverted, P_vol);
    //P_taper = mtxPtMult(density_xformtoworld, P_taper);
    //P_taper = mtxPtMult(density_xformtoworld, P_taper);

    float3 P_world = mtxPtMult(taper_mtx, P_vol);
    //P_world = P_vol;

    float fog = 0.0f;
    //fog = scene_fog(P_world, 0, NULL, NULL, theXNoise, max_iter, max_dist);
    if ( LENGTH(P_world) < 30.6f ) fog = 1.0f;

    printMtxVol(taper_mtx);

    vstore1(fog, idx, density);
}

kernel void computePoints( 
    global const void* theXNoise, 
    int P_length, 
    global float* P,
    int density_length, 
    global float* density,
    float max_dist,
    int max_iter
)
{
    int idx = get_global_id(0);
    if (idx >= density_length)
        return;

    float3 P_world = vload3(idx, P);

    float fog = 0.0f;
    fog = scene_fog(P_world, 0, NULL, NULL, theXNoise, max_iter, max_dist);

    vstore1(fog, idx, density);
}

kernel void lorenzAttractor( 
    int P_length, 
    global float* P,
    int k_length,
    global int* k_index,
    global float* k
)
{
    int idx = get_global_id(0);
    if (idx >= P_length)
        return;

}
