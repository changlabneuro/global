function array = DataArrayObject__from_DataObject(obj,array,stp)

if nargin < 2
    array = cell(1,count(obj,1)); stp = 1;
    assert(isa(obj,'DataObject'),ErrorObject.errors.inputIsNotDataObject);
end

if isempty(obj)
    empty = cellfun('isempty',array); array(empty) = []; 
    array = DataArrayObject(array{:}); return;
end

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

array = DataArrayObject__from_DataObject(obj,array,stp);

end

%{
    helper function to convert the labels in the data object to a form the
    label object understands
%}

function labels = format(labels)

labels = structfun(@(x) unique(x)',labels,'UniformOutput',false);

end