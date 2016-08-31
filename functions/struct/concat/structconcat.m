%{
    structconcat.m -- function for combining the fields of multiple
    structures into a single output structure <out>. By default, attempting
    to combine multiple structures with the same fieldname(s) is an
    error; add '-overwrite' as an input to bypass this.
%}

function out = structconcat(varargin)

flag = strcmp(varargin,'-overwrite');

allow_overwrite = false;

if any(flag);
    varargin(flag) = [];
    allow_overwrite = true;
end

out = struct();
for k = 1:length(varargin)
    
    current_struct = varargin{k};
    
    if ~isstruct(current_struct)
        error('Inputs must be structs');
    end
    
    fields = fieldnames(current_struct);
    
    if isempty(fields)
        continue;
    end
    
    for j = 1:length(fields)
        current_field = fields{j};
        
        if k > 1    %   check whether the new fields conflict with the fields already
                    %   in the output structure
            all_fields = fieldnames(out);
            if any(strcmp(all_fields,current_field)) && ~allow_overwrite
                error('Fields must be unique between input structures');
            end
        end
        
        out.(current_field) = current_struct.(current_field);
        
    end
    
end


end

