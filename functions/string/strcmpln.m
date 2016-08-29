function true_false = strcmpln(str,str2,n)

if ~iscell(str)
    str = fliplr(str);
else
    str = cellfun(@(x) fliplr(x),str,'UniformOutput',false);
end

if ~iscell(str2)
    str2 = fliplr(str2);
else
    str2 = cellfun(@(x) fliplr(x),str2,'UniformOutput',false);
end

true_false = strncmpi(str,str2,n);






