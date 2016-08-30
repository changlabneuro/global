%{
    structfieldconcat.m -- function for concatenating structures
    field-by-field. Demands that structures have equivalent fields (will
    throw an error otherwise). By default, will concatenate data
    horizontally; specify 'vert' to concatenate vertically

    E.g.:   structure1.data = 1; structure1.data2 = 2; 
            structure2.data = 1; structure2.data2 = 2;

    newstruct = structfieldconcat(structure1,structure2)
    
    %   newstruct.data = [1 1]; newstruct.data2 = [2 2];
%}


function outstruct = structfieldconcat(varargin)

method_index = cellfun(@(x) isa(x,'char'), varargin);

if ~any(method_index)
    method = 'vert';
else
    inputted_method = char(varargin(method_index));
    if strcmp(inputted_method,'horz')
        method = 'horz';
    elseif strcmp(inputted_method,'vert')
        method = 'vert';
    else
        error('Method can only be ''horz'' or ''vert''');
    end
    varargin(method_index) = []; % leave only structures in varargin
end

for i = 1:length(varargin)
    
    onestruct = varargin{i};
    
    if ~isa(onestruct,'struct')
        error('Inputs must be structures');
    end
    
    fields = fieldnames(onestruct);
    
    %   if this is the first input, just transfer the fields into the
    %   new struct

    if i == 1
        outstruct = onestruct; prev_fields = fields; continue;
    end
    
    validate_fields(prev_fields,fields);
    
    for j = 1:length(fields)
        
        %   otherwise, concatenate, either horizontally or vertically
        
        if strcmp(method,'horz')
            outstruct.(fields{j}) = [outstruct.(fields{j}) onestruct.(fields{j})];
        elseif strcmp(method,'vert');
            outstruct.(fields{j}) = [outstruct.(fields{j}); onestruct.(fields{j})];
        end
        
    end
    
    prev_fields = fields;
    
end

end

function validate_fields(current_fields,new_fields)

for i = 1:length(new_fields)
    if ~any(strcmp(current_fields,new_fields{i}))
        error('The inputted structures don''t have equivalent fields');
    end
end

end
