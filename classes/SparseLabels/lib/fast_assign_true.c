#include "mex.h"
#include <stdbool.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 2)
    {
        mexErrMsgIdAndTxt("fast_assign_true:main", "Wrong number of inputs.");
    }
    
    if (nlhs != 1)
    {
        mexErrMsgIdAndTxt("fast_assign_true:main", "Wrong number of outputs.");
    }
    
    const mxArray* in_indices = prhs[0];
    const mxArray* in_size = prhs[1];
    
    mxClassID indices_id = mxGetClassID(in_indices);
    mxClassID size_id = mxGetClassID(in_size);
    
    if (indices_id != mxCELL_CLASS)
    {
        mexErrMsgIdAndTxt("fast_assign_true:main", "Indices must be cell array.");
    }
    
    if (size_id != mxDOUBLE_CLASS)
    {
        mexErrMsgIdAndTxt("fast_assign_true:main", "Size must be double.");
    }
    
    size_t n_indices = mxGetNumberOfElements(in_indices);
    size_t n_size = mxGetNumberOfElements(in_size);
    
    if (n_size != 1)
    {
        mexErrMsgIdAndTxt("fast_assign_true:main", "Size must be scalar.");
    }
    
    size_t size = mxGetScalar(in_size);
    
    mxArray* out = mxCreateCellMatrix(n_indices, 1);
    
    for (size_t i = 0; i < n_indices; i++)
    {
        mxArray* num_indices = mxGetCell(in_indices, i);
        
        if (mxGetClassID(num_indices) != mxUINT64_CLASS)
        {
            for (size_t j = 0; j < i; j++)
            {
                mxDestroyArray(mxGetCell(out, j));
            }
            
            mxDestroyArray(out);
            mexErrMsgIdAndTxt("fast_assign_true:main", "Indices must be uint64.");
        }
        
        size_t n_num_indices = mxGetNumberOfElements(num_indices);
        uint64_t* num_inds_ptr = (uint64_t*) mxGetData(num_indices);
        
        mxArray* logical_inds = mxCreateLogicalMatrix(size, 1);
        bool* logical_inds_ptr = (bool*) mxGetLogicals(logical_inds);
        
        for (size_t j = 0; j < n_num_indices; j++)
        {
            logical_inds_ptr[num_inds_ptr[j]] = true;
        }
        
        mxSetCell(out, i, logical_inds);
    }
    
    plhs[0] = out;
}