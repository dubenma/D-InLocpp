### Inpaint_Nans

`inpaint_nans.m` is used for filling in `NaN` values in images (or data).

These files were copied from the MATLAB file-exchange directory by John d'Errico ([link](https://www.mathworks.com/matlabcentral/fileexchange/4551-inpaint-nans)).

For a simple demo of what the function does, type (in MATLAB)
```matlab
>> inpaint_nans_demo
```

### Julia version

Thanks to John d'Errico's permission, a julia version is available via the [Inpaintings.jl](https://github.com/briochemc/Inpaintings.jl) package. 
It can also inpaint `missing` or any other value, allows for cyclic dimensions, and works for generalized *n*-dimensional arrays.
Check it out!
