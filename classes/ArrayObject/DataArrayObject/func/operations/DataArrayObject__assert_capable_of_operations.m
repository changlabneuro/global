function DataArrayObject__assert_capable_of_operations(obj,values,varargin)

type_is_DataArrayObject = false;

if isa(values,'DataArrayObject')
    values = values.DataPoints;
    
    assert(all(dimensions(obj) == size(values)),...
        ErrorObject.errors.inconsistentDimensions);
    
    type_is_DataArrayObject = true;
end

points = obj.DataPoints;

for i = 1:numel(points)
    if ~type_is_DataArrayObject
        assert_capable_of_operations(points{i},values);
        continue;
    end
    
    assert_capable_of_operations(points{i},values{i});
end

end