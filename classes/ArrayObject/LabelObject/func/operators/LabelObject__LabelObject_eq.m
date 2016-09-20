function is_eq = LabelObject__LabelObject_eq(a,b,varargin)

is_eq = true;

a_fields = a.fields;
b_fields = b.fields;

for i = 1:length(b_fields)
    if ~any(strcmp(a_fields,b_fields{i}))
        is_eq = false; fprintf('\n\nLabel fields are different\n'); return;
    end
    
    a_labs = unique(a(b_fields{i}));
    b_labs = unique(b(b_fields{i}));
    
    for k = 1:length(a_labs)
        current_label = a_labs{k};
        
        if ~any(strcmp(b_labs,current_label))
            is_eq = false; fprintf('\n\nLabels are different\n'); return;
        end
        
    end
    
end

if strcmp(varargin,'returnWhenFinished')
    return;
end

is_eq = LabelObject__LabelObject_eq(b,a,'returnWhenFinished');
end