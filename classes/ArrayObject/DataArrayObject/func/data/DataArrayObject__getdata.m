%{
    DataArrayObject__getdata - function for extracting the data present in
    a DataArrayObject. In the most common use-case, the data in each
    <DataPoint> in <obj> are in a 'double' matrix and are consistent along 
    at least one dimension. 

    TODO: allow column-wise concatenation of 'double' data matrices

%}

function data = DataArrayObject__getdata(obj)

dtype = unique(getdtypes(obj));

assert(length(dtype) == 1, ErrorObject.errors.inconsistentDtype);

switch char(dtype)
    case 'double'
        data = data_is_double(obj);
    otherwise
        error(['Getting data from objects of dtype ''%s'' is currently' ...
            , ' unsupported'],char(dtype));
end

end

function data = data_is_double(obj)

sizes = getsizes(obj);

points = obj.DataPoints;

rows = unique(sizes(1,:));
cols = unique(sizes(2,:));

if length(rows) == 1 && length(cols) > 1
%     method = 'column-wise';
    error('Column-wise concatenation is currently unsupported');
elseif length(rows) > 1 && length(cols) == 1
    method = 'row-wise'; rows = sum(sizes(1,:)); use_size = sizes(1,:);
else
    error('The data in the DataArrayObject differ along more than one dimension');
end

data = zeros(rows,cols); stp = 0;

for i = 1:numel(points)
    point_data = points{i}.data;
    point_size = use_size(i);
    
    indices = (1+stp:point_size+stp);
    data(indices,:) = point_data;
    
    stp = stp + point_size;
end
end