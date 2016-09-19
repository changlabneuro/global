%{
    DataArrayObject__uniques -- function for obtaining all unique labels
    present in a DataArrayObject
%}

function out_labs = DataArrayObject__uniques(obj,varargin)

all_labs = struct(); 

%{
    if specifying fields, confirm that all requested fields are present in
    the object
%}

if ~isempty(varargin)
    for i = 1:numel(varargin{1})
        assert(isfield(obj,varargin{1}{i}),ErrorObject.errors.fieldDoesNotExist);
    end
end

points = obj.DataPoints;

for i = 1:numel(points);
    current_point = points{i};
    
    if i == 1
       all_labs = current_point.labels.labels; continue; 
    end
    
    all_fields = fieldnames(all_labs);
    current_fields = current_point.labels.fields;
    
    for k = 1:length(current_fields)
        field = current_fields{k};
        
        if any(strcmp(all_fields,field))
            labs = current_point.labels(field);
            
            for j = 1:length(labs)
                if ~any(strcmp(all_labs.(field),labs{j}))
                    all_labs.(field) = ...
                        [all_labs.(field) labs{j}];
                end
            end
            
            continue;
%             all_labs.(field) = ...
%                 [all_labs.(field) current_point.labels(field)];
%             continue;
        end
        
        all_labs.(field) = current_point.labels(field);
        
    end
    
end

out_labs = struct();

if isempty(varargin)
    all_fields = fieldnames(all_labs);
else
    all_fields = varargin{1};
end

for i = 1:length(all_fields)
    field = all_fields{i};
    
    out_labs.(field) = unique(all_labs.(field));
end

end