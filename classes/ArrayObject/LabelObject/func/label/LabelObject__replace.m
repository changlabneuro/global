function [obj, found] = LabelObject__replace(obj,searchfor,with,varargin)

searchfor = LabelObject.make_cell(searchfor);

%   <searchfor> must be a cell array of strings, and <with> must be a string

assert(iscellstr(searchfor),ErrorObject.errors.inputIsNotCellString);
assert(ischar(with),ErrorObject.errors.inputIsNotString);

copy = obj;
found = false(size(searchfor));

for i = 1:numel(searchfor)
    [copy, found(i)] = internal__replace(copy,searchfor{i},with,varargin{:});
end

%   if we could find and replace all the search terms, return the replaced
%   object and found = true; otherwise, return the original object

found = all(found);

if found
    obj = copy;
end

end

function [obj, found] = internal__replace(obj,searchfor,with,varargin)

params = struct(...
    'method','complete' ...
);

params = parsestruct(params,varargin);

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