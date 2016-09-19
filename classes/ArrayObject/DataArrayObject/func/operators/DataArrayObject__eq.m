function matches = DataArrayObject__eq(obj,values,varargin)

%{
    test object equality if values is a DataArrayObject
%}

if isa(values,'DataArrayObject')
    matches = DataArrayObject__DataArrayObject_eq(obj,values,varargin{:}); return;
end

%{
    ensure that values are a cell array of strings
%}

values = LabelObject.make_cell(values);            
assert(iscellstr(values),ErrorObject.errors.inputIsNotCellString);

%{
    return an index
%}

matches = false(dimensions(obj));

for i = 1:numel(matches)
    matches(i) = eq(obj.DataPoints{i},values,varargin{:});
end

end