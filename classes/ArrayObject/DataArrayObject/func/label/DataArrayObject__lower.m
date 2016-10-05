function obj = DataArrayObject__lower(obj)

points = obj.DataPoints;

for i = 1:numel(points)
    points{i}.labels = lower(points{i}.labels);
end

obj = DataArrayObject(points{:});

end