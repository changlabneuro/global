function out = DataPointObject__subtraction(obj,values)

%{
    ensure that we can add the values we're attempting to add
%}

DataPointObject__assert_capable_of_operations(obj,values);

if isa(values,'DataPointObject')
    values = values.data;
end

switch obj.dtype
    case 'double'
        out = double_subtraction(obj,values);
    case 'cell'
        out = cell_subtraction(obj,values);
end

end

function obj = double_subtraction(obj,values)

obj.data = obj.data - values;

end

function obj = cell_subtraction(obj,values)

for i = 1:numel(obj.data)
    obj.data{i} = obj.data{i} - values{i};
end

end