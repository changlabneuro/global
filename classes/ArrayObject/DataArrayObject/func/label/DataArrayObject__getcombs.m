%{
    DataArrayObject__getcombs - function for obtaining all unique
    combinations of unique labels in obj, within <within> label fields.

    Depends on external function allcomb, present in the DataObject folder
%}

function combs = DataArrayObject__getcombs(obj,within)

within = LabelObject.make_cell(within);

assert(iscellstr(within),ErrorObject.errors.inputIsNotCellString);
assert(obj.consistent_labels,ErrorObject.errors.inconsistentLabels);

for i = 1:numel(within)
    assert(isfield(obj,within{i}),ErrorObject.errors.fieldDoesNotExist);
end

combs = allcomb(make_cell(uniques(obj,within)));

end

%   - helper function to convert the struct output of uniques(obj) to a
%   cell array

function out = make_cell(s)

fields = fieldnames(s);
out = cell(size(fields));

for i = 1:numel(fields)
    out(i) = {s.(fields{i})};
end

end

