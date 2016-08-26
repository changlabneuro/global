function loaded = paraminclude(wanted_files, current_params)

if nargin < 2
    current_params = struct();
end

if ~iscell(wanted_files)
    wanted_files = {wanted_files};
end

wanted_files = add_extension(wanted_files); %   make sure files end in .mat

pathstr = pathfor('parameters');

subfolders = only_folders(rid_super_sub_folder_references(dir(pathstr)));

if isempty(subfolders)
    loaded = load_files(wanted_files);
    return;
end

loaded = struct();

for i = 1:length(wanted_files)
    foundfile = false;
    
    for k = 1:length(subfolders)
        subfolderpath = fullfile(pathstr,subfolders(k).name);
        files = dir(subfolderpath);
        names = {files(:).name};
        
        if ~any(strcmp(names,wanted_files{i}))
            continue;
        end
        
        params = load(wanted_files{i}); params = params.params;
        
        loaded = structconcat(loaded,params);
        
        foundfile = true;
        
    end
    
    if ~foundfile
        error('Could not find file %s',wanted_files{i});
    end
    
end

%   incorporate other params, overwriting the defaults as necessary

loaded = structconcat(loaded,current_params,'-overwrite');

end

function outfiles = add_extension(files)

outfiles = files;
for i = 1:length(files)
    if isempty(strfind(files{i},'.mat'));
        outfiles{i} = [files{i} '.mat'];
    end
end

end


function loaded = load_files(files)

loaded = struct();

for i = 1:length(files)
    
    params = load(files{i}); params = params.params;
    
    loaded = structconcat(loaded,params);
    
end

end