%{
    finder.m - function for interfacing with OSX's finder. For now, the
    function only serves to open a new finder window in the directory
    specified by 'open',<path>. Calling finder without arguments opens a
    finder window from matlab's current directory
%}

function finder(varargin)

params = struct(...
    'function','open', ...
    'open','.' ...
);

params = parsestruct(params,varargin);

switch params.function
    case 'open'
        file = params.open;
        open(file);
    otherwise
        error('Unrecognized function ''%s''',params.function);
end

end

function open(path)

eval(sprintf('!open %s',path));

end