function obj = DataArrayObject__determine_consistency(obj)

%{
    determine if label fields are consistent
%}

obj.consistent_labels = true;
obj.consistent_data = true;

data = obj.DataPoints;

for i = 1:numel(data)
    one_label = data{i}.labels;
    
    if i == 1
        store_label = one_label; continue;
    end
    
    if any(size(one_label.fields) ~= size(store_label.fields))
        obj.consistent_labels = false; break;
    end
    
    if ~strcmp(sort(one_label.fields), sort(store_label.fields))
        obj.consistent_labels = false; break;
    end
    
end

%{
    determine if data types / sizes are consistent
%}

for i = 1:numel(data)
    one_point = data{i};
    
    if i == 1
        store_point = one_point; continue;
    end
    
    if ~eq(one_point,store_point,'-ignoreLabels')
        obj.consistent_data = false; break;
    end
    
end

obj.consistent_obj = obj.consistent_data & obj.consistent_labels;
end