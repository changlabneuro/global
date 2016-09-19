function obj = DataArrayObject__addfield(obj,field)

points = obj.DataPoints;
for i = 1:numel(points)
    points{i} = addfield(points{i},field);
end
obj = DataArrayObject(points{:});

end