%{
    createstruct.m - function for initializing a struct with a number of
    fields. If <fillwith> is not specified, each field will be an empty
    matrix. If <fillwith> is 
%}

function out = createstruct(fields,varargin)

fillwith = varargin;

if isempty(fillwith)
    fillwith = cell(1);
end

if ~iscell(fields)
    error('Fields must be inputted as a cell array');
end

if (length(fillwith) == 1)
    fillwith = repmat(fillwith(1),1,length(fields));
    
elseif (length(fillwith) ~= length(fields))
    error(['If filling each field separately, all fields must have a' ...
        , ' corresponding <fillwith>']);
end

out = struct();

for i = 1:length(fields)
    
    field = fields{i};
    out.(field) = fillwith{i};
    
end

end