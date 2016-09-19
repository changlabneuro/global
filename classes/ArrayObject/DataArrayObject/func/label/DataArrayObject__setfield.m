function obj = DataArrayObject__setfield(obj,field,setas,varargin)

assert(isfield(obj,field),ErrorObject.errors.fieldDoesNotExist);

points = obj.DataPoints;

for i = 1:numel(points)
    try
        points{i}.labels(field) = setas;
    catch err
        if strcmp(err.identifier,'MATLAB:nonExistentField');
            points{i}.labels = addfield(points{i}.labels,field);
            points{i}.labels(field) = setas;
        else
            error(err.message);
        end
    end
end

obj = DataArrayObject(points{:});

end