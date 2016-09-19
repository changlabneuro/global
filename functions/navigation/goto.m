%{

    goto.m -- function for cd'ing into a path defined in make_paths.m.
    Refer to the documentation on path functions in functions/path for more
    information.

    Can call goto('back') to head to the previous folder visited via goto

%}

function goto(name)

%   - keep track of where we've been with <last>

persistent last;

if isempty(last)
    last = cd;
end

%   - without arguments, go to the repositories folder

if nargin < 1
    cd(pathfor('repositories')); return;
end

%   - if goto('back') -> goto(<last>), and mark <last> as the current direc

if strcmp(name,'back')
   curr = cd; cd(last); last = curr; return; 
end

% - otherwise, get the <name> of the path in paths.mat, and cd(<path>)

pathstr = pathfor(name);

cd(pathstr);

end