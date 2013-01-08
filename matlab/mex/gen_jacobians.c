#include <string.h>
#include <math.h>
#include "mex.h"

/*
 * gen_jacobians.c
 *
 * Generated by Matlab and then edited
 *
 * Written by Alex Burka, December 2012
 * University of Pennsylvania, GRASP Lab
 */

void Dq_3(double *ur, double *vr, double *Dq);
void Dq_2(double *ur, double *vr, double *Dq);
void Dr_3(double *ut, double *vt, double *Dr);
void Dr_2(double *ut, double *vt, double *Dr);

/* steps taken to generate this (do these for Dq, Dr, dims=2 and dims=3 and combine the files)
   1. make Matlab function
      A = sym('a%d%d', [dims dims]); A = sym(A, 'real');
      B = sym('b%d%d', [dims dims]); B = sym(B, 'real');
      s = evalc('simplify(jacobian(2*acos((trace(A\B)-1)/2), A))');
      Dq = eval(sprintf('@(ur, vr) %s', regexprep(subsref(regexp(s, '\n', 'split'), substruct('{}', {4})), {'a(\d)(\d)', 'b(\d)(\d)'}, {'ur($1,$2)', 'vr($1,$2)'})));
   2. translate to C
      ur = sym('ur_%d_%d', [dims dims]); ur = sym(ur, 'real');
      vr = sym('vr_%d_%d', [dims dims]); vr = sym(vr, 'real');
      ccode(Dq(ur,vr), 'file', 'mex/gen_Dq.c')
   3. regular expressions
      s/MatrixWithNoName/Dq/g    (Dq or Dr)
      s/\([uv]r\)_\(\d\)_\(\d\)/\=join(['IJ(', submatch(1), ',dims,', submatch(2)-1, ',', submatch(3)-1, ')'], '')/g    (replace dims with 2 and 3)
   4. put the necessary mex scaffolding around it (functions, declare variables, etc)
 */

#define IJ(m,n,i,j) ((m)[(i) + (n)*(j)])

void Dq_3(double *ur, double *vr, double *Dq)
{
    double t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t2, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t3, t30, t31, t32, t33, t34, t35, t36, t37, t38, t39, t4, t40, t41, t42, t43, t44, t45, t46, t47, t48, t49, t5, t50, t51, t52, t53, t54, t55, t56, t57, t58, t59, t6, t60, t61, t62, t63, t64, t65, t66, t67, t68, t69, t7, t70, t71, t72, t8, t9;
    // BEGIN GENERATED CODE
        t2 = IJ(ur,3,0,0)*IJ(ur,3,1,1)*IJ(ur,3,2,2)*2.0;
        t3 = IJ(ur,3,0,1)*IJ(ur,3,2,0)*IJ(ur,3,1,2)*2.0;
        t4 = IJ(ur,3,1,0)*IJ(ur,3,0,2)*IJ(ur,3,2,1)*2.0;
        t7 = IJ(ur,3,0,0)*IJ(ur,3,1,2)*IJ(ur,3,2,1)*2.0;
        t8 = IJ(ur,3,0,1)*IJ(ur,3,1,0)*IJ(ur,3,2,2)*2.0;
        t9 = IJ(ur,3,0,2)*IJ(ur,3,1,1)*IJ(ur,3,2,0)*2.0;
        t5 = t2+t3+t4-t7-t8-t9;
        t6 = 1.0/t5;
        t11 = IJ(ur,3,0,0)*IJ(ur,3,1,1)*IJ(vr,3,2,2);
        t12 = IJ(ur,3,0,0)*IJ(ur,3,2,1)*IJ(vr,3,1,2);
        t13 = IJ(ur,3,0,1)*IJ(ur,3,1,0)*IJ(vr,3,2,2);
        t14 = IJ(ur,3,0,1)*IJ(ur,3,2,0)*IJ(vr,3,1,2);
        t15 = IJ(ur,3,1,0)*IJ(ur,3,2,1)*IJ(vr,3,0,2);
        t16 = IJ(ur,3,1,1)*IJ(ur,3,2,0)*IJ(vr,3,0,2);
        t17 = t11-t12-t13+t14+t15-t16;
        t25 = IJ(ur,3,0,0)*IJ(ur,3,1,2)*IJ(vr,3,2,1);
        t26 = IJ(ur,3,0,0)*IJ(ur,3,2,2)*IJ(vr,3,1,1);
        t27 = IJ(ur,3,1,0)*IJ(ur,3,0,2)*IJ(vr,3,2,1);
        t28 = IJ(ur,3,1,0)*IJ(ur,3,2,2)*IJ(vr,3,0,1);
        t29 = IJ(ur,3,0,2)*IJ(ur,3,2,0)*IJ(vr,3,1,1);
        t30 = IJ(ur,3,2,0)*IJ(ur,3,1,2)*IJ(vr,3,0,1);
        t31 = t25-t26-t27+t28+t29-t30;
        t36 = IJ(ur,3,0,1)*IJ(ur,3,1,2)*IJ(vr,3,2,0);
        t37 = IJ(ur,3,0,1)*IJ(ur,3,2,2)*IJ(vr,3,1,0);
        t38 = IJ(ur,3,0,2)*IJ(ur,3,1,1)*IJ(vr,3,2,0);
        t39 = IJ(ur,3,0,2)*IJ(ur,3,2,1)*IJ(vr,3,1,0);
        t40 = IJ(ur,3,1,1)*IJ(ur,3,2,2)*IJ(vr,3,0,0);
        t41 = IJ(ur,3,1,2)*IJ(ur,3,2,1)*IJ(vr,3,0,0);
        t42 = t36-t37-t38+t39+t40-t41;
        t43 = t17*t6;
        t44 = t31*t6;
        t45 = t42*t6;
        t10 = t43-t44+t45-1.0/2.0;
        t18 = IJ(ur,3,1,1)*IJ(ur,3,2,2);
        t32 = IJ(ur,3,1,2)*IJ(ur,3,2,1);
        t19 = t18-t32;
        t20 = IJ(ur,3,0,0)*IJ(ur,3,1,1)*IJ(ur,3,2,2);
        t21 = IJ(ur,3,0,1)*IJ(ur,3,2,0)*IJ(ur,3,1,2);
        t22 = IJ(ur,3,1,0)*IJ(ur,3,0,2)*IJ(ur,3,2,1);
        t33 = IJ(ur,3,0,0)*IJ(ur,3,1,2)*IJ(ur,3,2,1);
        t34 = IJ(ur,3,0,1)*IJ(ur,3,1,0)*IJ(ur,3,2,2);
        t35 = IJ(ur,3,0,2)*IJ(ur,3,1,1)*IJ(ur,3,2,0);
        t23 = t20+t21+t22-t33-t34-t35;
        t24 = 1.0/(t23*t23);
        t46 = t10*t10;
        t47 = -t46+1.0;
        t48 = 1.0/sqrt(t47);
        t49 = IJ(ur,3,0,1)*IJ(ur,3,2,2);
        t51 = IJ(ur,3,0,2)*IJ(ur,3,2,1);
        t50 = t49-t51;
        t52 = IJ(ur,3,0,1)*IJ(ur,3,1,2);
        t54 = IJ(ur,3,0,2)*IJ(ur,3,1,1);
        t53 = t52-t54;
        t55 = IJ(ur,3,1,0)*IJ(ur,3,2,2);
        t57 = IJ(ur,3,2,0)*IJ(ur,3,1,2);
        t56 = t55-t57;
        t58 = IJ(ur,3,0,0)*IJ(ur,3,2,2);
        t60 = IJ(ur,3,0,2)*IJ(ur,3,2,0);
        t59 = t58-t60;
        t61 = IJ(ur,3,0,0)*IJ(ur,3,1,2);
        t63 = IJ(ur,3,1,0)*IJ(ur,3,0,2);
        t62 = t61-t63;
        t64 = IJ(ur,3,1,0)*IJ(ur,3,2,1);
        t66 = IJ(ur,3,1,1)*IJ(ur,3,2,0);
        t65 = t64-t66;
        t67 = IJ(ur,3,0,0)*IJ(ur,3,2,1);
        t69 = IJ(ur,3,0,1)*IJ(ur,3,2,0);
        t68 = t67-t69;
        t70 = IJ(ur,3,0,0)*IJ(ur,3,1,1);
        t72 = IJ(ur,3,0,1)*IJ(ur,3,1,0);
        t71 = t70-t72;
        Dq[0] = t48*(t6*(IJ(ur,3,1,1)*IJ(vr,3,2,2)-IJ(ur,3,2,1)*IJ(vr,3,1,2))*-2.0+t6*(IJ(ur,3,1,2)*IJ(vr,3,2,1)-IJ(ur,3,2,2)*IJ(vr,3,1,1))*2.0+t17*t19*t24-t19*t24*t31+t19*t24*t42);
        Dq[1] = -t48*(t6*(IJ(ur,3,0,1)*IJ(vr,3,2,2)-IJ(ur,3,2,1)*IJ(vr,3,0,2))*-2.0+t6*(IJ(ur,3,0,2)*IJ(vr,3,2,1)-IJ(ur,3,2,2)*IJ(vr,3,0,1))*2.0+t17*t24*t50-t24*t31*t50+t24*t42*t50);
        Dq[2] = t48*(t6*(IJ(ur,3,0,1)*IJ(vr,3,1,2)-IJ(ur,3,1,1)*IJ(vr,3,0,2))*-2.0+t6*(IJ(ur,3,0,2)*IJ(vr,3,1,1)-IJ(ur,3,1,2)*IJ(vr,3,0,1))*2.0+t17*t24*t53-t24*t31*t53+t24*t42*t53);
        Dq[3] = -t48*(t6*(IJ(ur,3,1,0)*IJ(vr,3,2,2)-IJ(ur,3,2,0)*IJ(vr,3,1,2))*-2.0+t6*(IJ(ur,3,1,2)*IJ(vr,3,2,0)-IJ(ur,3,2,2)*IJ(vr,3,1,0))*2.0+t17*t24*t56-t24*t31*t56+t24*t42*t56);
        Dq[4] = t48*(t6*(IJ(ur,3,0,0)*IJ(vr,3,2,2)-IJ(ur,3,2,0)*IJ(vr,3,0,2))*-2.0+t6*(IJ(ur,3,0,2)*IJ(vr,3,2,0)-IJ(ur,3,2,2)*IJ(vr,3,0,0))*2.0+t17*t24*t59-t24*t31*t59+t24*t42*t59);
        Dq[5] = -t48*(t6*(IJ(ur,3,0,0)*IJ(vr,3,1,2)-IJ(ur,3,1,0)*IJ(vr,3,0,2))*-2.0+t6*(IJ(ur,3,0,2)*IJ(vr,3,1,0)-IJ(ur,3,1,2)*IJ(vr,3,0,0))*2.0+t17*t24*t62-t24*t31*t62+t24*t42*t62);
        Dq[6] = t48*(t6*(IJ(ur,3,1,0)*IJ(vr,3,2,1)-IJ(ur,3,2,0)*IJ(vr,3,1,1))*-2.0+t6*(IJ(ur,3,1,1)*IJ(vr,3,2,0)-IJ(ur,3,2,1)*IJ(vr,3,1,0))*2.0+t17*t24*t65-t24*t31*t65+t24*t42*t65);
        Dq[7] = -t48*(t6*(IJ(ur,3,0,0)*IJ(vr,3,2,1)-IJ(ur,3,2,0)*IJ(vr,3,0,1))*-2.0+t6*(IJ(ur,3,0,1)*IJ(vr,3,2,0)-IJ(ur,3,2,1)*IJ(vr,3,0,0))*2.0+t17*t24*t68-t24*t31*t68+t24*t42*t68);
        Dq[8] = t48*(t6*(IJ(ur,3,0,0)*IJ(vr,3,1,1)-IJ(ur,3,1,0)*IJ(vr,3,0,1))*-2.0+t6*(IJ(ur,3,0,1)*IJ(vr,3,1,0)-IJ(ur,3,1,1)*IJ(vr,3,0,0))*2.0+t17*t24*t71-t24*t31*t71+t24*t42*t71);
    // END GENERATED CODE
}

void Dq_2(double *ur, double *vr, double *Dq)
{
    double t76, t77, t78, t79, t80, t81, t82, t83, t84, t85, t86, t87, t88, t89, t90, t91, t92, t93, t94, t95;
    // BEGIN GENERATED CODE
        t76 = IJ(ur,2,0,0)*IJ(ur,2,1,1)*2.0;
        t80 = IJ(ur,2,0,1)*IJ(ur,2,1,0)*2.0;
        t77 = t76-t80;
        t78 = 1.0/t77;
        t81 = IJ(ur,2,0,0)*IJ(vr,2,1,1);
        t82 = IJ(ur,2,1,0)*IJ(vr,2,0,1);
        t83 = t81-t82;
        t84 = t78*t83;
        t85 = IJ(ur,2,0,1)*IJ(vr,2,1,0);
        t86 = IJ(ur,2,1,1)*IJ(vr,2,0,0);
        t87 = t85-t86;
        t88 = t78*t87;
        t79 = -t84+t88+1.0/2.0;
        t89 = t79*t79;
        t90 = -t89+1.0;
        t91 = 1.0/sqrt(t90);
        t92 = IJ(ur,2,0,0)*IJ(ur,2,1,1);
        t95 = IJ(ur,2,0,1)*IJ(ur,2,1,0);
        t93 = t92-t95;
        t94 = 1.0/(t93*t93);
        Dq[0] = t91*t94*((IJ(ur,2,1,1)*IJ(ur,2,1,1))*IJ(vr,2,0,0)+IJ(ur,2,0,1)*IJ(ur,2,1,0)*IJ(vr,2,1,1)-IJ(ur,2,0,1)*IJ(ur,2,1,1)*IJ(vr,2,1,0)-IJ(ur,2,1,0)*IJ(ur,2,1,1)*IJ(vr,2,0,1));
        Dq[1] = t91*t94*((IJ(ur,2,0,1)*IJ(ur,2,0,1))*IJ(vr,2,1,0)-IJ(ur,2,0,0)*IJ(ur,2,0,1)*IJ(vr,2,1,1)+IJ(ur,2,0,0)*IJ(ur,2,1,1)*IJ(vr,2,0,1)-IJ(ur,2,0,1)*IJ(ur,2,1,1)*IJ(vr,2,0,0));
        Dq[2] = t91*t94*((IJ(ur,2,1,0)*IJ(ur,2,1,0))*IJ(vr,2,0,1)-IJ(ur,2,0,0)*IJ(ur,2,1,0)*IJ(vr,2,1,1)+IJ(ur,2,0,0)*IJ(ur,2,1,1)*IJ(vr,2,1,0)-IJ(ur,2,1,0)*IJ(ur,2,1,1)*IJ(vr,2,0,0));
        Dq[3] = t91*t94*((IJ(ur,2,0,0)*IJ(ur,2,0,0))*IJ(vr,2,1,1)-IJ(ur,2,0,0)*IJ(ur,2,0,1)*IJ(vr,2,1,0)-IJ(ur,2,0,0)*IJ(ur,2,1,0)*IJ(vr,2,0,1)+IJ(ur,2,0,1)*IJ(ur,2,1,0)*IJ(vr,2,0,0));
    // END GENERATED CODE
}

void Dr_3(double *ut, double *vt, double *Dr)
{
    // BEGIN GENERATED CODE
        Dr[0] = ut[0]*2.0-vt[0]*2.0;
        Dr[1] = ut[1]*2.0-vt[1]*2.0;
        Dr[2] = ut[2]*2.0-vt[2]*2.0;
    // END GENERATED CODE
}

void Dr_2(double *ut, double *vt, double *Dr)
{
    // BEGIN GENERATED CODE
        Dr[0] = ut[0]*2.0-vt[0]*2.0;
        Dr[1] = ut[1]*2.0-vt[1]*2.0;
    // END GENERATED CODE
}

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    const mxArray *u, *v;
    size_t m, n;
    void (*funcs[2][3])(double *, double *, double *) = { {Dr_2, Dq_2}, {Dr_3, NULL, Dq_3} };

    /* Check for proper number of arguments. */
    if (nrhs!=2) {
        mexErrMsgTxt("Two inputs required.");
    } else if (nlhs>1) {
        mexErrMsgTxt("Too many output arguments.");
    }

    u = prhs[0];
    v = prhs[1];

    /* Check argument types */
    if (!mxIsDouble(u) || mxIsComplex(u) || mxGetNumberOfDimensions(u) != 2
     || !mxIsDouble(v) || mxIsComplex(v) || mxGetNumberOfDimensions(v) != 2) {
        mexErrMsgTxt("Inputs must be real double 2D arrays.");
    }

    /* Decide what to do based on argument sizes */
    m = mxGetM(u);
    n = mxGetN(u);
    if (mxGetM(v) != m || mxGetN(v) != n) {
        mexErrMsgTxt("Inputs must have the same size.");
    }
    if ((m != 2 && m != 3)
     || (n != m && n != 1)) {
        mexErrMsgTxt("Permissible input sizes: 2x2, 2x1, 3x3, 3x1");
    }

    plhs[0] = mxCreateDoubleMatrix(1, m*n, mxREAL);
    funcs[m-2][n-1](mxGetPr(u), mxGetPr(v), mxGetPr(plhs[0]));
}
