%{

    verify_compatability.m -- function for ensuring that 

%}

function verify_compatability(obj)

depends = load(fullfile(pathfor('global'),'dependencies','depends.mat'));
depends = depends.depends;

type = class(obj);

types = fieldnames(depends);

if ~any(strcmp(types,type))
    error('No dependency has been defined for class ''%s''', type);
end

given = obj.meta.version;   %   given and required are both VersionObjects,
                            %   with overloaded lt, gt, le, and ge
                            %   operators
required = depends.(type);

if given < required
    fprintf('\nUpdate your %s to ''%s''\n\n', type, required.name);
    error(['The %s you are using does not meet the requirements specified' ...
        , ' in depends.mat'], type);
end


end