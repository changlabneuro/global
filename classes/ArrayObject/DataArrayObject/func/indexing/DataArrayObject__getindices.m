function [indices, combs] = DataArrayObject__getindices(obj,within)

combs = getcombs(obj,within);

indices = cell(size(combs,1),1); remove = false(size(indices));
for i = 1:size(combs,1)
    index = eq(obj,combs(i,:),'fields',within);
    
    if ~any(index)
        remove(i) = true; continue;
    end
    
    indices{i} = index;
    
end

indices(remove) = [];
combs(remove,:) = [];

end