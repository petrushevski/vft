#include "raymarching_funcs.h"

// 
//// scene setup

static float scene( float3 P, float frame ) {
    float dist;

    float3 P_rep = sdfRep( P, (float3)(8, 22, 2) );
    
    P_rep.x = P.x;
    P_rep.y = P.y;
    P_rep.z = P.z;

    float shape1 = mandelbox( P_rep - (float3)( -3 + frame*0.03 ,0.2,0), 3, .2 );
    float shape2 = mandelbulb( P_rep, 8, 1.1 );
    //float shape2 = mandelbulb( P_rep, 4, 1.1 );
    //float shape2 = box(P_rep - (float3)(0,0.2,0), .8);
    //float shape2 = sphere(P_rep, 1.08, (float3)(0));


    //dist = sdfBlend(shape1, shape2, frame*.005);
    dist = sdfUnionSmooth(shape1, shape2, 0.3);
    //dist = shape1;

    return dist;
}

//// main function

kernel void marchPerspCam(
        float timeinc, float time, 
        int P_length, global float* P,
        int planeZ_length, global float* planeZ,
        int width_length, global float* width,
        int height_length, global float* height,
        int px_length, global float* px,
        int camXform_length, global float* camXform,
        int camPos_length, global float* camPos,
        int N_length, global float* N,
        int iRel_length, global float* iRel,
        int Cd_length, global float* Cd
        )
{
    // get current point id
    int idx = get_global_id(0);

    // if current point is not valid, then end
    if ( idx >= P_length )
        return;

    // read in P attrib
    float3 P_in = vload3(idx, P);
    float3 P_out = P_in;

    //// transforming to near img plane

    // move to near img plane
    P_out.z = planeZ[0];
    
    // compute scale of near img plane
    float16 scale = mtxScale( (float3)(width[0]-px[0], height[0]-px[0], 1) );
    
    // read in cam world matrix
    float16 cam = (float16)(camXform[0],camXform[1],camXform[2],camXform[3],
                            camXform[4],camXform[5],camXform[6],camXform[7],
                            camXform[8],camXform[9],camXform[10],camXform[11],
                            camXform[12],camXform[13],camXform[14],camXform[15] );

    // create a mtx to hold transformations
    float16 xform = ident();

    // apply transformations
    xform = mtxMult(xform, scale);
    xform = mtxMult(xform, cam);

    // transform points into near img plane
    P_out = mtxPtMult(xform, P_out);    

    // get camera world space position and compute ray direction vector
    float3 camP = (float3)(camPos[0], camPos[1], camPos[2]);
    float3 rayDir = normalize(P_out - camP);

    //// raymarching

    // raymarch settings
    float dist;
    int i = 0;
    int max = 3000;
    float stepSize = 0.3;
    float iso = 0.0004;
    float t = planeZ[0];
    float maxDist = 20000;

    float frame = time/timeinc + 1;

    // raymarch
    for (i=0; i<max; i++) {
        dist = scene(P_out, frame);
        //if ( dist <= iso * (t/300) || t >= maxDist ) break;
        if ( dist <= iso || t >= maxDist ) break;
        dist *= stepSize;
        t += dist;
        P_out += rayDir * dist;
    }

    // compute N
    float e = iso;
    float3 N_out = (float3)(0);
    float3 ePos[6] = { P_out + (float3)(e,0,0),
                       P_out - (float3)(e,0,0),
                       P_out + (float3)(0,e,0),
                       P_out - (float3)(0,e,0),
                       P_out + (float3)(0,0,e),
                       P_out - (float3)(0,0,e) };
    
    N_out = (float3)( scene( ePos[0], frame ) - scene( ePos[1], frame ),
                      scene( ePos[2], frame ) - scene( ePos[3], frame ),
                      scene( ePos[4], frame ) - scene( ePos[5], frame ) );

    N_out = normalize(N_out);

    // relative amount of steps
    float iRel_out = (float)(i)/(float)(max);
    iRel_out = pow(iRel_out, 1.0f/2.0f);

    // remove missed
    if ( dist > iso ) {
        //P_out = (float3)(0);
        iRel_out = -1;
    }

    // Cd for viz
    float3 Cd_out = fabs(N_out);
    Cd_out *= (1 - iRel_out);

    // export attribs
    vstore3(P_out, idx, P);
    vstore3(N_out, idx, N);
    vstore3(Cd_out, idx, Cd);
    vstore1(iRel_out, idx, iRel);
}