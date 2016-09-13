function out = struct2varargin(s,exclude)

fields = fieldnames(s);

if nargin > 1
    if ~iscell(exclude)
        exclude = {exclude};
    end
    
    for i = 1:length(exclude)
        fields = fields(~strcmp(fields,exclude{i}));
    end
    
    if isempty(fields)
        return;
    end
end

nfields = length(fields);
ncells = nfields * 2;

out = cell(1,ncells);
field_index = 1;

for i = 1:2:ncells
    
    out{i} = fields{field_index};
    out{i+1} = s.(fields{field_index});
    
    field_index = field_index + 1;
    
end

end