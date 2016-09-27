function points = DataArrayObject__input_analyzer(varargin)

if isempty(varargin)
    points = {}; return;     %   allow empty objects
end

is_dataobj = cellfun(@(x) isa(x,'DataObject'),varargin);
is_datapoint = cellfun(@(x) isa(x,'DataPointObject'),varargin);

assert(all(is_dataobj | is_datapoint),'Unsupported input type');

points = varargin(~is_dataobj);

if ~any(is_dataobj)
    return;
end

objs = varargin(is_dataobj);

arr = DataArrayObject();

for i = 1:numel(objs)
    arr = [arr DataArrayObject.from(objs{i})];
end

if ~any(is_datapoint)
    points = arr.DataPoints; return;
end

points = [points arr.DataPoints];

end