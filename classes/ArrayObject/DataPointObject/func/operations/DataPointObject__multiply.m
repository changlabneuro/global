function out = DataPointObject__multiply(obj,values)

%{
    ensure that we can add the values we're attempting to add
%}

DataPointObject__assert_capable_of_operations(obj,values);

if isa(values,'DataPointObject')
    values = values.data;
end

switch obj.dtype
    case 'double'
        out = double_multiply(obj,values);
    case 'cell'
        out = cell_multiply(obj,values);
end

end

function obj = double_multiply(obj,values)

obj.data = obj.data .* values;

end

function obj = cell_multiply(obj,values)

for i = 1:numel(obj.data)
    obj.data{i} = obj.data{i} .* values{i};
end

end