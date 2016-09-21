function [obj, found] = LabelObject__replace(obj,searchfor,with,varargin)

params = struct(...
    'method','complete' ...
);

params = parsestruct(params,varargin);

%   searchfor and with must be strings

assert(ischar(searchfor),ErrorObject.errors.inputIsNotString);
assert(ischar(with),ErrorObject.errors.inputIsNotString);

%   right now, can only replace values present in one field

[present, field] = obj == searchfor;

if ~present
    found = false; return;
end

found = true;   %   searchfor exists

if strncmpi(searchfor,'*',1)
    searchfor = searchfor(2:end);   %   remove '*';
end

%   make sure that <with> is not a label in a different field of <obj>;
%   otherwise, the == operator will not work for that label

[present, replace_field] = obj == with;

if present
    if ~strcmp(replace_field,field)
        error(['Replacing ''%s'' with ''%s'' would result in ''%s''' ...
            , ' appearing in multiple label fields, creating issues with' ...
            , ' the == operator.'],searchfor,with,with);
    end
end

%   get all labels in <field> (field) is outputted from eq(obj,values) as
%   a cell array)

field = field{1};

labs = obj(field);

%   it's possible to have multiple tags per label field; only replace the
%   matching tags

matches = cellfun(@(x) strfind(x,searchfor),labs,'UniformOutput',false);
empty = cellfun('isempty',matches);

putback = labs(empty); %    stash for later
labs(empty) = [];
matches(empty) = [];

for k = 1:numel(labs)
    current = labs{k};
    
    %   usually, just replace the label wholesale.
    
    if strcmp(params.method,'complete')
        labs{k} = with; continue;
    end
    
    %   alternatively, can replace part of the label if method = 'partial'
    
    if strcmp(params.method,'partial')
        from = matches{k};
        to = from + length(searchfor) - 1;

        current(from:to) = [];

        if from == 1
            labs{k} = [with current];
        else
            error('Cannot currently replace strings in the middle of labels');
        end
        continue;
    end
    
    error('Invalid method ''%s''. Options are ''complete'' or ''partial''', ...
        params.method);
    
end

obj(field) = [labs putback];

end