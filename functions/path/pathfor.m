%{
    
    pathfor.m -- get the path associated with <field>, as defined in
    'paths.mat'. 

    Create the 'paths.mat' file with make_paths.m, and make sure that you
    add the 'paths' directory to matlab's search path.
    
    If the specified field is not found in 'paths.mat', an error will be
    thrown.

    If the function is called without arguments, the available paths will
    be printed.
    
%}

function pathstr = pathfor(field,paths)

    if nargin < 2
        paths = load('paths.mat');
    end
    
    paths = paths.paths;
        
    if nargin < 1
        disp(paths); return;
    end
    
    %   otherwise, try to get the associated field
   
    names = fieldnames(paths);

    if ~any(strcmp(names,field))
        fprintf('\nAvailable paths are:\n\n'); disp(paths);
        error('The path for ''%s'' has not been defined. See above for defined paths.',field);
    end

    pathstr = paths.(field);
end