function obj = DataArrayObject__multiply(obj,values)

assert_capable_of_operations(obj,values);

points = obj.DataPoints;

for i = 1:numel(points)
    
    if isa(values,'DataArrayObject')
        points{i} = points{i} .* values{i}; continue;
    end
    
    points{i} = points{i} .* values;
    
end

obj = DataArrayObject(points{:});

end