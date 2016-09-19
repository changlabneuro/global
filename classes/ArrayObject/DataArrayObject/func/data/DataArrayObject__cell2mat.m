function obj = DataArrayObject__cell2mat(obj)

dtypes = unique(getdtypes(obj));

assert(length(dtypes) == 1,ErrorObject.errors.inconsistentDtype);
assert(strcmp(char(dtypes),'cell'),ErrorObject.errors.inputIsNotCell);

points = cellfun(@(x) cell2mat(x),obj.DataPoints,'UniformOutput',false);

obj = DataArrayObject(points{:});

end