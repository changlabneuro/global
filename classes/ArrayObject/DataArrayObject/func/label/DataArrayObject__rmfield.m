function obj = DataArrayObject__rmfield(obj,fields)

fields = LabelObject.make_cell(fields);

%{
    make sure all label fields are present
%}

for i = 1:numel(fields)
    assert(isfield(obj,fields{i}),ErrorObject.errors.fieldDoesNotExist);
end

points = obj.DataPoints;

%{
    for each data point, rmfield if it exists
%}

for i = 1:numel(points)
    try
        points{i} = points{i}.rmfield(fields);
    catch err
        if ~isempty(strfind(err.message,'does not exist'))
            continue;
        else
            error(err.message);
        end
    end
end

obj = DataArrayObject(points{:});

end