#include <string.h>
#include <math.h>
#include "mex.h"

/*
 * Rmex.c
 *
 * Written by Alex Burka, December 2012
 * University of Pennsylvania, GRASP Lab
 */

#define IJ(m,n,i,j) ((m)[(i) + (n)*(j)])

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    const mxArray *params;
    double *r, *theta;
    size_t m, n, d;
    int i;

    /* Check for proper number of arguments. */
    if (nrhs!=1) {
        mexErrMsgTxt("One input required.");
    } else if (nlhs>1) {
        mexErrMsgTxt("Too many output arguments.");
    }
    
    params = prhs[0];

    /* Check argument types */
    if (!mxIsDouble(params) || mxIsComplex(params) || mxGetNumberOfDimensions(params) != 2) {
        mexErrMsgTxt("Input must be a real double scalar or 3-element vector.");
    }

    m = mxGetM(params);
    n = mxGetN(params);
    if (m != 1 && n != 1) {
        mexErrMsgTxt("Input must be a scalar or 3-element vector.");
    }
    d = m > n ? m : n;
    if (d == 1) d = 2;
    if (d != 2 && d != 3) {
        mexErrMsgTxt("I can only think in two or three dimensions.");
    }

    plhs[0] = mxCreateDoubleMatrix(d+1, d+1, mxREAL);
    r = mxGetPr(plhs[0]);
    theta = mxGetPr(params);
    if (d == 2) {
        IJ(r,d+1, 0,0) = cos(*theta); IJ(r,d+1, 0,1) = -sin(*theta); IJ(r,d+1, 0,2) = 0;
        IJ(r,d+1, 1,0) = sin(*theta); IJ(r,d+1, 1,1) =  cos(*theta); IJ(r,d+1, 1,2) = 0;
        IJ(r,d+1, 2,0) = 0;           IJ(r,d+1, 2,1) = 0;            IJ(r,d+1, 2,2) = 1;
    } else {
        double ca = cos(theta[0]), cb = cos(theta[1]), cc = cos(theta[2]),
               sa = sin(theta[0]), sb = sin(theta[1]), sc = sin(theta[2]);

        IJ(r,d+1, 0,0) = ca*cb*cc - sa*sc; IJ(r,d+1, 0,1) = -cc*sa - ca*cb*sc; IJ(r,d+1, 0,2) = -ca*sb; IJ(r,d+1, 0,3) = 0;
        IJ(r,d+1, 1,0) = ca*sc + cb*cc*sa; IJ(r,d+1, 1,1) =  ca*cc - cb*sa*sc; IJ(r,d+1, 1,2) = -sa*sb; IJ(r,d+1, 1,3) = 0;
        IJ(r,d+1, 2,0) = cc*sb;            IJ(r,d+1, 2,1) = -sb*sc;            IJ(r,d+1, 2,2) =  cb;    IJ(r,d+1, 2,3) = 0;
        IJ(r,d+1, 3,0) = 0;                IJ(r,d+1, 3,1) =  0;                IJ(r,d+1, 3,2) =  0;     IJ(r,d+1, 3,3) = 1;
    }
}

