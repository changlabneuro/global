function obj = DataArrayObject__array2obj(obj)

assert(isa(obj,'DataArrayObject'),'Input must be a DataArrayObject');
assert(obj.consistent_labels,ErrorObject.errors.inconsistentLabels);

sizes = getsizes(obj);

assert(length(unique(sizes(2,:))) == 1,ErrorObject.errors.inconsistentDimensions);

dtypes = unique(getdtypes(obj));

assert(length(dtypes) == 1,ErrorObject.errors.inconsistentDtype);

switch dtypes{1}
    case 'cell'
        array = cell(sum(sizes(1,:)),sizes(2,1));
    case 'double'
        array = zeros(sum(sizes(1,:)), sizes(2,1));
end

fields = allfields(obj);
labels = layeredstruct({fields},cell(size(array,1),1));

points = obj.DataPoints;

stp = 0;
for i = 1:numel(points)
    update = points{i}.data;
    update_range = (stp+1):(stp+size(update,1));
    array(update_range,:) = update;
    labels = populate_labels(points{i}.labels,fields,labels,update_range);
    stp = max(update_range);
end

obj = DataObject(array,labels);

end

function labels = populate_labels(obj,fields,labels,update_range)

obj_labels = struct(obj.labels);

for i = 1:numel(fields)
    update = obj_labels.(fields{i});
    assert(length(update) == 1,sprintf(['The label object has more than one' ...
        , ' label in field ''%s'''],fields{i}));
    labels.(fields{i})(update_range) = update;
end
    
end