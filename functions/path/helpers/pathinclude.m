%   varargin paths should be .mat files to other paths

function allpaths = pathinclude(paths,varargin)

%   add input paths

for k = 1:length(varargin)
    loadedpath = load(varargin{k});
    include.(sprintf('path%d',k)) = loadedpath.paths;
end

%   add <paths> as final input

include.(sprintf('path%d',k+1)) = paths;

%   combine all paths

allpaths = pathconcat(include);

end