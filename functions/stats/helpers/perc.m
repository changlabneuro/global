%{
    perc.m - simple helper function for returning the percentage of 'true'
    occurrences in a logical array <condition>

    E.g., percentages = perc(some_array > 1000)
%}

function vals = perc(condition)

if ~isa(condition,'logical')
    error('perc must be called with a logical index as input')
end

vals = (sum(condition) ./ size(condition,1)) .* 100;

end