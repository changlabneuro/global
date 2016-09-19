function obj = DataArrayObject__replace(obj,searchfor,with)

points = obj.DataPoints;

for i = 1:numel(points);
    points{i}.labels = replace(points{i}.labels,searchfor,with);
end

obj = DataArrayObject(points{:});

end