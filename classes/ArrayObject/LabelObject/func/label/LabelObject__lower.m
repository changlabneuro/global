function obj = LabelObject__lower(obj)

labels = structfun(@(x) cellfun(@(y) lower(y), x, 'UniformOutput', false), ...
    obj.labels, 'UniformOutput', false);

obj = LabelObject(labels);

end