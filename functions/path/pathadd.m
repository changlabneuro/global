%{
    pathadd.m -- shortcut to add all subdirectories of a defined path to
    the search path
%}

function pathadd(varargin)

for i = 1:length(varargin)
    name = varargin{i};
    addpath(genpath(pathfor(name)));
end

end