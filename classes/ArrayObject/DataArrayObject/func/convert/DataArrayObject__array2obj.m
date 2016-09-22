function obj = DataArrayObject__array2obj(obj)

assert(isa(obj,'DataArrayObject'),'Input must be a DataArrayObject');
assert(obj.consistent_labels,ErrorObject.errors.inconsistentLabels);

sizes = getsizes(obj);
sizes = unique(sizes','rows');

assert(size(sizes,1) == 1,ErrorObject.errors.inconsistentDimensions);

dtypes = unique(getdtypes(obj));

assert(length(dtypes) == 1,ErrorObject.errors.inconsistentDtype);

switch dtypes{1}
    case 'cell'
        array = cell(count(obj),sizes(2));
    case 'double'
        array = zeros(count(obj)*sizes(1), sizes(2));
        
end

fields = allfields(obj);
labels = layeredstruct({fields},cell(size(array,1),1));

points = obj.DataPoints;

stp = 1;
for i = 1:numel(points)
    update = points{i}.data;
    array(stp,:) = update; 
    labels = populate_labels(points{i}.labels,fields,labels,stp);
    stp = stp + 1;
end

obj = DataObject(array,labels);

end

function labels = populate_labels(obj,fields,labels,stp)

obj_labels = struct(obj.labels);

for i = 1:numel(fields)
    update = obj_labels.(fields{i});
    assert(length(update) == 1,sprintf(['The label object has more than one' ...
        , ' label in field ''%s'''],fields{i}));
    labels.(fields{i})(stp) = update;
end
    
end