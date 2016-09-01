%{

    make_dependencies.m -- script for establishing the required
    dependencies to be checked by verify_compatability.m

%}

depends = struct(...
    'DataObject',VersionObject(...
        'release',0, ...
        'revision',1 ...
    ) ...
);

savepath = fullfile(pathfor('global'),'dependencies');
filename = fullfile(savepath,'depends.mat');

save(filename,'depends');