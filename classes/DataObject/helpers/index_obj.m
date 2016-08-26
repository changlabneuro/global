function data_obj = index_obj(data_obj,ind,method)

if nargin < 3
    method = 'include';
end

ind = sum(ind,2) >= 1;

if strcmp(method,'include');

    data_obj.data = data_obj.data(ind,:);
    label_fields = fieldnames(data_obj.labels);

    for i = 1:length(label_fields)
        data_obj.labels.(label_fields{i}) = data_obj.labels.(label_fields{i})(ind);
    end

end

if strcmp(method,'del')
    
    data_obj.data(ind,:) = [];
    
    label_fields = fieldnames(data_obj.labels);

    for i = 1:length(label_fields)
        data_obj.labels.(label_fields{i})(ind) = [];
    end
    
end





