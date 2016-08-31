function copypath(field)

if strcmp(field,'cd')
    pathstr = cd;
else pathstr = pathfor(field);    
end

clipboard('copy',pathstr);

end