%{
    DataArrayObject__uniques -- function for obtaining all unique labels
    present in a DataArrayObject
%}

function out_labs = DataArrayObject__uniques(obj,varargin)

%{
    if specifying fields, confirm that all requested fields are present in
    the object
%}

if ~isempty(varargin)
    for i = 1:numel(varargin{1})
        assert(isfield(obj,varargin{1}{i}),ErrorObject.errors.fieldDoesNotExist);
    end
end

if obj.consistent_labels    %   if we know the labels are consistent, we can use
                            %   a slightly faster function
    out_labs = consistent_labels(obj,varargin{:}); return;
end

out_labs = inconsistent_labels(obj,varargin{:}); return;

end

function all_labs = consistent_labels(obj, varargin)

if isempty(varargin)
    fields = obj{1}.labels.fields;
else fields = varargin{1};
end

all_labs = layeredstruct({fields},cell(1,count(obj)));
stps = layeredstruct({fields},0);

points = obj.DataPoints;

for i = 1:numel(points)
    for k = 1:numel(fields)
        field = fields{k};
        to_update = points{i}.labels(field);
        
        stp = stps.(field);
        update = numel(to_update);
        all_labs.(field)(stp+1:stp+update) = to_update;
        
        stps.(field) = stps.(field) + update;
    end
end


for i = 1:numel(fields)
    all_labs.(fields{i}) = unique(all_labs.(fields{i}));
end

end

%{
    if labels are inconsistent
%}

function out_labs = inconsistent_labels(obj,varargin)

all_labs = struct();

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