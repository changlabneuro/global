function out = LabelObject__subsref(obj,s,out)

if nargin < 3
    out = NaN;
end

current = s(1);
s(1) = [];

subs = current.subs;
type = current.type;

switch type
    case '.'
        intermediate = obj.(subs);
end


if isempty(s)
    return;
end







end