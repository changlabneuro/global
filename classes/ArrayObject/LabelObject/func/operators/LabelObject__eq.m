function [matches, store_fields] = LabelObject__eq(obj,values,varargin)

%{
    test object equality of values is a LabelObject
%}

if isa(values,'LabelObject')
    matches = LabelObject__LabelObject_eq(obj,values); store_fields = {}; return;
end

%{
    ensure that values are a cell array of strings
%}

values = LabelObject.make_cell(values);            
assert(iscellstr(values),ErrorObject.errors.inputIsNotCellString);

%{
    returns true if all strings in <values> are present in the obj.labels
    structure. Use flag eq( ... 'fields', <fields>) to limit the search to
    those <fields>
%}

manual_fields = strcmp(varargin,'fields');

if sum(manual_fields)
    fields = LabelObject.make_cell(varargin{(find(manual_fields == 1) + 1)});
else
    fields = obj.fields;
end
    
labels = obj.labels;

nterms = length(values);
nfields = length(fields);
store_fields = cell(1,nterms); %    for storing which fields were found

all_eq = false(1,nterms);

for i = 1:nterms
    val = values{i};
    
    %   - if string is preceded by '*', the string is treated as a pattern,
    %   otherwise the string must match exactly.
    
    if strncmpi(val,'*',1)
        wildcard = true; val = val(2:end);
    else wildcard = false;
    end
    
    is_eq = false(1,nfields);
    
    for k = 1:nfields
        current_labels = labels.(fields{k});
        
        if wildcard
            is_eq(k) = any(cellfun(@(x) ~isempty(strfind(lower(x),val)), ...
                current_labels));
        else
            is_eq(k) = any(strcmp(current_labels,val));
        end
        
    end
    
    if sum(is_eq) > 1
        error(['The search term ''%s'' was found in more than one' ...
            , ' category.'],val);
    end
    
    all_eq(i) = sum(is_eq);
    
    if nargout > 1
        if sum(is_eq)
            store_fields(i) = fields(is_eq);
        else store_fields{i} = -1;
        end
    end
     
end

matches = sum(all_eq) == nterms;

if nargout > 1
    empty = cellfun('isempty',store_fields); store_fields(empty) = [];
    if isempty(store_fields)
        store_fields = {};
    end
end

end