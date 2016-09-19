function obj = LabelObject__replace(obj,searchfor,with)

assert(ischar(searchfor),ErrorObject.errors.inputIsNotString);
assert(ischar(with),ErrorObject.errors.inputIsNotString);

%   right now, can only replace values present in one field

[present, field] = obj == searchfor;

if ~present
    fprintf('\nCould not find ''%s''',searchfor); return;
end

if strncmpi(searchfor,'*',1)
    searchfor = searchfor(2:end);   %   remove '*';
end

field = field{1};

labs = obj(field);

matches = cellfun(@(x) strfind(x,searchfor),labs,'UniformOutput',false);
empty = cellfun('isempty',matches);

labs(empty) = [];
matches(empty) = [];

for k = 1:numel(labs)
    current = labs{k};
    from = matches{k};
    to = from + length(searchfor) - 1;
    
    current(from:to) = [];
    
    if from == 1
        labs{k} = [with current];
    else
        error('Cannot currently replace strings in the middle of labels');
    end
end

obj(field) = labs;

end