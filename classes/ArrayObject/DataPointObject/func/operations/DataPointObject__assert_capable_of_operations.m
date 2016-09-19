function DataPointObject__assert_capable_of_operations(obj,varargin)

values = varargin{1};

switch class(values)
    case 'DataPointObject'
        assert(obj.labels == values.labels, ErrorObject.errors.inconsistentLabels);
        
        assert(~any(dimensions(obj) ~= dimensions(values)),...
            ErrorObject.errors.inconsistentDimensions);
        
        assert(strcmp(obj.dtype,values.dtype),...
            ErrorObject.errors.inconsistentDtype);
        
    case 'double'
        if ~all(size(values) == 1)
            assert(~any(dimensions(obj) ~= size(values)),...
                ErrorObject.errors.inconsistentDimensions);
        end
        
    otherwise
        error('Operations on data type ''%s'' are currently unsupported' ...
            , class(values));
end


end