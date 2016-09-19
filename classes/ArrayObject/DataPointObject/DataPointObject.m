classdef DataPointObject
    
    properties
        data;
        labels;
        dtype;
    end
    
    properties (Hidden = true, Constant = true)
        errors = ErrorObject();
    end
    
    methods
        
        function obj = DataPointObject(data,labels)
            [data, labels] = DataPointObject.validate_initial_input(data,labels);
            
            obj.data = data;
            obj.labels = labels;
            obj.dtype = DataPointObject.get_dtype(data);
        end
        
        %{
            label handling
        %}
        
        function obj = addfield(obj,fields)
            obj.labels = addfield(obj.labels,fields);
        end
        
        function obj = rmfield(obj,fields)
            obj.labels = rmfield(obj.labels,fields);
        end
        
        %{
            data handling
        %}
        
        function obj = cell2mat(obj)
            obj = DataPointObject(concatenateData(obj.data),obj.labels);
        end
        
        %{
            operators
        %}
        
        function is_eq = eq(obj,values,varargin)
            is_eq = DataPointObject__eq(obj,values,varargin{:});
        end
        
        function is_eq = ne(obj,values,varargin)
            is_eq = ~eq(obj,values,varargin{:});
        end
        
        %{
            operations
        %}
        
        function out = plus(obj,values)
            out = DataPointObject__plus(obj,values);
        end
        
        function out = minus(obj,values)
            out = DataPointObject__subtraction(obj,values);
        end
        
        function out = times(obj,values)
            out = DataPointObject__multiply(obj,values);
        end
        
        function out = rdivide(obj,values)
            out = DataPointObject__divide(obj,values);
        end
        
        %   - helper
        
        function assert_capable_of_operations(obj,varargin)
            DataPointObject__assert_capable_of_operations(obj,varargin{:});
        end
        
        %{
            size
        %}
        
        function s = dimensions(obj)
            s = size(obj.data);
        end
        
        %{
            print
        %}
        
        function disp(obj)
            fprintf('\n''%s'' type DataPointObject with Labels ... \n\n'...
                , upper(obj.dtype));
            
            disp(obj.labels);
            
            fprintf('\nAnd size ... \n\n');
            
            disp(size(obj.data));
        end
        
    end
    
    %{
        static / helpers
    %}
    
    methods (Static)
        
        function [data, labels] = validate_initial_input(data,labels)
            if ~isa(labels,'LabelObject')
                try
                    labels = LabelObject(labels);
                catch
                    error('Failed to convert labels into a LabelObject');
                end
            end
        end
        
        %   returns the type of data contained in obj.data
        
        function dtype = get_dtype(data)
            dtype = class(data);
        end
        
    end
    
end