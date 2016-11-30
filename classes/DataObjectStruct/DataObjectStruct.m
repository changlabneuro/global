%{
    DataObjectStruct.m -- class for extending the functionality of a
    DataObject. When you instantiate a DataObjectStruct, you can call
    methods as you would for a single object, but apply them to all objects
    in the struct. The syntax is matched as closely as possible, such that,
    for most operations, code need not be rewritten to handle
    DataObjectStructs vs. DataObjects.

    INPUT
        <structure> -- struct where each field is a DataObject

    EXAMPLE USAGE:
        inputs.object1 = <DataObject>
        inputs.object2 = <DataObject>

    datastruct = DataObjectStruct( inputs );

    datastruct.replace( 'self', 'both' );   %   replace 'self' labels with
                                            %   'both' labels, for each
                                            %   object in the structure

    datastruct

    ans =
        object1
        object2

    ADDITIONAL FUNCTIONALITY

    -   structure.foreach( function_handle, varargin )
            Apply a function <function_handle> to each DataObject in
            <structure>. The object is always the first input to
            <function_handle>, followed by the ordered inputs in
            <varargin>. Returns a structure of the same format as
            <structure>. This is useful / necessary for dealing with
            functions that are not DataObject methods defined in DataObject.m

    -   structure.perfield( structure2, function_handle, varargin )
            Apply a function object-wise to <structure> and <structure2>.
            Both structures must have matching fieldnames. Returns a new
            structure of the same format as <structure> and <structure2>.
            <structure> is always the first input to <function_handle>, and
            <structure2> is always the second input, followed by <varargin>

            e.g.:
                struct1.toNormalize = <DataObject>
                struct1.baseline = <DataObject>

                struct2.toNormalize = <DataObject>
                struct2.baseline = <DataObject>

                %   subtract each DataObject, field-by-field, i.e.,
                %   struct1.toNormalize - struct2.toNormalize, ...

                newstruct = struct1.perfield( struct2, @minus );

                %   concat 

                newstruct = struct1.perfield( struct2, @vertcat );                
%}

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
        
        %   execute a function on each object in <obj>
        
        function obj = foreach(obj, func, varargin)            
            assert( isa(func, 'function_handle'), 'func must be a function handle' );
            
            objs = obj.objects;
            fields = objectfields( obj );
            
            for i = 1:numel(fields)
                objs.(fields{i}) = func( objs.(fields{i}), varargin{:} );
            end
            
            obj.objects = objs;
        end
        
        %   execute a function field-wise on two DataObjectStructs -- e.g.,
        %   obj - obj2 -> obj.toNormalize - obj2.toNormalize, and
        %   obj.baseline - obj2.baseline
        
        function obj = perfield(obj, obj2, func, varargin)
            assert_capable_of_operations( obj, obj2 );
            fields = objectfields( obj );
            
            for i = 1:numel(fields)
                obj.objects.(fields{i}) = ...
                    func( obj.objects.(fields{i}), obj2.objects.(fields{i}), varargin{:} );
            end           
            
        end
        
        %{
            subscript referencing
        %}
        
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
        
        %{
            field handling
        %}
        
        function obj = renameobject(obj, from, to)
            assert( isobjectfield(obj, from), ...
                sprintf('The field ''%s'' is not in the object', from) );
            current = obj.objects.(from);
            new = rmfield(obj.objects, from);
            new.(to) = current;
            obj.objects = new;
        end
        
        %   append <label> to each fieldname in obj.objects
        
        function obj = namespace(obj, label)
            assert( ischar(label), '<label> must be a string' );
            fields = objectfields( obj );
            for i = 1:numel(fields)
                obj = renameobject( ...
                    obj, fields{i}, sprintf('%s__%s', label, fields{i}) );
            end
        end
        
        %   get the names of the objects in the struct
        
        function fields = objectfields(obj)
            fields = fieldnames( obj.objects );
        end
        
        function tf = isobjectfield(obj, field)
            fields = objectfields(obj);
            tf = any( strcmp(fields, field) );
        end
        
        %{
            object mutation - adding, removing, concatenating ...
        %}
        
        %   add an object to the structure
        
        function obj = addobject(obj, toadd, name)
            assert( isa(toadd, 'DataObject'), 'Input must be a DataObject' );
            assert( ischar(name), 'The fieldname must be a string' );
            assert( ~isobjectfield(obj, name), ...
                sprintf('The field ''%s'' already exists', name) );
            
            obj.objects.(name) = toadd;
        end
        
        %   remove an object from the structure
        
        function obj = rmobject(obj, fields)
            if ( ~iscell(fields) ); fields = {fields}; end;
            assert_fields_exist( obj, fields ); fields = unique( fields );
            for i = 1:numel(fields)
                obj.objects = rmfield( obj.objects, fields{i} );
            end
        end
        
        %   place the contents of <obj2> into <obj>, assuming each are
        %   unique
        
        function obj = include(obj, obj2)
            fields = objectfields( obj2 );
            assert_fields_do_not_exist( obj, fields, ...
                [ 'Cannot add the contents of the second object to the first,' ...
                , ' because the fieldnames overlap between the two objects.' ...
                , ' Call namespace( <object>, <label> ) to create a namespace' ...
                , ' for the second object before proceeding' ] );
            for i = 1:numel(fields)
                obj.objects.(fields{i}) = obj2.objects.(fields{i});
            end
        end
        
        %{
            generic
        %}
        
        function disp(obj)
            disp( obj.objects );
        end
        
        function s = struct( obj )
            s = obj.objects;
        end
        
        %{
            operations - certain operations (like minus) are supported
            directly, without the need to call foreach() or perfield()
        %}
        
        function obj = minus(obj, obj2)
            obj = perfield( obj, obj2, @minus );         
        end
        
        %{
            ensure we can do field-wise operations on two DataObjectStructs
        %}
        
        function assert_capable_of_operations(obj, obj2)
            assert( isa(obj2, 'DataObjectStruct'), ...
                'Input is not of type DataObjectStruct' );
            fields = objectfields( obj2 );            
            assert_fields_exist( obj, fields, 'Fields do not match between objects' );
        end
        
        %   ensure that all <fields> exist in the object
        
        function assert_fields_exist(obj, fields, msg)            
            if ( nargin < 3 ); msg = 'At least one field does not exist'; end;            
            assert( iscellstr(fields), '<fields> must be a cell array of strings' );
            for i = 1:numel(fields)
                assert( isobjectfield( obj, fields{i} ), msg );
            end
        end
        
        %   ensure that all <fields> do NOT exist in the object
        
        function assert_fields_do_not_exist(obj, fields, msg)
            if ( nargin < 3 ); msg = 'At least one field exists that shouldn''t'; end;
            assert( iscellstr(fields), '<fields> must be a cell array of strings' );
            for i = 1:numel(fields)
                assert( ~isobjectfield( obj, fields{i} ), msg );
            end
        end
        
    end
    
    methods (Static)
        
        %   input validation: make sure <structure> is a struct, and that 
        %   each field of <structure> is a DataObject
        
        function validate_structure(structure)
            msg = ['<structure> must be a struct or DataObjectStruct,' ...
                , ' and each field must be a DataObject'];            
            if ( isa( structure, 'DataObjectStruct' ) )
                structure = struct( structure );
            end
            assert( isa(structure, 'struct'), msg );
            structfun( @(x) assert(isa(x, 'DataObject'), msg), structure );
        end
        sdfj;
    end
    
end