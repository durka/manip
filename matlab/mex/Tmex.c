#include <string.h>
#include <math.h>
#include "mex.h"

/*
 * Tmex.c
 *
 * Written by Alex Burka, December 2012
 * University of Pennsylvania, GRASP Lab
 */

#define IJ(m,n,i,j) ((m)[(i) + (n)*(j)])

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    const mxArray *params;
    double *t;
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
        mexErrMsgTxt("Input must be a real double row or column vector.");
    }

    m = mxGetM(params);
    n = mxGetN(params);
    if (m != 1 && n != 1) {
        mexErrMsgTxt("Input must be a row or column vector.");
    }
    d = m > n ? m : n;
    if (d != 2 && d != 3) {
        mexErrMsgTxt("I can only think in two or three dimensions.");
    }

    plhs[0] = mxCreateDoubleMatrix(d+1, d+1, mxREAL);
    t = mxGetPr(plhs[0]);
    for (i = 0; i < d+1; ++i) {
        IJ(t, d+1, i, i) = 1;
    }
    for (i = 0; i < d; ++i) {
        IJ(t, d+1, i, d) = mxGetPr(params)[i];
    }
}

