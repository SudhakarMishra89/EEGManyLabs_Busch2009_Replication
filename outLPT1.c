
#include "mex.h" 
#include <conio.h>
#include "matrix.h"
#include "io.h"
#include "io.cpp"

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 

/* Input Arguments: 1 byte for LPT1 */
//#define	B_IN	prhs[0]

{	int m,n,bint;
	double *b;        		/* argument coming from matlab */
	unsigned char bchar;	/* the byte we output */
	int port;
    //int tester;
	if (nrhs != 1) {
		mexErrMsgTxt("OUTP(B) requires a single integer to write to LPT1. etape1");
	} else if (nlhs != 0) {
		mexErrMsgTxt("OUTP requires no output arguments.");
	}
  
	m = mxGetM(prhs[0]);
	n = mxGetN(prhs[0]);
    /*    mode debug
    mexPrintf("Hello World\n"); 
  	mexPrintf("n=%d, m=%d : Hello World\n",n,m);
    tester=mxIsNumeric(prhs[0]);
    mexPrintf("tester=%d,: IsNumeric, attendu: 1\n",tester);
     tester=mxIsComplex(prhs[0]);
    mexPrintf("tester=%d,: IsComplex, attendu: 0\n",tester);
     tester=mxIsSparse(prhs[0]);
    mexPrintf("tester=%d,: IsSparse, attendu: 0\n",tester);
     tester=mxIsDouble(prhs[0]);
    mexPrintf("tester=%d,: IsDouble, attendu: 1\n",tester);
     */
	if (!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0]) || 
		mxIsSparse(prhs[0])  || !mxIsDouble(prhs[0]) ||
		(m != 1) || (n != 1)) {
		mexErrMsgTxt("OUTP(B) requires a single integer to write to LPT1. etape2");
	}

	b = mxGetPr(prhs[0]);
  //  mexPrintf("b=%8.4f,hello\n",b);
  //   tester=mxIsDouble(prhs[0]);
	bint = (int)(*b);

	if ( ((*b)-bint>0.00001) || (bint-(*b)>0.00001) || (bint<0) || (bint>255) ) {
		mexErrMsgTxt("OUTP(B) requires an integer B, 0<=B<=255.");
	}

/* For debugging:

    mexPrintf("Hello World\n"); 
  	mexPrintf("*b=%8.4f, bint=%d : Hello World\n",*b,bint); 

    mexPrintf( "f1 = %8.4f f2 = %10.2E x = %#08x i = %d\n",
            23.45,      3141.5926,   0x1db,     -1 );
*/
	bchar = (unsigned char) bint;

	//mexPrintf("on a passé le bchar\n");
    
    port = 0x378; /* LPT1 */
    LoadIODLL();
	PortOut(port, bchar);
    
    //mexPrintf("on a passé le outp\n");
    
    return;
    

} 
/*--------------------------------------------*/ 


