#include <string.h>
#include <math.h>
#include "mex.h"

/*
 * mex_inverse_rigid.c
 *
 * Translation of inverse_rigid.m
 *
 * Written by Alex Burka, December 2012
 * University of Pennsylvania, GRASP Lab
 */

/*
% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to the to-object center

function [state, D] = inverse_rigid(x, params)
    state = 0; % rigid joints have no state
    
    if nargout > 1
        n = size(x,1)-1;
        d = n*(n+1)/2;
        D = vertcat(eye(d), zeros(1,d));
    end
end
*/

#define IJ(m,n,i,j) ((m)[(i) + (n)*(j)])

void inverse_rigid(int n, double *x, double *offset, double *state)
{
    *state = 0;
}

void inverse_rigid_gradient(int n, double *D)
{
    if (n == 2) {
        IJ(D,4,0,0) = 1 ; IJ(D,4,0,1) = 0 ; IJ(D,4,0,2) = 0 ; 
        IJ(D,4,1,0) = 0 ; IJ(D,4,1,1) = 1 ; IJ(D,4,1,2) = 0 ; 
        IJ(D,4,2,0) = 0 ; IJ(D,4,2,1) = 0 ; IJ(D,4,2,2) = 1 ; 
        IJ(D,4,3,0) = 0 ; IJ(D,4,3,1) = 0 ; IJ(D,4,3,2) = 0 ; 
    } else {
        IJ(D,7,0,0) = 1 ; IJ(D,7,0,1) = 0 ; IJ(D,7,0,2) = 0 ; IJ(D,7,0,3) = 0 ; IJ(D,7,0,4) = 0 ; IJ(D,7,0,5) = 0 ; 
        IJ(D,7,1,0) = 0 ; IJ(D,7,1,1) = 1 ; IJ(D,7,1,2) = 0 ; IJ(D,7,1,3) = 0 ; IJ(D,7,1,4) = 0 ; IJ(D,7,1,5) = 0 ; 
        IJ(D,7,2,0) = 0 ; IJ(D,7,2,1) = 0 ; IJ(D,7,2,2) = 1 ; IJ(D,7,2,3) = 0 ; IJ(D,7,2,4) = 0 ; IJ(D,7,2,5) = 0 ; 
        IJ(D,7,3,0) = 0 ; IJ(D,7,3,1) = 0 ; IJ(D,7,3,2) = 0 ; IJ(D,7,3,3) = 1 ; IJ(D,7,3,4) = 0 ; IJ(D,7,3,5) = 0 ; 
        IJ(D,7,4,0) = 0 ; IJ(D,7,4,1) = 0 ; IJ(D,7,4,2) = 0 ; IJ(D,7,4,3) = 0 ; IJ(D,7,4,4) = 1 ; IJ(D,7,4,5) = 0 ; 
        IJ(D,7,5,0) = 0 ; IJ(D,7,5,1) = 0 ; IJ(D,7,5,2) = 0 ; IJ(D,7,5,3) = 0 ; IJ(D,7,5,4) = 0 ; IJ(D,7,5,5) = 1 ; 
        IJ(D,7,6,0) = 0 ; IJ(D,7,6,1) = 0 ; IJ(D,7,6,2) = 0 ; IJ(D,7,6,3) = 0 ; IJ(D,7,6,4) = 0 ; IJ(D,7,6,5) = 0 ; 
    }
}

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
  mxArray *offset = NULL;
  size_t m, n;

  /* Check for proper number of arguments. */
  if(nrhs!=2) {
    mexErrMsgTxt("Two inputs required.");
  } else if(nlhs>2) {
    mexErrMsgTxt("Too many output arguments.");
  }

  /* The first input must be a SE(n) */
  m = mxGetM(prhs[0]);
  n = mxGetN(prhs[0]);
  if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[1]) || !((m == 3 && n == 3) || (m == 4 && n ==4))) {
      mexErrMsgTxt("x must be a 3x3 or 4x4 real double matrix.");
  }
  
  /* The second input must be a 1x1 cell with a SE(n) in it.*/
  if (!mxIsCell(prhs[1]) || mxGetNumberOfDimensions(prhs[1]) != 2 || mxGetM(prhs[1]) != 1 || mxGetN(prhs[1]) != 1) {
      mexErrMsgTxt("params must be a 1x1 cell array.");
  }
  offset = mxGetCell(prhs[1], 0);
  m = mxGetM(offset);
  n = mxGetN(offset);
  if (!mxIsDouble(offset) || mxIsComplex(offset) || !((m == 3 && n == 3) || (m == 4 && n == 4))) {
      mexErrMsgTxt("params{1} must be a 3x3 or 4x4 real double matrix.");
  }

  /* Create matrices for return arguments. */
  plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
  if (nrhs == 2) {
      size_t d = m*(m-1)/2;
      plhs[1] = mxCreateDoubleMatrix(d+1, d, mxREAL);
  }

  /* Call subroutine(s). */
  inverse_rigid(m-1, mxGetPr(prhs[0]), mxGetPr(offset), mxGetPr(plhs[0]));
  if (nrhs == 2) {
      inverse_rigid_gradient(m-1, mxGetPr(plhs[1]));
  }
}
