function array = DataArrayObject__from_DataObject(obj,varargin)

assert(isa(obj,'DataObject'),ErrorObject.errors.inputIsNotDataObject);

flag = any(strcmpi(varargin,'-allrows'));

array = DataArrayObject();

if flag
    
    
    return;
end

if nargin < 2
    within = obj.label_fields;
else within = varargin{1};
end

indices = getindices(obj,within);

for i = 1:length(indices)
    
    extr = obj(indices{i});
    
    data = extr.data;
    labs = extr.labels;
    fields = extr.label_fields;
    
    for k = 1:length(fields)
       labs.(fields{k}) = unique(labs.(fields{k})); 
    end
    
    new_array = DataArrayObject(...
        DataPointObject(data,labs));
    
    array = [array new_array];
    
end

end
