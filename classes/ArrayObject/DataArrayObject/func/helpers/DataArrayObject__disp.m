function DataArrayObject__disp(obj,varargin)

if isempty(obj)
    fprintf('\nEMPTY\n\n'); return;
end

thresh = 20;

if any(strcmp(varargin,'-v'))
    thresh = Inf;
end

labs = uniques(obj);

fields = fieldnames(labs);

if isempty(fields)
    fprintf('\n\nEMPTY\n');
end

for i = 1:length(fields)
    to_print = labs.(fields{i});
    
    fprintf('\n%s:',upper(fields{i}));
    if length(to_print) < thresh
        for k = 1:length(to_print)
            fprintf('\n\t%s',to_print{k});
        end
    else
            fprintf(['\n\tToo many to display ... Rerun with -v' ...
                , ' to see all']);
    end
    
end