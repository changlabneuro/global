function pathinit(name)

if nargin < 1
    name = 'hannah';
end

paths = globalpath();

initial = pathfor(name,paths);

addpath(fullfile(initial,'paths'));

pathchange(name);

end