classdef LabelObject
    
    properties (Access = public)
        labels;
        fields;
    end
    
    %{
        public methods
    %}
    
    methods (Access = public)
        
        %{
            init
        %}
        
        function obj = LabelObject(s)
            LabelObject.validate_initial_input(s);
            
            labels = struct();
            
            fields = fieldnames(s);
            
            for i = 1:length(fields)
                labels.(fields{i}) = unique(s.(fields{i}));
            end
            
            obj.labels = labels;
            obj.fields = fields;
        end
        
        %{
            subscript reference / assignment
        %}
        
        %   - allow reference of fields via () -> e.g., monks =
        %   obj('monkeys')
        
        function out = subsref(obj,s)
            current = s(1);
            s(1) = [];

            subs = current.subs;
            type = current.type;

            switch type
                case '.'
                    out = obj.(subs);
                case '()'
                    assert(iscellstr(subs),...
                        ErrorObject.errors.inputIsNotCellString);
                    out = obj.labels.(char(subs));
            end

            if isempty(s)
                return;
            end

            out = subsref(out,s);
        end
        
        %   - allow assignment of fields via () -> e.g., obj('monkeys') =
        %   'ephron'
        
        function out = subsasgn(obj,s,values)
            subs = s.subs;
            type = s.type;
            
            assert(iscellstr(subs),ErrorObject.errors.inputIsNotCellString);
            
            labs = obj.labels;
            
            switch type
                case '()'
                    values = LabelObject.make_cell(values);
                    
                    assert(iscellstr(values),...
                        ErrorObject.errors.inputIsNotCellString);
                    
                    labs.(char(subs)) = values;
                    out = LabelObject(labs); return;
            end
        end
        
        %{
            operators
        %}
        
        %   If <values> is a cell array of strings, LabelObject__eq returns
        %   whether all <values> are present in the <obj>. If <values> is
        %   another LabelObject, LabelObject__eq returns whether all labels
        %   present in <obj> are also present in <values>
        
        function [is_eq, field] = eq(obj,values,varargin)
            [is_eq, field] = LabelObject__eq(obj,values,varargin{:}); 
        end
        
        function [is_eq, field] = ne(obj,values,varargin)
            [is_eq, field] = eq(obj,values,varargin{:}); is_eq = ~is_eq;
        end
        
        %{
            field handling
        %}
        
        function obj = addfield(obj,fields)
            obj = LabelObject__addfield(obj,fields);
        end
        
        function obj = rmfield(obj,fields)
            obj = LabelObject__rmfield(obj,fields);
        end
        
        function [obj, found] = replace(obj,x,with,varargin)
            [obj, found] = LabelObject__replace(obj,x,with,varargin{:});
        end
        
        %   - get lowercase labels
        
        function obj = lower(obj)
            obj = LabelObject__lower(obj);
        end
        
        %{
            print
        %}
        
        function disp(obj)
            disp(obj.labels);
        end
        
        %{
            non-static helpers
        %}
        
        function bool = islabelfield(obj,field)
            assert(ischar(field),ErrorObject.errors.inputIsNotString);
            bool = any(strcmp(obj.fields,field));
        end
        
        
    end
    
    %{
        static helper methods
    %}
    
    methods (Static)
        
        function validate_initial_input(s)
            if ~isstruct(s)
                error(ErrorObject.errors.inputIsNotStruct);
            end
            
            fields = fieldnames(s);
            
            %   ensure each field is a cell array of strings
            
            for i = 1:length(fields)
                assert(iscellstr(s.(fields{i})),...
                    ErrorObject.errors.inputIsNotCellString);
            end
        end
        
        function c = make_cell(c)
            if ~iscell(c)
                c = {c};
            end
        end
        
    end
    
end

% labels.monkeys = {'hitch'};
% labels.drugs = {'saline'};
% labels.