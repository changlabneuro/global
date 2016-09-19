function sizes = DataArrayObject__getsizes(obj)

points = obj.DataPoints;

sizes = zeros(2,dimensions(obj,2));

for i = 1:numel(points)
    sizes(:,i) = dimensions(points{i});
end

end