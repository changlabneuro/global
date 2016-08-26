%   combine the fields of include into one struct

function outstruct = pathconcat(include)

outstruct = struct();
pathfields = fieldnames(include);

for i = 1:length(pathfields)
    
    current_struct = include.(pathfields{i});
    current_fields = fieldnames(current_struct);
    
    for k = 1:length(current_fields)
        
        outstruct_fields = fieldnames(outstruct);
        
        if ~isempty(outstruct_fields)
            error_handler();
        end
        
        outstruct.(current_fields{k}) = current_struct.(current_fields{k});
    end
end

function error_handler()
    if any(strcmp(outstruct_fields,current_fields{k}))
        error('Attempting to combine multiple path files with fieldname %s',current_fields{k});
    end
end


end

