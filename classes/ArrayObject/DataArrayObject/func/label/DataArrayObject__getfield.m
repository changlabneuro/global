%{
    DataArrayObject__getfield.m -- returns a cell array of data labels in
    the field <field>, as obtained from the LabelObjects in 
    <obj.DataPoints{i}.labels>
%}

function labs = DataArrayObject__getfield(obj,field,varargin)

assert(isfield(obj,field),ErrorObject.errors.fieldDoesNotExist);

points = obj.DataPoints;

labs = cell(1,numel(points));
for i = 1:numel(points)
    try
        labs{i} = points{i}.labels(field);
    catch err
        if strcmp(err.identifier,'MATLAB:nonExistentField');
            labs{i} = {'<empty>'};
        else
            error(err.message);
        end
    end
end

rows = max(cellfun(@(x) max(size(x)), labs));
cols = size(labs,2);

labs = unnest(labs,rows,cols);

end

%{
    convert labs from a cell array of cell-array strings to a single
    cell-array of strings. This way we can do strcmp(cell,'some-string')
%}

function fixed = unnest(labs,rows,cols)

fixed = repmat({'<empty>'},rows,cols);

for i = 1:rows
    fixed(i,:) = cellfun(@(x) x{i}, labs, ...
        'UniformOutput',false, 'ErrorHandler',@errorhandler);
end

end

%{
    fill with '<empty>' if there are fewer rows than what are called for
%}

function out = errorhandler(varargin)

out = '<empty>';

end