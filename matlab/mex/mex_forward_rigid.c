#include <string.h>
#include <math.h>
#include "mex.h"

/*
 * mex_forward_rigid.c
 *
 * Translation of forward_rigid.m
 *
 * Written by Alex Burka, December 2012
 * University of Pennsylvania, GRASP Lab
 */


/*
% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to the to-object center
function [x, Dr, Dt] = forward_rigid(params, ~)
    x = params{1};

    if nargout > 1
        [t, r] = extract_SE(params{1});
        if length(t) == 2
            Dr = [ 0 0 -sin(r) 0
                   0 0 -cos(r) 0
                   0 0  cos(r) 0
                   0 0 -sin(r) 0 ];
            Dt = [ 1 0 0 0
                   0 1 0 0 ];
        else
            Dr = [ 0, 0, 0,       -cos(r(1))*sin(r(3)) - cos(r(2))*cos(r(3))*sin(r(1)),      -cos(r(1))*cos(r(3))*sin(r(2)),       -cos(r(3))*sin(r(1)) - cos(r(1))*cos(r(2))*sin(r(3)),      0
                   0, 0, 0,       -sin(r(1))*sin(r(3)) + cos(r(1))*cos(r(2))*cos(r(3)),      -cos(r(3))*sin(r(1))*sin(r(2)),       -cos(r(2))*sin(r(1))*sin(r(3)) + cos(r(1))*cos(r(3)),      0
                   0, 0, 0,        0,                                                         cos(r(2))*cos(r(3)),                 -sin(r(2))*sin(r(3)),                                      0
                   0, 0, 0,       -cos(r(1))*cos(r(3)) + cos(r(2))*sin(r(1))*sin(r(3)),       cos(r(1))*sin(r(2))*sin(r(3)),        sin(r(1))*sin(r(3)) - cos(r(1))*cos(r(2))*cos(r(3)),      0
                   0, 0, 0,       -cos(r(3))*sin(r(1)) - cos(r(1))*cos(r(2))*sin(r(3)),       sin(r(1))*sin(r(2))*sin(r(3)),       -cos(r(1))*sin(r(3)) - cos(r(2))*cos(r(3))*sin(r(1)),      0
                   0, 0, 0,        0,                                                        -cos(r(2))*sin(r(3)),                 -cos(r(3))*sin(r(2)),                                      0
                   0, 0, 0,        sin(r(1))*sin(r(2)),                                      -cos(r(1))*cos(r(2)),                  0,                                                        0
                   0, 0, 0,       -cos(r(1))*sin(r(2)),                                      -cos(r(2))*sin(r(1)),                  0,                                                        0
                   0, 0, 0,        0,                                                        -sin(r(2)),                            0,                                                        0 ];
            Dt = [ 1 0 0    0 0 0   0
                   0 1 0    0 0 0   0
                   0 0 1    0 0 0   0 ];
        end
    end
end
*/

#define IJ(m,n,i,j) ((m)[(i) + (n)*(j)])

void forward_rigid(int n, double *offset, double *x)
{
    memcpy(x, offset, (n+1)*(n+1)*sizeof(double));
}

void forward_rigid_gradient(int n, double *t, double *r, double *Dr, double *Dt)
{
    if (n == 2) {
        IJ(Dr,4,0,0) = 0 ; IJ(Dr,4,0,1) = 0 ; IJ(Dr,4,0,2) = -sin(r[0]) ; IJ(Dr,4,0,3) = 0 ; 
        IJ(Dr,4,1,0) = 0 ; IJ(Dr,4,1,1) = 0 ; IJ(Dr,4,1,2) = -cos(r[0]) ; IJ(Dr,4,1,3) = 0 ; 
        IJ(Dr,4,2,0) = 0 ; IJ(Dr,4,2,1) = 0 ; IJ(Dr,4,2,2) =  cos(r[0]) ; IJ(Dr,4,2,3) = 0 ; 
        IJ(Dr,4,3,0) = 0 ; IJ(Dr,4,3,1) = 0 ; IJ(Dr,4,3,2) = -sin(r[0]) ; IJ(Dr,4,3,3) = 0 ; 

        IJ(Dt,2,0,0) = 1 ; IJ(Dt,2,0,1) = 0 ; IJ(Dt,2,0,2) = 0 ; IJ(Dt,2,0,3) = 0 ; 
        IJ(Dt,2,1,0) = 0 ; IJ(Dt,2,1,1) = 1 ; IJ(Dt,2,1,2) = 0 ; IJ(Dt,2,1,3) = 0 ; 
    } else {
        IJ(Dr,9,0,0) = 0 ; IJ(Dr,9,0,1) = 0 ; IJ(Dr,9,0,2) = 0 ; IJ(Dr,9,0,3) = - cos(r[0])*sin(r[2]) - cos(r[1])*cos(r[2])*sin(r[0]) ; IJ(Dr,9,0,4) = -cos(r[0])*cos(r[2])*sin(r[1]) ; IJ(Dr,9,0,5) = - cos(r[2])*sin(r[0]) - cos(r[0])*cos(r[1])*sin(r[2]) ; IJ(Dr,9,0,6) = 0 ; 
        IJ(Dr,9,1,0) = 0 ; IJ(Dr,9,1,1) = 0 ; IJ(Dr,9,1,2) = 0 ; IJ(Dr,9,1,3) = cos(r[0])*cos(r[1])*cos(r[2]) - sin(r[0])*sin(r[2])   ; IJ(Dr,9,1,4) = -cos(r[2])*sin(r[0])*sin(r[1]) ; IJ(Dr,9,1,5) = cos(r[0])*cos(r[2]) - cos(r[1])*sin(r[0])*sin(r[2])   ; IJ(Dr,9,1,6) = 0 ; 
        IJ(Dr,9,2,0) = 0 ; IJ(Dr,9,2,1) = 0 ; IJ(Dr,9,2,2) = 0 ; IJ(Dr,9,2,3) = 0                                                     ; IJ(Dr,9,2,4) = cos(r[1])*cos(r[2])            ; IJ(Dr,9,2,5) = -sin(r[1])*sin(r[2])                                  ; IJ(Dr,9,2,6) = 0 ; 
        IJ(Dr,9,3,0) = 0 ; IJ(Dr,9,3,1) = 0 ; IJ(Dr,9,3,2) = 0 ; IJ(Dr,9,3,3) = cos(r[1])*sin(r[0])*sin(r[2]) - cos(r[0])*cos(r[2])   ; IJ(Dr,9,3,4) = cos(r[0])*sin(r[1])*sin(r[2])  ; IJ(Dr,9,3,5) = sin(r[0])*sin(r[2]) - cos(r[0])*cos(r[1])*cos(r[2])   ; IJ(Dr,9,3,6) = 0 ; 
        IJ(Dr,9,4,0) = 0 ; IJ(Dr,9,4,1) = 0 ; IJ(Dr,9,4,2) = 0 ; IJ(Dr,9,4,3) = - cos(r[2])*sin(r[0]) - cos(r[0])*cos(r[1])*sin(r[2]) ; IJ(Dr,9,4,4) = sin(r[0])*sin(r[1])*sin(r[2])  ; IJ(Dr,9,4,5) = - cos(r[0])*sin(r[2]) - cos(r[1])*cos(r[2])*sin(r[0]) ; IJ(Dr,9,4,6) = 0 ; 
        IJ(Dr,9,5,0) = 0 ; IJ(Dr,9,5,1) = 0 ; IJ(Dr,9,5,2) = 0 ; IJ(Dr,9,5,3) = 0                                                     ; IJ(Dr,9,5,4) = -cos(r[1])*sin(r[2])           ; IJ(Dr,9,5,5) = -cos(r[2])*sin(r[1])                                  ; IJ(Dr,9,5,6) = 0 ; 
        IJ(Dr,9,6,0) = 0 ; IJ(Dr,9,6,1) = 0 ; IJ(Dr,9,6,2) = 0 ; IJ(Dr,9,6,3) = sin(r[0])*sin(r[1])                                   ; IJ(Dr,9,6,4) = -cos(r[0])*cos(r[1])           ; IJ(Dr,9,6,5) = 0                                                     ; IJ(Dr,9,6,6) = 0 ; 
        IJ(Dr,9,7,0) = 0 ; IJ(Dr,9,7,1) = 0 ; IJ(Dr,9,7,2) = 0 ; IJ(Dr,9,7,3) = -cos(r[0])*sin(r[1])                                  ; IJ(Dr,9,7,4) = -cos(r[1])*sin(r[0])           ; IJ(Dr,9,7,5) = 0                                                     ; IJ(Dr,9,7,6) = 0 ; 
        IJ(Dr,9,8,0) = 0 ; IJ(Dr,9,8,1) = 0 ; IJ(Dr,9,8,2) = 0 ; IJ(Dr,9,8,3) = 0                                                     ; IJ(Dr,9,8,4) = -sin(r[1])                     ; IJ(Dr,9,8,5) = 0                                                     ; IJ(Dr,9,8,6) = 0 ; 

        IJ(Dt,3,0,0) = 1 ; IJ(Dt,3,0,1) = 0 ; IJ(Dt,3,0,2) = 0 ; IJ(Dt,3,0,3) = 0 ; IJ(Dt,3,0,4) = 0 ; IJ(Dt,3,0,5) = 0 ; IJ(Dt,3,0,6) = 0 ; 
        IJ(Dt,3,1,0) = 0 ; IJ(Dt,3,1,1) = 1 ; IJ(Dt,3,1,2) = 0 ; IJ(Dt,3,1,3) = 0 ; IJ(Dt,3,1,4) = 0 ; IJ(Dt,3,1,5) = 0 ; IJ(Dt,3,1,6) = 0 ; 
        IJ(Dt,3,2,0) = 0 ; IJ(Dt,3,2,1) = 0 ; IJ(Dt,3,2,2) = 1 ; IJ(Dt,3,2,3) = 0 ; IJ(Dt,3,2,4) = 0 ; IJ(Dt,3,2,5) = 0 ; IJ(Dt,3,2,6) = 0 ; 

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
  } else if(nlhs>3) {
    mexErrMsgTxt("Too many output arguments.");
  }
  
  /* The first input must be a 1x1 cell with a SE(n) in it.*/
  if (!mxIsCell(prhs[0]) || mxGetNumberOfDimensions(prhs[0]) != 2 || mxGetM(prhs[0]) != 1 || mxGetN(prhs[0]) != 1) {
      mexErrMsgTxt("params must be a 1x1 cell array.");
  }
  offset = mxGetCell(prhs[0], 0);
  m = mxGetM(offset);
  n = mxGetN(offset);
  if (!mxIsDouble(offset) || mxIsComplex(offset) || !((m == 3 && n == 3) || (m == 4 && n == 4))) {
      mexErrMsgTxt("params{1} must be a 3x3 or 4x4 real double matrix.");
  }

  /* The second input must be a real double scalar. */
  if (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) || mxGetM(prhs[1]) != 1 || mxGetN(prhs[1]) != 1) {
      mexErrMsgTxt("state must be a real double scalar.");
  }
  
  /* Create matrix for the first return argument. */
  plhs[0] = mxCreateDoubleMatrix(m, n, mxREAL);
  if (nlhs == 3) {
      if (m == 3) {
          plhs[1] = mxCreateDoubleMatrix(4, 4, mxREAL);
          plhs[2] = mxCreateDoubleMatrix(2, 4, mxREAL);
      } else {
          plhs[1] = mxCreateDoubleMatrix(9, 7, mxREAL);
          plhs[2] = mxCreateDoubleMatrix(3, 7, mxREAL);
      }
  }
  
  /* Call the subroutine(s). */
  forward_rigid(m-1, mxGetPr(offset), mxGetPr(plhs[0]));
  if (nlhs == 3) {
      mxArray* lhs[2];
      
      if (mexCallMATLAB(2, lhs, 1, &offset, "extract_SE") != 0) {
          mexErrMsgTxt("failed to call extract_SE");
      }
      
      forward_rigid_gradient(m-1, mxGetPr(lhs[0]), mxGetPr(lhs[1]), mxGetPr(plhs[1]), mxGetPr(plhs[2]));
  }
}
