%{
    DataArrayObject__DataArrayObject_eq - function for determining
    equivalence of two DataArrayObjects. Use flag '-ignoreData' to only
    compare the label objects in each array; use flag '-ignoreLabels' to
    only compare the data in each array
%}

function bool = DataArrayObject__DataArrayObject_eq(a,b,varargin)

if any(dimensions(a) ~= dimensions(b))
    fprintf('\n\nSize inequality'); bool = false; return;
end

if a.consistent_obj ~= b.consistent_obj
    fprintf('\n\nObjects are not of the same consistency'); bool = false; return;
end

a_points = a.DataPoints;
b_points = b.DataPoints;

if any(strcmp(varargin,'-ignoreData'))
    a_points = cellfun(@(x) x.labels,a_points,'UniformOutput',false);
    b_points = cellfun(@(x) x.labels,b_points,'UniformOutput',false);
end

flag = '';

if any(strcmp(varargin,'-ignoreLabels'))
    flag = '-ignoreLabels';
end

bool = compare_points_or_labels(a_points,b_points,flag);

end

function bool = compare_points_or_labels(a,b,varargin)

bool = true;

for i = 1:numel(a)
    if ne(a{i},b{i},varargin{:});
        bool = false; return;
    end
end

end