#include "cMathCUDAKernels.h"
#define KAPPA1 (3.14159 - 1.9391)
#define KAPPA2 (3.14159 - 2.061)
#define KAPPA3 (3.14159 -2.1186)
#define OMEGACIS -3.1318

#define R_CA_C 1.525
#define R_C_N 1.330
#define R_N_CA 1.460

#define CA_C_N (M_PI - 2.1186)
#define C_N_CA (M_PI - 1.9391)
#define N_CA_C  (M_PI - 2.061)


__device__ void getRotationMatrix(double *d_data, double alpha, double beta, double R){
	d_data[0]=cos(alpha);   d_data[1]=-sin(alpha)*cos(beta);d_data[2]=sin(alpha)*sin(beta);	d_data[3]=-R*sin(alpha)*cos(beta);
	d_data[4]=sin(alpha);	d_data[5]=cos(alpha)*cos(beta); d_data[6]=-cos(alpha)*sin(beta);d_data[7]=R*cos(alpha)*cos(beta);
	d_data[8]=0.0;   		d_data[9]=sin(beta);			d_data[10]=cos(beta); 			d_data[11]=R*sin(beta);
	d_data[12]=0.0;			d_data[13]=0.0;					d_data[14]=0.0;		 			d_data[15]=1.0;
}

__device__ void get33RotationMatrix(double *d_data, double alpha, double beta){
    d_data[0]=cos(alpha);   d_data[1]=-sin(alpha)*cos(beta);d_data[2]=sin(alpha)*sin(beta);	
	d_data[3]=sin(alpha);	d_data[4]=cos(alpha)*cos(beta); d_data[5]=-cos(alpha)*sin(beta);
	d_data[6]=0.0;   		d_data[7]=sin(beta);			d_data[8]=cos(beta); 			
}

__device__ void getRotationMatrixDAlpha(double *d_data, double alpha, double beta, double R){
	d_data[0]=-sin(alpha);  d_data[1]=-cos(alpha)*cos(beta);    d_data[2]=cos(alpha)*sin(beta);		d_data[3]=-R*cos(alpha)*cos(beta);
	d_data[4]=cos(alpha);   d_data[5]=-sin(alpha)*cos(beta); 	d_data[6]=sin(alpha)*sin(beta);		d_data[7]=-R*sin(alpha)*cos(beta);
	d_data[8]=0.0;   		d_data[9]=0.0;				 	    d_data[10]=0.0; 					d_data[11]=0.0;
	d_data[12]=0.0;			d_data[13]=0.0;					    d_data[14]=0.0;		 				d_data[15]=0.0;
}

__device__ void get33RotationMatrixDAlpha(double *d_data, double alpha, double beta){
	d_data[0]=-sin(alpha);  d_data[1]=-cos(alpha)*cos(beta);    d_data[2]=cos(alpha)*sin(beta);
	d_data[3]=cos(alpha);   d_data[4]=-sin(alpha)*cos(beta); 	d_data[5]=sin(alpha)*sin(beta);
	d_data[6]=0.0;   		d_data[7]=0.0;				 	    d_data[8]=0.0; 			
}

__device__ void getRotationMatrixDBeta(double *d_data, double alpha, double beta, double R){
	d_data[0]=0.0;          d_data[1]=sin(alpha)*sin(beta);	d_data[2]=sin(alpha)*cos(beta);		d_data[3]=R*sin(alpha)*sin(beta);
	d_data[4]=0.0;			d_data[5]=-cos(alpha)*sin(beta); 	d_data[6]=-cos(alpha)*cos(beta);    d_data[7]=-R*cos(alpha)*sin(beta);
	d_data[8]=0.0;   		d_data[9]=cos(beta); 				d_data[10]=-sin(beta); 				d_data[11]=R*cos(beta);
	d_data[12]=0.0;			d_data[13]=0.0;					    d_data[14]=0.0;		 				d_data[15]=0.0;
}

__device__ void get33RotationMatrixDBeta(double *d_data, double alpha, double beta){
	d_data[0]=0.0;          d_data[1]=sin(alpha)*sin(beta);	    d_data[2]=sin(alpha)*cos(beta);	
	d_data[3]=0.0;			d_data[4]=-cos(alpha)*sin(beta); 	d_data[5]=-cos(alpha)*cos(beta);
	d_data[6]=0.0;   		d_data[7]=cos(beta); 				d_data[8]=-sin(beta); 			
}

__device__ void getRotationMatrixDihedral(double *d_data, double a, double b, double R){
	d_data[0]=cos(b); 	d_data[1]=sin(a)*sin(b);	d_data[2]=cos(a)*sin(b);	d_data[3]=R*cos(b);
	d_data[4]=0;		d_data[5]=cos(a); 			d_data[6]=-sin(a);			d_data[7]=0;
	d_data[8]=-sin(b);  d_data[9]=sin(a)*cos(b);	d_data[10]=cos(a)*cos(b);	d_data[11]=-R*sin(b);
	d_data[12]=0.0;		d_data[13]=0.0;				d_data[14]=0.0;				d_data[15]=1.0;
}
__device__ void getRotationMatrixDihedralDPsi(double *d_data, double psi, double kappa, double R){
	d_data[0]=-sin(psi)*cos(kappa); 	d_data[1]=sin(psi)*sin(kappa);	d_data[2]=cos(psi);	d_data[3]=0;
	d_data[4]=0.0;						d_data[5]=0.0;	 				d_data[6]=0;		d_data[7]=0;
	d_data[8]=-cos(psi)*cos(kappa); 	d_data[9]=cos(psi)*sin(kappa);	d_data[10]=-sin(psi);d_data[11]=0.0;
	d_data[12]=0.0;						d_data[13]=0.0;					d_data[14]=0.0;		d_data[15]=0.0;
}

__device__ void getRotationMatrixCalpha(double *d_data, double phi, double psi, bool first){
	// getRotationMatrixDihedral(d_data, 0.0, psi);
	double A[16], B[16], Bp[16], C[16], D[16];
	if(first){
		getRotationMatrixDihedral(d_data, phi, C_N_CA, R_N_CA);
	}else{
		getRotationMatrixDihedral(B, psi, N_CA_C, R_CA_C);
		getRotationMatrixDihedral(C, OMEGACIS, CA_C_N, R_C_N);
		getRotationMatrixDihedral(A, phi, C_N_CA, R_N_CA);	
		mat44Mul(B, C, D);
		mat44Mul(D, A, d_data);	
	}
}

__device__ void getRotationMatrixCalphaDPhi(double *d_data, double phi, double psi){
	// getRotationMatrixDihedral(d_data, 0.0, psi);
	double A[16],B[16],C[16],D[16];
	getRotationMatrixDihedralDPsi(A, phi, KAPPA1, R_N_CA);
	getRotationMatrixDihedral(B, OMEGACIS, KAPPA2, R_CA_C);
	getRotationMatrixDihedral(C, OMEGACIS, KAPPA3, R_C_N);

	mat44Mul(B, C, D);
	mat44Mul(D, A, d_data);
}

__device__ void getRotationMatrixCalphaDPsi(double *d_data, double phi, double psi){
	// getRotationMatrixDihedral(d_data, 0.0, psi);
	double A[16],B[16],C[16],D[16];
	getRotationMatrixDihedral(A, phi, KAPPA1, R_N_CA);
	getRotationMatrixDihedralDPsi(B, psi, KAPPA2, R_CA_C);
	getRotationMatrixDihedral(C, OMEGACIS, KAPPA3, R_C_N);

	mat44Mul(B, C, D);
	mat44Mul(D, A, d_data);
}


__device__ void getIdentityMatrix44(double *d_data){
	d_data[0]=1.0;          d_data[1]=0.0;	d_data[2]=0.0;  d_data[3]=0.0;
	d_data[4]=0.0;			d_data[5]=1.0; 	d_data[6]=0.0;  d_data[7]=0.0;
	d_data[8]=0.0;   		d_data[9]=0.0; 	d_data[10]=1.0; d_data[11]=0.0;
	d_data[12]=0.0;			d_data[13]=0.0;	d_data[14]=0.0;	d_data[15]=1.0;
}

__device__ void getIdentityMatrix33(double *d_data){
	d_data[0]=1.0;          d_data[1]=0.0;	d_data[2]=0.0;
	d_data[3]=0.0;			d_data[4]=1.0; 	d_data[5]=0.0;
	d_data[6]=0.0;   		d_data[7]=0.0; 	d_data[8]=1.0;
}

__device__ void setMat44(double *d_dst, double *d_src){
	memcpy(d_dst, d_src, 16*sizeof(double));
}
__device__ void setMat33(double *d_dst, double *d_src){
	memcpy(d_dst, d_src, 9*sizeof(double));
}

__device__ void mat44Mul(double *d_m1, double *d_m2, double *dst){
	if(dst == d_m1 || dst == d_m2){
		double tmp[16];
		for(int i=0;i<4;i++){
			for(int j=0;j<4;j++){
				tmp[i*4 + j] = 0.0;
				for(int k=0; k<4; k++){
					tmp[i*4+j] += d_m1[i*4+k]*d_m2[k*4+j];
				}
			}
		}
		memcpy(dst, tmp, 16*sizeof(double));
	}else{
		for(int i=0;i<4;i++){
			for(int j=0;j<4;j++){
				dst[i*4 + j] = 0.0;
				for(int k=0; k<4; k++){
					dst[i*4+j] += d_m1[i*4+k]*d_m2[k*4+j];
				}
			}
		}
	}
}

__device__ void mat33Mul(double *d_m1, double *d_m2, double *dst){
	if(dst == d_m1 || dst == d_m2){
		double tmp[9];
		for(int i=0;i<3;i++){
			for(int j=0;j<3;j++){
				tmp[i*3 + j] = 0.0;
				for(int k=0; k<3; k++){
					tmp[i*3+j] += d_m1[i*3+k]*d_m2[k*3+j];
				}
			}
		}
		memcpy(dst, tmp, 9*sizeof(double));
	}else{
		for(int i=0;i<3;i++){
			for(int j=0;j<3;j++){
				dst[i*3 + j] = 0.0;
				for(int k=0; k<3; k++){
					dst[i*3+j] += d_m1[i*3+k]*d_m2[k*3+j];
				}
			}
		}
	}
}


__device__ void mat44Vec4Mul(double *d_m, double *d_v, double *dst){
	if(dst == d_v){
		double tmp[4];
		for(int i=0;i<4;i++){
			tmp[i] = 0.0;
			for(int j=0;j<4;j++){
				tmp[i] += d_m[i*4+j]*d_v[j];
			}
		}
		memcpy(dst, tmp, 4*sizeof(double));
	}else{
		for(int i=0;i<4;i++){
			dst[i] = 0.0;
			for(int j=0;j<4;j++){
				dst[i] += d_m[i*4+j]*d_v[j];
			}
		}
	}
}

__device__ void mat33Vec3Mul(double *d_m, double *d_v, double *dst){
	if(dst == d_v){
		double tmp[3];
		for(int i=0;i<3;i++){
			tmp[i] = 0.0;
			for(int j=0;j<3;j++){
				tmp[i] += d_m[i*3+j]*d_v[j];
			}
		}
		memcpy(dst, tmp, 3*sizeof(double));
	}else{
		for(int i=0;i<3;i++){
			dst[i] = 0.0;
			for(int j=0;j<3;j++){
				dst[i] += d_m[i*3+j]*d_v[j];
			}
		}
	}
}

__device__ void mat44Vec3Mul(double *d_m, double *d_v, double *dst){
   double tmp[4];
   memcpy(tmp, d_v, 3*sizeof(double));tmp[3]=1.0;
   mat44Vec4Mul(d_m, tmp, dst);
}

__device__ void setVec3(double *d_v, double x, double y, double z){
	d_v[0]=x;d_v[1]=y;d_v[2]=z;
}

__device__ void setVec3(double *src, double *dst){
	dst[0]=src[0];dst[1]=src[1];dst[2]=src[2];
}

__device__ double vec3Mul(double *v1, double *v2){
	return v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2];
}

__device__ void extract33RotationMatrix(double *mat44, double *mat33){
	for(int i=0;i<3;i++)	
		for(int j=0;j<3;j++)
			mat33[3*i+j] = mat44[4*i+j];
}

__device__ void vec3Mul(double *u, double lambda){
	u[0]*=lambda;u[1]*=lambda;u[2]*=lambda;
}
__device__ double vec3Dot(double *v1, double *v2){
	return v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2];
}

__device__ void vec3Cross(double *u, double *v, double *w){
	w[0] = u[1]*v[2] - u[2]*v[1];
	w[1] = u[2]*v[0] - u[0]*v[2];
	w[2] = u[0]*v[1] - u[1]*v[0];
}

__device__ double getVec3Norm(double *u){
	return sqrt(vec3Dot(u,u));
}

__device__ void vec3Normalize(double *u){
	vec3Mul(u, 1.0/getVec3Norm(u));
}

__device__ void vec3Minus(double *vec1, double *vec2, double *res){
	res[0] = vec1[0]-vec2[0];res[1] = vec1[1]-vec2[1];res[2] = vec1[2]-vec2[2];
}	
__device__ void vec3Plus(double *vec1, double *vec2, double *res){
	res[0] = vec1[0]+vec2[0];res[1] = vec1[1]+vec2[1];res[2] = vec1[2]+vec2[2];
}	
