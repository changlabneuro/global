function obj = LabelObject__rmfield(obj,fields)

fields = LabelObject.make_cell(fields);
            
assert(iscellstr(fields),ErrorObject.errors.inputIsNotCellString);

labs = obj.labels;

for i = 1:length(fields)
    if ~islabelfield(obj,fields{i})
        error('The field ''%s'' does not exist',fields{i});
    end

    labs = rmfield(labs,fields{i});
end

obj = LabelObject(labs);
end