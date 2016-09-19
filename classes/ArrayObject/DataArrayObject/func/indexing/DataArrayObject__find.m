function ind = DataArrayObject__find(obj,condition)

len = dimensions(obj,2);

indices = 1:len;

if any(size(condition) ~= size(indices))
    error('Invalid condition')
end

ind = indices(condition);

end