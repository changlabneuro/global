%{
    WORK IN PROGRESS

    DataArrayObject.m - array class in which each element is a
    DataPointObject, with <data> and <label> properties. DataArrayObjects
    can be filtered

%}

classdef DataArrayObject
    
    properties
        DataPoints = cell(1,1);
    end
    
    properties (Hidden = true)
        consistent_labels = false;
        consistent_data = false;
        consistent_obj = false;
    end
    
    methods
        
        function obj = DataArrayObject(varargin)
            DataArrayObject.validate_initial_input(varargin{:});
            obj.DataPoints = varargin;
            obj = determine_consistency(obj);
        end
        
        %{
            label handling
        %}
        
        function labs = uniques(obj,varargin)
            labs = DataArrayObject__uniques(obj,varargin{:});
        end
        
        function combs = getcombs(obj,within)
            combs = DataArrayObject__getcombs(obj,within);
        end
        
        function fields = allfields(obj)
            if obj.consistent_labels
                fields = obj.DataPoints{1}.labels.fields; return;
            end
            fields = fieldnames(uniques(obj));
        end
        
        function bool = isfield(obj,field)
            bool = any(strcmp(allfields(obj),field));
        end
        
        function obj = addfield(obj,field)
            obj = DataArrayObject__addfield(obj,field);
        end
        
        function obj = rmfield(obj,field)
            obj = DataArrayObject__rmfield(obj,field);
        end
        
        function labs = getfield(obj,field,varargin)
            labs = DataArrayObject__getfield(obj,field,varargin{:});
        end
        
        function obj = setfield(obj,field,setas,varargin)
            obj = DataArrayObject__setfield(obj,field,setas,varargin{:});
        end
        
        function obj = replace(obj,searchfor,with,varargin)
            obj = DataArrayObject__replace(obj,searchfor,with,varargin{:});
        end
        
        %{
            data handling
        %}
        
        function data = getdata(obj)
            data = DataArrayObject__getdata(obj);
        end
        
        function sizes = getsizes(obj)
            sizes = DataArrayObject__getsizes(obj);
        end
        
        function dtypes = getdtypes(obj)
            dtypes = cellfun(@(x) x.dtype, obj.DataPoints, 'UniformOutput',false);
        end
        
        function obj = cell2mat(obj)
            obj = DataArrayObject__cell2mat(obj);
        end
        
        %{
            operators
        %}
        
        function index = eq(obj,values,varargin)
            index = DataArrayObject__eq(obj,values,varargin{:});
        end
        
        function index = ne(obj,values,varargin)
            index = ~eq(obj,values,varargin{:});
        end
        
        function obj = horzcat(varargin)
            obj = DataArrayObject__cat(varargin{:});
        end
        
        function obj = vertcat(varargin)
            obj = DataArrayObject__cat(varargin{:});
        end
        
        %{
            operations
        %}
        
        function obj = plus(obj,values)
            obj = DataArrayObject__plus(obj,values);
        end
        
        function obj = minus(obj,values)
            obj = DataArrayObject__minus(obj,values);
        end
        
        function obj = rdivide(obj,values)
            obj = DataArrayObject__divide(obj,values);
        end
        
        function obj = times(obj,values)
            obj = DataArrayObject__multiply(obj,values);
        end
        
        function assert_capable_of_operations(obj,varargin)
            DataArrayObject__assert_capable_of_operations(obj,varargin{:})
        end
        
        %{
            reference, assignment, indexing
        %}
        
        %   - reference
        
        function out = subsref(obj,s)
            current = s(1);
            s(1) = [];

            subs = current.subs;
            type = current.type;

            switch type
                case '.'
                    
                    %   call the function if subs is a method
                    
                    if any(strcmp(methods(obj),subs))
                        func = eval(sprintf('@%s',subs));
                        inputs = [{obj} {s(:).subs{:}}];
                        out = func(inputs{:}); return;
                    end
                    
                    %   otherwise, get the property <subs>
                    
                    out = obj.(subs);
                case '()'
                    ref = subs{1};
                    
                    %   if format is obj('some field')
                    
                    if ischar(ref)
                        out = getfield(obj,ref); return; %#ok<*GFLD>
                    end
                    
                    %   otherwise, filter the data object by a logical
                    %   index
                    
                    filtered = obj.DataPoints(ref);
                    out = DataArrayObject(filtered{:});
                case '{}'
                    ref = subs{1};
                    
                    out = obj.DataPoints{ref};
                otherwise
                    error('Unsupported reference method');
            end

            if isempty(s)
                return;
            end

            out = subsref(out,s);
        end
        
        %   - indexing
        
        function [inds, combs] = getindices(obj,within)
            [inds, combs] = DataArrayObject__getindices(obj,within);
        end
        
        function inds = find(obj,condition)
            inds = DataArrayObject__find(obj,condition);
        end
        
        %{
            size
        %}
        
        function dims = dimensions(obj,dim)
           if nargin < 2
               dims = size(obj.DataPoints);
           else
               dims = size(obj.DataPoints,dim);
           end
        end
        
        function els = count(obj)
            els = numel(obj.DataPoints);
        end
        
        function empty = isempty(obj)
            empty = isempty(obj.DataPoints);
        end
        
        %{
            object composition
        %}
        
        function obj = determine_consistency(obj)
            obj = DataArrayObject__determine_consistency(obj);
        end
        
        %{
            object lifespan
        %}
        
        function obj = refresh(obj)
            points = obj.DataPoints;
            obj = DataArrayObject(points{:});
        end
        
        %{
            print
        %}
        
        function disp(obj)
            DataArrayObject__disp(obj);
        end
        
        %{
            conversion
        %}
        
        function obj = array2obj(obj)
            obj = DataArrayObject__array2obj(obj);
        end
        
    end
    
    methods (Static)
        
        function validate_initial_input(varargin)
            for i = 1:length(varargin)
                current_input = varargin{i};
                
                assert(isa(current_input,'DataPointObject'),...
                    ErrorObject.errors.inputIsNotDataPointObject);
            end
        end
        
        %{
            creation / conversion
        %}
        
        function obj = from(data_obj,varargin)
            obj = DataArrayObject__from_DataObject(data_obj,varargin{:});
        end
        
    end
    
end