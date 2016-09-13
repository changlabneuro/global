%{
    parsestruct.m -- function for parsing name-value pairs from function
    input. Taken from a stack-exchange thread I can no longer find 
    ¯\_(?)_/¯.
%}

function params = parsestruct(params,args)

names = fieldnames(params);

nArgs = length(args);

if round(nArgs/2)~=nArgs/2
   error('Name-value pairs are incomplete!')
end

for pair = reshape(args,2,[])
   inpName = pair{1};
   if any(strcmp(inpName,names))
      params.(inpName) = pair{2};
   else
      error('%s is not a recognized parameter name',inpName)
   end
end