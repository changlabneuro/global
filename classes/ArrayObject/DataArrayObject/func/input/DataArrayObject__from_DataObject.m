function array = DataArrayObject__from_DataObject(obj)

array = cell(1,count(obj,1));
assert(isa(obj,'DataObject'),ErrorObject.errors.inputIsNotDataObject);

stp = 1;

for k = 1:count(obj,1)

fprintf('\n%d',count(obj,1));

new = obj(1);
fields = new.label_fields;

index = true(count(obj,1),1);
for i = 1:numel(fields)
    field = fields{i};
    matchlabel = char(new(field));
    index = index & eq(obj,matchlabel,field);
end

all = obj(index);

array{stp} = DataPointObject(all.data,format(all.labels)); stp = stp + 1;

obj = obj(~index);

if isempty(obj)
    break;
end

end

empty = cellfun('isempty',array); array(empty) = []; 

array = DataArrayObject(array{:});

end

%{
    helper function to convert the labels in the data object to a form the
    label object understands
%}

function labels = format(labels)

labels = structfun(@(x) unique(x)',labels,'UniformOutput',false);

end