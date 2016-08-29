function concatenated = concatenate_data_obj(varargin)

validate(varargin);

concatenated = struct();
concatenated.data = [];
concatenated.labels = struct();

label_fields = fieldnames(varargin{1}.labels);

for i = 1:length(label_fields)
    concatenated.labels.(label_fields{i}) = [];
end

for i = 1:length(varargin)
    data_obj = varargin{i};    
    concatenated.data = vertcat(concatenated.data,data_obj.data);
    for j = 1:length(label_fields)
        concatenated.labels.(label_fields{j}) = vertcat(...
            concatenated.labels.(label_fields{j}),data_obj.labels.(label_fields{j}));
    end
end

end

function validate(objs)

    if length(objs) == 1
        error('Specify at least two objs to concatenate');
    end
    
    for i = 1:length(objs)
        if i == 1
            store_labels = fieldnames(objs{i}.labels);
            store_size = size(objs{i}.data);
            continue;
        end
        
        if isempty(objs{i})
            continue;   %   allow concatenation of empty objects
        end
        
        %   validate data

        data_sizes = size(objs{i}.data);
        if data_sizes ~= store_size & sum(store_size) ~= 0
            error('Dimension mismatch in the data to be concatenated');
        end
        store_size = data_sizes;

        %   validate labels

        data_labels = fieldnames(objs{i}.labels);
        if length(data_labels) ~= length(store_labels)
            error('Unequal number of labels b/w data to be concatenated')
        end
        for j = 1:length(data_labels)
            if ~any(strcmp(store_labels,data_labels{j}))
                error('Label field mismatch');
            end
        end
        store_labels = data_labels;
        
    end
    
end