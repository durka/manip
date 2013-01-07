#include <string.h>
#include <math.h>
#include "mex.h"

/*
 * SEmex.c
 *
 * Written by Alex Burka, January 2013
 * University of Pennsylvania, GRASP Lab
 */

#define IJ(m,n,i,j) ((m)[(i) + (n)*(j)])

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    const mxArray *Tparams, *Rparams;
    double *se, *t, *r;
    size_t mt, nt, dt, mr, nr, dr, d;
    int i;

    /* Check for proper number of arguments. */
    if (nrhs!=2) {
        mexErrMsgTxt("Two inputs required.");
    } else if (nlhs>1) {
        mexErrMsgTxt("Too many output arguments.");
    }
    
    Tparams = prhs[0];
    Rparams = prhs[1];

    /* Check argument types */
    if (!mxIsDouble(Tparams) || mxIsComplex(Tparams) || mxGetNumberOfDimensions(Tparams) != 2
     || !mxIsDouble(Rparams) || mxIsComplex(Rparams) || mxGetNumberOfDimensions(Rparams) != 2) {
        mexErrMsgTxt("Inputs must be real double row or column vectors.");
    }

    mt = mxGetM(Tparams);
    nt = mxGetN(Tparams);
    mr = mxGetM(Rparams);
    nr = mxGetN(Rparams);
    if ((mt != 1 && nt != 1) || (mr != 1 && nr != 1)) {
        mexErrMsgTxt("Inputs must be row or column vectors.");
    }
    dt = mt > nt ? mt : nt;
    dr = mr > nr ? mr : nr;
    if (dr == 1) dr = 2;
    if (dt != dr) {
        mexErrMsgTxt("Inconsistent argument dimensions!");
    }
    if (dt != 2 && dt != 3) {
        mexErrMsgTxt("I can only think in two or three dimensions.");
    }
    d = dt;

    plhs[0] = mxCreateDoubleMatrix(d+1, d+1, mxREAL);
    se = mxGetPr(plhs[0]);
    t = mxGetPr(prhs[0]);
    r = mxGetPr(prhs[1]);
    if (d == 2) {
        double c1 = cos(r[0]);
        double s1 = sin(r[0]);
        IJ(se,d+1, 0,0) = c1;
        IJ(se,d+1, 0,1) = -s1;
        IJ(se,d+1, 0,2) = t[0];
        IJ(se,d+1, 1,0) = s1;
        IJ(se,d+1, 1,1) = c1;
        IJ(se,d+1, 1,2) = t[1];
        IJ(se,d+1, 2,2) = 1.0;
    } else {
        double c1 = cos(r[0]);
        double s1 = sin(r[0]);
        double c2 = cos(r[1]);
        double s2 = sin(r[1]);
        double c3 = cos(r[2]);
        double s3 = sin(r[2]);
        IJ(se,d+1, 0,0) = -s1*s3+c3*c1*c2;
        IJ(se,d+1, 0,1) = -c3*s1-c1*c2*s3;
        IJ(se,d+1, 0,2) = -s2*c1;
        IJ(se,d+1, 0,3) = t[0];
        IJ(se,d+1, 1,0) = c1*s3+c3*s1*c2;
        IJ(se,d+1, 1,1) = c3*c1-s1*c2*s3;
        IJ(se,d+1, 1,2) = -s2*s1;
        IJ(se,d+1, 1,3) = t[1];
        IJ(se,d+1, 2,0) = s2*c3;
        IJ(se,d+1, 2,1) = -s2*s3;
        IJ(se,d+1, 2,2) = c2;
        IJ(se,d+1, 2,3) = t[2];
        IJ(se,d+1, 3,3) = 1.0;
    }
}

