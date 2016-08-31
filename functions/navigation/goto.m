%{

    goto.m -- function for cd'ing into a path defined in make_paths.m.
    Refer to the documentation on path functions in functions/path for more
    information.

%}

function goto(name)

if nargin < 1
    cd(pathfor('repositories')); return;
end

pathstr = pathfor(name);

cd(pathstr);

end