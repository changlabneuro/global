%{
    validfieldnames.m - helper function to convert strings to valid
    fieldnames.
%}

function fixed = validfieldnames(varargin)

fields = varargin;
fixed = fields;

for i = 1:length(fields)
    
    if ~ischar(fields{i})
        error('Inputs must be strings');
    end
    
    alphabetic = isstrprop(fields{i},'alpha');
    numeric = isstrprop(fields{i},'digit');
    
    if numeric(1)
        error('Fieldnames cannot begin with a number');
    end
    
    acceptable = alphabetic | numeric;
    
    fixed{i} = fields{i}(acceptable);
    
end

end