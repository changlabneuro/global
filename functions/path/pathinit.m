function pathinit()

paths = globalpath();

initial = pathfor('hannah',paths);

addpath(fullfile(initial,'paths'));

pathchange('hannah');

end