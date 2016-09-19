function matches = DataPointObject__eq(obj,values,varargin)

%{
    test object equality if values is a DataPointObject
%}

if isa(values,'DataPointObject')
    matches = DataPointObject__DataPointObject_eq(obj,values,varargin{:}); return;
end

%{
    ensure that values are a cell array of strings
%}

values = LabelObject.make_cell(values);            
assert(iscellstr(values),ErrorObject.errors.inputIsNotCellString);

matches = eq(obj.labels,values,varargin{:});