% structInpParse.m - function for parsing varargin name-value pair
% arguments (params) and adjusting default values as appropriate. Legacy
% version kept in for compatability reasons.

function params = structInpParse(params,inpArgs)

paramNames = fieldnames(params);

nArgs = length(inpArgs);
if round(nArgs/2)~=nArgs/2
   error('Name-value pairs are incomplete!')
end

for pair = reshape(inpArgs,2,[])
   inpName = pair{1};
   if any(strcmp(inpName,paramNames))
      params.(inpName) = pair{2};
   else
      error('%s is not a recognized parameter name',inpName)
   end
end
