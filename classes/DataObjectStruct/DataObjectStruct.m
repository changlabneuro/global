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
        
        function out = subsref(obj,s)
            current = s(1);
            s(1) = [];

            subs = current.subs;
            type = current.type;

            switch type
                case '.'
                    
                    %   return the property <subs> if subs is a property
                    
                    if any(strcmp(properties(obj), subs))
                        out = obj.(subs); return;
                    end
                    
                    %   call the function on the obj is <subs> is a
                    %   SignalStruct method
                    
                    if any( strcmp(methods(obj), subs) )
                        func = eval(sprintf('@%s',subs));
                        inputs = [{obj} {s(:).subs{:}}];
                        out = func(inputs{:}); return;
                    end                    
                    
                    fields = objectfields(obj);
                    data_obj_funcs = methods(obj.objects.(fields{1}));
                    
                    %   call the function on each object field if <subs> is
                    %   a method
                    
                    if any(strcmp(data_obj_funcs,subs))
                        out = obj;
                        func = eval(sprintf('@%s',subs));
                        inputs = {s(:).subs{:}};
                        out.objects = structfun(@(x) func(x, inputs{:}),...
                            obj.objects, 'UniformOutput', false);
                        return;
                    end
                    
                    %   return the objects if <subs> is an object field
                    
                    if any(strcmp(fields, subs))
                        out = obj.objects.(subs);
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
            
%             fields = fieldnames(structure);
%             for i = 1:numel(fields)
%                 if ( i == 1 ); to_compare = structure.(fields{i}); continue; end;
%                 assert( labeleq(to_compare, structure.(fields{i})), ...
%                     'Labels must be equal between objects' );
%                 to_compare = structure.(fields{i});
%             end
        end
        
    end
    
end