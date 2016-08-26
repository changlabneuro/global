function goto(name)

if nargin < 1
    cd(pathfor('repositories')); return;
end

pathstr = pathfor(name);

cd(pathstr);

end