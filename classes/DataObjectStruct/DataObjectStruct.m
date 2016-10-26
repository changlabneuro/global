classdef DataObjectStruct
    
    properties
        objects = struct();
    end
    
    methods
        
        function obj = DataObjectStruct(structure)            
            DataObjectStruct.validate_structure(structure);
            
            fields = fieldnames(structure);
            for i = 1:numel(fields)
               objects.(fields{i}) = structure.(fields{i});
            end
           
            obj.objects = objects;
        end
        
        %   execute a function on each object
        
        function obj = foreach(obj, func, varargin)
            
            assert( isa(func, 'function_handle'), 'func must be a function handle' );
            
            objs = obj.objects;
            fields = objectfields(obj);
            
            for i = 1:numel(fields)
                objs.(fields{i}) = func(objs.(fields{i}), varargin{:});
            end
            
            obj.objects = objs;
        end
        
        function out = subsref(obj,s)
            current = s(1);
            s(1) = [];

            subs = current.subs;
            type = current.type;
            
            proceed = true; %   for breaking from the '.' case at the right point

            switch type
                case '.'
                    
                    %   return the property <subs> if subs is a property
                    
                    if any(strcmp(properties(obj), subs)) && proceed
                        out = obj.(subs); proceed = false;
                    end
                    
                    %   call the function on the obj is <subs> is a
                    %   DataObjectStruct method
                    
                    if any( strcmp(methods(obj), subs) ) && proceed
                        func = eval(sprintf('@%s',subs));
                        inputs = [{obj} {s(:).subs{:}}];
                        out = func(inputs{:});
                        return; %   note -- in this case, we do not proceed
                    end                    
                    
                    fields = objectfields(obj);
                    data_obj_funcs = methods(obj.objects.(fields{1}));
                    
                    %   call the function on each object field if <subs> is
                    %   a method
                    
                    if any(strcmp(data_obj_funcs,subs)) && proceed
                        out = obj;
                        func = eval(sprintf('@%s',subs));
                        inputs = {s(:).subs{:}};
                        out.objects = structfun(@(x) func(x, inputs{:}),...
                            obj.objects, 'UniformOutput', false);
                        return; %   note -- in this case, we do not proceed
                    end
                    
                    %   return the objects if <subs> is an object field
                    
                    if any(strcmp(fields, subs))
                        out = obj.objects.(subs); proceed = false;
                    end
                    
                    %   otherwise, the reference type is unsupported
                    
                    if ( proceed )
                        error('Unsupported reference method');
                    end
                    
                otherwise
                    error('Unsupported reference method');
            end

            if isempty(s)
                return;
            end

            out = subsref(out,s);
        end
        
        function obj = renamefield(obj, from, to)
            assert( isobjectfield(obj, from), ...
                'The field ''%s'' is not in the object' );
            current = obj.objects.(from);
            new = rmfield(obj.objects, from);
            new.(to) = current;
            obj.objects = new;
        end
        
        function fields = objectfields(obj)
            fields = fieldnames(obj.objects);
        end
        
        function tf = isobjectfield(obj, field)
            fields = objectfields(obj);
            tf = any( strcmp(fields, field) );
        end
        
        function disp(obj)
            disp(obj.objects);
        end
    end
    
    methods (Static)
        
        function validate_structure(structure)
            structfun(@(x) assert(isa(x, 'DataObject')), structure);
        end
        
    end
    
end