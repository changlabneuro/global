classdef Structure
  
  properties (Access = public)
    objects = struct();
    dtype = '';
  end
  
  properties (Access = protected)
    EMPTY_DTYPE = 'NONE';
  end
  
  methods
    function obj = Structure(s)
      obj.dtype = obj.EMPTY_DTYPE;
      if ( nargin < 1 ), return; end;
      Structure.validate__initial_input(s);
      obj.objects = s;
      obj.dtype = get_dtype( obj );
    end
    
    %{
        SIZE AND SHAPE
    %}
    
    function n = nfields(obj)
      
      %   NFIELDS -- Get the number of fields in the object.
      %
      %     If the `objects` property is a struct with no fields, `n` is 0.
      %
      %     OUT:
      %       - `n` (number)
      
      fs = fields( obj );
      n = numel( fs );      
    end
    
    function tf = isempty(obj)
      
      %   ISEMPTY -- True if the `objects` property is a struct with no
      %     fields.
      %
      %     OUT:
      %       - tf (logical) |SCALAR|
      
      tf = nfields( obj ) == 0;
    end
    
    %{
        FIELD HANDLING
    %}
    
    function f = fields(obj)
      
      %   FIELDS -- List the current fieldnames of the `obj.objects`
      %     struct.
      %
      %     OUT:
      %       - `f` (cell array of strings, {}) -- If the object is empty,
      %         `f` will be an empty cell array.
      
      f = fieldnames( obj.objects );
    end
    
    function obj = rm_fields(obj, names)
      
      %   RM_FIELDS -- Remove any number of fields from the object.
      %
      %     If even one of the given fields does not exist in the object,
      %     an error will be thrown.
      %
      %     IN:
      %       - `names` (cell array of strings, char) -- Fieldnames to
      %         remove from the `obj.objects` struct.
      
      names = unique( Structure.ensure_cell(names) );
      assert( iscellstr(names), ['To-be-removed fields must be specified' ...
        , ' as a string or cell array of strings'] );
      assert__fields_exist( obj, names );
      for i = 1:numel(names)
        obj.objects = rmfield( obj.objects, names{i} );
      end
    end
    
    function tf = is_field(obj, name)
      
      %   IS_FIELD -- True if the given `name` is a field in the
      %     `obj.objects` struct.
      %
      %     IN:
      %       - `name` (char) -- Name to test.
      %     OUT:
      %       - `tf` (logical) |SCALAR|
      
      assert( isa(name, 'char'), ...
        'Name must be a string; was a ''%s.''', class(name) );
      fs = fields( obj );
      tf = any( strcmp(fs, name) );
    end
    
    function tfs = are_fields(obj, fs)
      
      %   ARE_FIELDS -- Return a logical index of whether the given
      %     fields are fields in the `obj.objects` struct.
      %
      %     Fields can be repeated.
      %
      %     IN:
      %       - `fs` (cell array of strings, char) -- Fields to test.
      %     OUT:
      %       - `tfs` (logical) -- Index of whether the inputted fields
      %         were found in the `obj.objects` struct. Each `tfs`(i)
      %         corresponds to each `fs`(i).
      
      fs = Structure.ensure_cell( fs );
      assert( iscellstr(fs), ...
        'Specify names as a cell array of strings, or a single string' );
      tfs = cellfun( @(x) is_field(obj, x), fs );
    end
    
    %{
        REFERENCE
    %}
    
    function out = subsref(obj, s)
    
      subs = s(1).subs;
      type = s(1).type;
      
      s(1) = [];

      proceed = true;
      
      switch ( type )
        case '.'
          if ( ~isa(subs, 'char') )
            error( ['Referencing with ''.'' with values of class ''%s'' is' ...
              , ' illegal.'], class(subs) );
          end
          %   if the ref is the name of a Structure property, return the
          %   property
          if ( proceed && any(strcmp(properties(obj), subs)) )
            out = obj.(subs); proceed = false;
          end
          %   if the ref is the name of a field in `obj.objects`, return
          %   the object
          fs = fields( obj );
          if ( proceed && any(strcmp(fs, subs)) )
            out = obj.objects.(subs); proceed = false;
          end
          %   if the ref is the name of a Structure method, call the method
          %   on the Structure object (with whatever other inputs are
          %   passed), and return
          if ( proceed && any(strcmp(methods(obj), subs)) )
            func = eval( sprintf('@Structure.%s', subs) );
            %   if the ref is to a method, but is called without (), an
            %   error is thrown. E.g., Structure.eq -> error ...
            if ( numel(s) == 0 )
              error( ['''%s'' is the name of a Structure method, but was' ...
                , ' referenced as if it were a property'], subs );
            end
            inputs = [ {obj} {s(:).subs{:}} ];
            %   if no outputs are requested, execute the function without
            %   assigning anything to `out`. Otherwise, assign `out` to the
            %   output of func() and return
            if ( nargout(func) > 0 )
              out = func( inputs{:} );
            else func( inputs{:} );
            end
            return;
          end
          %   check if the ref is a method of the class in `obj.dtype`. If
          %   it is, call it on each object in `obj.objects` (with whatever
          %   other inputs are passed), and mutate the `objects` property
          %   to reflect the new values. Update the `dtype` in accordance
          %   with the new values.
          other_class_methods = methods( obj.dtype );
          if ( proceed && any(strcmp(other_class_methods, subs)) )
            func = eval( sprintf('@%s', subs) );
            %   if the ref is to a method, but is called without (), an
            %   error is thrown.
            if ( numel(s) == 0 )
              error( ['''%s'' is the name of a %s method, but was' ...
                , ' referenced as if it were a property'], subs, obj.dtype );
            end
            inputs = { s(:).subs{:} };
            obj.objects = structfun( @(x) func(x, inputs{:}), ...
              obj.objects, 'UniformOutput', false ); 
            out = obj;
            %   update the dtype
            out.dtype = get_dtype( out );
            return;
          end
          if ( proceed )
            error( ['The reference ''%s'' is not the name of a Structure' ...
              , ' property,\na Structure method, a field of Structure.objects,' ...
              , ' or a %s method'], ...
              subs, obj.dtype );
          end
        otherwise
          error( 'Referencing with ''%s'' is not supported', type );
      end
      
      if isempty(s)
        return;
      end
      %   continue referencing if this is a nested reference, e.g.
      %   obj.labels.labels
      out = subsref( out, s );
    end
    
    %{
        ASSIGNMENT
    %}
    
    function obj = subsasgn(obj, s, values)
    
      switch ( s(1).type )
        case '.'
          if ( ~isa(s(1).subs, 'char') )
            error( ['Referencing with ''.'' with values of class ''%s'' is' ...
              , ' illegal.'], class(s(1).subs) );
          end
          if ( is_field(obj, s(1).subs) )
            top = subsref( obj, s(1) );
          else
            assert( numel(s) == 1, ...
              ['Nested assignment with ''.'' requires that the top-level' ...
              , ' reference is already a field in the object.'] );
          end
          prop = s(1).subs;
          s(1) = [];
          if ( ~isempty(s) )
            values = subsasgn( top, s, values );
          end
          %   validate the prop name, and assign to the `obj.objects`
          %   struct
          obj = assign_to_objects( obj, prop, values );
        otherwise
          error( 'Referencing with ''%s'' is not supported', s(1).type );
      end
    end
    
    function obj = assign_to_objects(obj, prop, values)
      
      %   ASSIGN_TO_OBJECTS -- Intermediary to assign_field() to ensure
      %     that the to-be-assigned values are not a property.
      %
      %     IN:
      %       - `prop` (char) -- Property to set.
      %       - `values` (/any/) -- Values to assign.      
      
      assert( ~any(strcmp(properties(obj), prop)), ...
        'It is an error to directly set the ''%s'' property', prop );
      obj = assign_field( obj, prop, values );
    end
    
    function obj = assign_field(obj, field, values)
      
      %   ASSIGN_FIELD -- Assign the contents of a given `field` to the
      %     given `values`.
      %
      %     The validity of the fieldname will be confirmed. The class of
      %     the incoming values must match the `dtype` of the object.
      %
      %     IN:
      %       - `field` (char) -- Name of the field of `obj.objects` to
      %         assign. Must be a valid struct fieldname; otherwise, an
      %         error is thrown.
      %       - `values` (/any/) -- Values to assign. Class of `values`
      %         must match `obj.dtype`.
      
      assert__valid_fieldname( obj, field );
      assert__compatible_values( obj, values );
      obj.objects.(field) = values;
    end
    
    %{
        FUNCTIONAL
    %}
    
    function obj = each(obj, func, varargin)
      
      %   EACH -- Call a function on each field of `obj.objects`.
      %
      %     The given function must accept the values of each field of the
      %     object as its first input, and return exactly one output. Any 
      %     number of additional inputs can be specified. The function need
      %     not return a value of the same class as the original object's
      %     `dtype`, but the resulting `objects` struct must remain
      %     consistent. An error will be thrown if the call to `func`
      %     produces an `obj.objects` struct whose fields have values of
      %     different classes.
      %
      %     IN:
      %       - `func` (function_handle) -- Handle to the desired function,
      %         specified with @. The first input to `func` will be a given
      %         field in `obj.objects.
      %       - `varargin` (/any/) -- Any additional inputs that are
      %         passed to each call of `func`.
      %     OUT:
      %       - `obj` (Structure) -- Structure with its `objects` property
      %         mutated.
      
      assert( isa(func, 'function_handle'), ...
        'Input must be a function_handle; was a ''%s''', class(func) );
      assert( ~isempty(obj), 'Cannot apply functions to an empty object.' );
      %   apply the function to each field in `obj.objects`
      obj.objects = structfun( @(x) func(x, varargin{:}), obj.objects, ...
        'UniformOutput', false );
      msg = sprintf( ['Function ''%s'' produced a struct whose fields have values' ...
        , ' of different classes. A function called via `each` can change' ...
        , ' the class of values in the object, but must do so consistently.'] ...
        , func2str(func) );
      Structure.assert__consistent_dtype( obj.objects, struct('msg', msg) );
      obj.dtype = get_dtype( obj );
    end
    
    %{
        INTER-OBJECT HANDLING
    %}
    
    function tf = fields_match(obj, B)
      
      %   FIELDS_MATCH -- True if `B` is a Structure whose fields are
      %     identical to those of the current object.
      %
      %     IN:
      %       `B` (/any/) -- Values to compare.
      %     OUT:
      %       `tf` (logical) |SCALAR| -- True if `B` is a Structure with
      %       identical fields to the current object.
      
      tf = false;
      if ( ~isa(B, 'Structure') ), return; end;
      tf = isequal( fields(obj), fields(B) );
    end
    
    function tf = dtypes_match(obj, B)
      
      %   DTYPES_MATCH -- True if `B` is a Structure whose dtype is
      %     identical to that of the current object.
      %
      %     IN:
      %       `B` (/any/) -- Values to compare.
      %     OUT:
      %       `tf` (logical) |SCALAR| -- True if `B` is a Structure with
      %       the same `dtype` as the current object.
      
      tf = false;
      if ( ~isa(B, 'Structure') ), return; end;
      tf = isequal( obj.dtype, B.dtype );
    end
    
    function obj = structure_wise(obj, B, func, varargin)
      
      %   STRUCTURE_WISE -- Apply a function field-wise on two Structure 
      %     objects.
      %
      %     The two structures need have identical fields and dtypes. The 
      %     given function must be configured to accept the field of the 
      %     first Structure as its first argument, and the field of the 
      %     second Structure as its second argument. Any other additional
      %     arguments will be applied with each call of the function. The 
      %     function must return only one output; and while the class of 
      %     the returned values needn't be the same as the dtype of the
      %     inputted objects, it must be the same with each call to `func`. 
      %     I.e., calling the function cannot produce a struct whose fields 
      %     have values of different classes.
      %
      %     EXAMPLES:
      %
      %     //
      %     
      %     `obj` and `B` are 'Container' type Structures with fields
      %     'sums', 'proportions', and 'means'. Append the 'sums' Container
      %     in `B` to the 'sums' Container in `obj`, the 'proportions' 
      %     Container in `B` to the 'proportions' Container in `obj`, etc.
      %
      %     appended = obj.structure_wise( B, @append );
      %
      %     //
      %
      %     `obj` and `B` are 'double' type Structures with fields 'sums',
      %     'proportions', and 'means'. Subtract the 'sums' array in
      %     `B` from the 'sums' array in `obj`, etc. 
      %     
      %     subtracted = obj.structure_wise( B, @minus );
      %
      %     IN:
      %       - `B` (Structure) -- The second Structure in the call to
      %         `func`.
      %       - `func` (function_handle) -- Handle to a function configured
      %         to accept a field of `obj`, followed by a field of `B`,
      %         followed by any additional passed arguments. E.g.: @sum.
      %       - `varargin` (/any/) -- Any additional inputs to be passed to
      %         each call of `func`.
      %     OUT:
      %       - `obj` (Structure) -- Structure object with its `objects`
      %         property mutated.
      
      assert__capable_of_fieldwise_operations( obj, B );
      fs = fields( obj );
      for i = 1:numel(fs)
        own = obj.objects.(fs{i});
        other = B.objects.(fs{i});
        obj.objects.(fs{i}) = func( own, other, varargin{:} );
      end
      msg = sprintf( ['Function ''%s'' produced a struct whose fields have values' ...
        , ' of different classes. A function called via `each` can change' ...
        , ' the class of values in the object, but must do so consistently.'] ...
        , func2str(func) );
      Structure.assert__consistent_dtype( obj.objects, struct('msg', msg) );
      obj.dtype = get_dtype( obj );
    end
    
    function obj = swise(obj, B, func, varargin)
      
      %   SWISE -- Shorthand alias for `structure_wise`. See help
      %     `Structure/structure_wise` for more information.
      
      obj = structure_wise( obj, B, func, varargin{:} );
    end
    
    %{
        UTIL
    %}
    
    function disp(obj)
      
      %   DISP -- Print the current values in `obj.objects`.
      %
      %     Only prints the `obj.objects` struct if the object is not
      %     empty.
      
      if ( ~isempty(obj) )
        fprintf( '\n ''%s'' type Structure with fields:\n\n', obj.dtype );
        disp( obj.objects );
      else fprintf( '\n Structure with no fields\n\n' );
      end
    end
    
    function dtype = get_dtype(obj)
      
      %   GET_DTYPE -- Get the class of values in the Structure.
      %
      %     If the object is empty, dtype is `obj.EMPTY_DTYPE`
      %
      %     OUT:
      %       - `dtype` (char) -- Class of values in the Structure.
      
      if ( isempty(obj) ), dtype = obj.EMPTY_DTYPE; return; end;
      fs = fields( obj );
      dtype = class( obj.objects.(fs{1}) );
    end
    
    %{
        INSTANCE / STRUCTURE-SPECIFIC ASSERTIONS
    %}
    
    function assert__capable_of_fieldwise_operations(obj, B, opts)
      
      %   ASSERT__CAPABLE_OF_FIELDWISE_OPERATIONS -- Ensure two Structures
      %     have equivalent fields and dtypes
      %
      %     IN:
      %       - `B` (Structure) -- Structure to validate.
      %       - `opts` (struct) |OPTIONAL| -- struct with a 'msg' field
      %         that specifies the error message to display if the
      %         assertion fails.
      
      if ( nargin < 3 )
        opts.msg = [ 'When attempting field-wise function calls, the two objects' ...
          , ' must be Structures with the same dtypes and fields.' ];
      end
      assert( isa(B, 'Structure'), opts.msg );
      assert__dtypes_match( obj, B, struct('msg', opts.msg) );
      assert__fields_match( obj, B, struct('msg', opts.msg) );
    end
    
    function assert__dtypes_match(obj, B, opts)
      
      %   ASSERT__DTYPES_MATCH -- Ensure the dtypes of two Structure
      %     objects match.
      %
      %     Note that if `B` is not a Structure, dtypes_match() returns
      %     false.
      %
      %     IN:
      %       - `B` (Structure) -- Structure to check.
      %       - `opts` (struct) |OPTIONAL| -- struct with a 'msg' field
      %         that specifies the error message to display if the
      %         assertion fails.
      
      if ( nargin < 3 ), opts.msg = 'Dtypes do not match between objects'; end;
      assert( dtypes_match(obj, B), opts.msg );
    end
    
    function assert__fields_match(obj, B, opts)
      
      %   ASSERT__FIELDS_MATCH -- Ensure the fields of two Structure
      %     objects match.
      %
      %     Note that if `B` is not a Structure, fields_match() returns
      %     false.
      %
      %     IN:
      %       - `B` (Structure) -- Structure to check.
      %       - `opts` (struct) |OPTIONAL| -- struct with a 'msg' field
      %         that specifies the error message to display if the
      %         assertion fails.
      
      if ( nargin < 3 ), opts.msg = 'Fields do not match between objects'; end;
      assert( fields_match(obj, B), opts.msg );
    end
    
    function assert__fields_do_not_exist(obj, others, opts)
      
      %   ASSERT__FIELDS_DO_NOT_EXIST -- Ensure a given set of fields are
      %     not already present in the object.
      %
      %     IN:
      %       - `others` (cell array of strings) -- Fieldnames to test.
      %       - `opts` (struct) |OPTIONAL| -- struct with a 'msg' field
      %         that specifies the error message to display if the
      %         assertion fails.
      
      fs = fields( obj );
      if ( nargin < 3 )
        opts.msg = 'The field ''%s'' already exists in the object';
      end
      cellfun( @(x) assert(~any(strcmp(fs, x)), opts.msg, x), others );
    end
    
    function assert__fields_exist(obj, others, opts)
      
      %   ASSERT__FIELDS_EXIST -- Ensure a given set of fields are present 
      %     in the object.
      %
      %     IN:
      %       - `others` (cell array of strings) -- Fieldnames to test.
      %       - `opts` (struct) |OPTIONAL| -- struct with a 'msg' field
      %         that specifies the error message to display if the
      %         assertion fails.
      
      fs = fields( obj );
      if ( nargin < 3 )
        opts.msg = 'The field ''%s'' does not exist in the object';
      end
      cellfun( @(x) assert(any(strcmp(fs, x)), opts.msg, x), others );
    end
    
    function assert__compatible_values(obj, B, opts)
      
      %   ASSERT__COMPATIBLE_VALUES -- Ensure the class of a given variable
      %     matches the `dtype` of the object.
      %
      %     IN:
      %       - `B` (/any/) -- Values to compare.
      %       - `opts` (struct) |OPTIONAL| -- struct with a 'msg' field
      %         that specifies the error message to display if the
      %         assertion fails.
      
      if ( nargin < 3 )
        opts.msg = sprintf( ['The class of values must match' ...
          , ' the dtype of the Structure. Current dtype is ''%s'';' ...
          , ' values were of class ''%s'''], obj.dtype, class(B) );
      end
      assert( isequal(obj.dtype, class(B)), opts.msg );
    end
    
    function assert__valid_fieldname(obj, f, opts)
      
      %   ASSERT__VALID_FIELDNAME -- Ensure a given string is a valid
      %     struct fieldname.
      %
      %     IN:
      %       - `f` (char) -- Fieldname to test.
      %       - `opts` (struct) |OPTIONAL| -- struct with a 'msg' field
      %         that specifies the error message to display if the
      %         assertion fails.
      
      assert( isa(f, 'char'), ['Can only test if values of class ''char'' are' ...
        , ' valid fieldnames; given values were of class ''%s'''], class(f) );
      if ( nargin < 3 ), opts.msg = sprintf('Invalid fieldname ''%s''', f); end;
      try
        s = struct(); s.(f) = 10; %#ok<*STRNU>
      catch
        error( opts.msg );
      end
    end
  end
  
  methods (Static = true)
    
    function validate__initial_input(s)
      
      %   VALIDATE__INITIAL_INPUT -- Ensure `s` is a structure with
      %     values all of the same class.
      %
      %     IN:
      %       - `s` (struct) -- Struct to validate.
      
      msg = ['Instantiating a Structure requires a struct whose fields' ...
        , ' are values of the same class'];
      assert( isstruct(s), msg );
      Structure.assert__consistent_dtype( s, struct('msg', msg) );
    end
    
    function assert__consistent_dtype(s, opts)
      
      %   ASSERT__CONSISTENT_DTYPE -- Ensure the fields of a structure have
      %     values of the same class.
      %
      %     IN:
      %       - `s` (struct) -- Struct to validate.
      
      if ( nargin < 2 )
        opts.msg = 'The fields of the given struct have values of different classes';
      end
      assert( isa(s, 'struct'), ...
        'The first input must be a struct; was a ''%s''', class(s) );
      f = fieldnames(s);
      if ( numel(f) == 1 ), return; end;
      first = class( s.(f{1}) ); f(1) = [];
      classes = cellfun( @(x) class(s.(x)), f, 'UniformOutput', false );
      cellfun( @(x) assert(isequal(x, first), opts.msg), classes );
    end
    
    function arr = ensure_cell(arr)
      if ( ~iscell(arr) ), arr = { arr }; end;
    end
  end
  
end