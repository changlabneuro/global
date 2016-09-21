function obj = DataArrayObject__replace(obj,searchfor,with,varargin)

searchfor = LabelObject.make_cell(searchfor);

for i = 1:numel(searchfor)
    obj = internal__replace(obj,searchfor{i},with,varargin{:});
end

end

function obj = internal__replace(obj,searchfor,with,varargin)

points = obj.DataPoints;

found = zeros(size(points));

for i = 1:numel(points);
    [points{i}.labels, found(i)] = ...
        replace(points{i}.labels,searchfor,with,varargin{:});
end

if ~any(found)
    fprintf('\nCould not find ''%s''',searchfor);
else fprintf('\nMade %d replacements', sum(found));
end

obj = DataArrayObject(points{:});

end