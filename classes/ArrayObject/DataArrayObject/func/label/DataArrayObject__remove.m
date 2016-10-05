function obj = DataArrayObject__remove(obj, labels)

labels = LabelObject.make_cell(labels);
assert(iscellstr(labels), ErrorObject.errors.inputIsNotCellString);

ind = false(dimensions(obj));

for i = 1:numel(labels)
    ind = ind | obj == labels{i};
end

obj = obj(~ind);

end