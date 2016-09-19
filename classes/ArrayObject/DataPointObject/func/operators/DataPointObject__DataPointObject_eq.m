function is_eq = DataPointObject__DataPointObject_eq(a,b,varargin)

is_eq = true;

if ~strcmp(a.dtype,b.dtype)
    fprintf('\n\nDoc-type inequality\n'); is_eq = false; return;
end

%{
    Make sure that we can test equality between objects
%}

valid_dtypes = {'double','cell'};

if ~any(strcmp(valid_dtypes,a.dtype))
    error(['Testing equality of objects with dtype ''%s'' is not ' ...
        , ' supported.'],a.dtype);
end

%   if '-ignoreLabels' flag is present, only test the equality of the data
%   in each object. By default, confirm that labels are also the same

if ~any(strcmp(varargin,'-ignoreLabels'))
    if a.labels ~= b.labels
        is_eq = false; return;
    end
end

if any(dimensions(a) ~= dimensions(b))
    fprintf('\n\nSize inequality\n'); is_eq = false; return;
end

a_data = a.data;
b_data = b.data;

switch a.dtype
    case 'double'
        is_eq = matrix_equality(a_data == b_data); return;
        
    case 'cell'
        for i = 1:numel(a_data)
            is_eq = matrix_equality(a_data{i} == b_data{i}); return;
        end
end

end


function is_eq = matrix_equality(matrix)

is_eq = true;

if sum(sum(matrix)) ~= numel(matrix)
    is_eq = false;
end

end