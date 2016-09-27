function newobj = DataArrayObject__foreach(obj,indices,func,varargin)

assert(isa(func,'function_handle'),'The third input must be a function handle');
assert(isa(indices,'cell'),'The second input must be a cell array of indices');
assert(isa(indices{1},'logical'),'The second input must be a cell array of indices');

store = {};

for i = 1:numel(indices)
    filtered = obj(indices{i});

    output = func(filtered,varargin{:});
    
    store = [store output];
end

if isa(store{1},'double') || isa(store{1},'logical')
    newobj = concatenateData(store);
end


end