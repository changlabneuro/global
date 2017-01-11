classdef Container
  
  properties (Access = public)
    data = [];
    labels = Labels();
    dtype = 'EMPTY'
  end
  
  properties (Access = protected)
    IGNORE_CHECKS = false;
    SUPPORTED_DTYPES = struct( ...
      'plus',     {{ 'cell', 'double' }}, ...
      'minus',    {{ 'cell', 'double' }}, ...
      'times',    {{ 'cell', 'double' }}, ...
      'rdivide',  {{ 'cell', 'double' }} ...
    );
    VERBOSE = false;
    IS_PREALLOCATING = false;
    PREALLOCATION_ROW = NaN;
    PREALLOCATION_SIZE = NaN;
    BEEN_POPULATED = false;
  end
  
  methods
    function obj = Container(data, labels)
      if ( nargin == 0 ), return; end;
      [data, labels] = Container.validate__initial_input( data, labels );
      obj.data = data;
      obj.labels = labels;
      obj.dtype = class( data );
    end
    
    %{
        STATE
    %}
    
    function obj = verbosity(obj, to)
      
      %   VERBOSITY -- turn more descriptive / debug messages 'on' or
      %     'off'. 
      %
      %     If no inputs are specified, the object is returned unchanged. 
      %     If `to` is neither 'on' nor 'off', the object is returned 
      %     unchanged.
      %
      %     IN:
      %       - `to` ('on' or 'off')
      
      if ( nargin < 2 ), return; end;
      if ( isequal(to, 'on') )
        obj.VERBOSE = true; 
        obj.labels = verbosity( obj.labels, 'on' ); return; 
      end
      if ( isequal(to, 'off') )
        obj.VERBOSE = false; 
        obj.labels = verbosity( obj.labels, 'off' );
      end
    end
    
    function obj = toggle_verbosity(obj)
      
      %   TOGGLE_VERBOSITY -- Toggle the display of more descriptive
      %     messages in the Container and `Container.labels` objects.
      
      if ( obj.VERBOSE )
        obj.VERBOSE = false;
        obj.labels = verbosity( obj.labels, 'off' );
        fprintf( ['\n ! Container/toggle_verbosity: Turned verbosity' ...
          , ' ''off''\n\n'] );
      else
        obj.VERBOSE = true;
        obj.labels = verbosity( obj.labels, 'on' );
        fprintf( ['\n ! Container/toggle_verbosity: Turned verbosity' ...
          , ' ''on''\n\n'] );
      end
    end
    
    %{
        SIZE + SHAPE
    %}
    
    function s = shape(obj, dim)
      
      %   SHAPE -- get the size of the data in the object.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- dimension(s) of the data to 
      %         query.
      %     OUT:
      %       - `s` (double) -- dimensions.
      
      s = size( obj.data );
      if ( nargin < 2 ), return; end;
      s = s( dim );
    end
    
    function n = nels(obj)
      
      %   NELS -- get the total number of data elements in the object.
      %
      %     OUT:
      %       - `n` -- number of elements `Container.data`
      
      n = numel( obj.data );
    end
        
    function tf = isempty(obj)
      
      %   ISEMPTY -- True if the data in the object are empty.
      
      tf = isempty( obj.data );
    end
    
    %{
        INDEXING
    %}    
    
    function obj = keep(obj, ind)
      
      %   KEEP -- retain rows of data and labels at which `ind` is true.
      %
      %     Note that a number of checks as to the validity of `ind` are 
      %     handled in the call to keep( obj.labels, ind ).
      %
      %     IN:
      %       - `ind` (logical) |COLUMN| -- Index of elements to keep. 
      %         Must be a column vector with as many rows as the object. If 
      %         it is entirely false, the resulting object will be empty.
      %     OUT:
      %       - `obj` (Container) -- New object containing only true 
      %         elements of `ind`.
      
      obj.labels = keep( obj.labels, ind );
      obj.data = obj.data(ind, :);
    end
    
    function [obj, ind] = remove(obj, selectors)
      
      %   REMOVE -- remove rows of data and labels identified by
      %     the labels in `selectors`.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- labels to
      %         identify rows to remove.
      %     OUT:
      %       - `obj` (Container) -- object with `selectors` removed.
      %       - `full_ind` (logical) |COLUMN| -- index of the removed 
      %         elements, with respect to the inputted (non-mutated)
      %         object.
      
      [obj.labels, ind] = remove( obj.labels, selectors );
      obj.data = obj.data( ~ind, : );
    end
    
    function [obj, ind] = rm(obj, selectors)
      
      %   RM -- shorthand alias for remove(). See `help Container/remove`.
      
      [obj, ind] = remove( obj, selectors );
    end
    
    function [obj, ind] = only(obj, selectors)
      
      %   ONLY -- retain elements in `obj.data` that match the index of the
      %     `selectors`. 
      %
      %     See `help Labels/only` and `help Labels/where` for more 
      %     information about how the indices are computed.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- labels to
      %         keep.
      %     OUT:
      %       - `obj` (Container) -- New Container, only including elements
      %         associated with `selectors`.
      %       - `ind` (logical) -- The index used to select rows of the 
      %         object.
      
      ind = where( obj.labels, selectors );
      obj = keep( obj, ind );
    end
    
    function [ind, fields] = where(obj, selectors, varargin)
      
      %   WHERE -- generate an index of the labels in `selectors`.
      %
      %     See help Labels/where` for more information on how labels are
      %     located.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- labels to 
      %         search for.
      %       - `varargin` (/see `help Labels/where` for information about
      %         additional inputs; normally, they won't be specified
      %         here/).
      %     OUT:
      %       - `ind` (logical) -- index of the elements in `selectors`.
      %       - `fields` (cell array) -- fields associated with each 
      %         element in `selectors`.
      
      [ind, fields] = where( obj.labels, selectors, varargin{:} );
    end
    
    %{
        ITERATION
    %}
    
    function c = combs(obj, fields)
      
      %   COMBS -- Get all unique combinations of the labels in `fields`.
      %
      %     See `help Labels/combs` for more information.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- fields in the 
      %         Labels object in `obj.labels`
      %     OUT:
      %       - `c` (cell array of strings) -- Unique combinations of 
      %         labels.
      
      c = combs( obj.labels, fields );
    end
    
    function [indices, comb] = get_indices(obj, fields)
      
      %   GET_INDICES -- Get indices associated with the unique
      %     combinations of unique labels in `fields`.
      %
      %     See help `Labels/get_indices` for more information.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- fields in the
      %         Labels object in `obj.labels`
      %
      %     OUT:
      %       - `indices` (cell array of logicals) -- indices associated 
      %         with the labels identified by each row of `c`
      %       - `comb` (cell array of strings) -- the unique combinations 
      %         of labels in `fields`; each row of c is identified by the
      %         corresponding row of `indices`.
      
      [indices, comb] = get_indices( obj.labels, fields );
    end
    
    %{
        ASSIGNMENT
    %}
    
    function obj = subsasgn(obj, s, values)
      
      %   SUBSASGN -- assign values to the object. 
      %
      %     Almost never will this function be called explicitly -- it's 
      %     invoked when you do something like Container.data(:, 2) = 10.
      %
      %     // '.' assignment //
      %
      %     '.' assignment occurs when attempting to overwrite a property,
      %     e.g., Container.data = `some values`.
      %
      %     Values will be validated before they are accepted. If 
      %     attempting to assign new data to the Container object, the new 
      %     data must have the same number of rows as the object. If 
      %     attempting to assign new labels to the object, the new labels 
      %     must be a `Labels` object, and have the same number of rows as
      %     the `Container`.
      %
      %     // '()' assignment //
      %
      %     '()' assignment is used when a) setting the contents of a field
      %     of the labels object, b) deleting elements of the Container, or
      %     c) assigning new Container elements to the object.
      %
      %     In case a), Container('fieldname') = 'values' is equivalent
      %     to: 
      %
      %     Container.labels = ...
      %       Container.labels.set_field( 'fieldname', 'values' );
      %
      %     You can optionally input an index after 'fieldname' to specify
      %     which elements in 'fieldname' are overwritten:
      %
      %     Container('fieldname', `index`) = 'values', which is equivalent
      %     to:
      %
      %     Container.labels = ...
      %       Container.labels.set_field( 'fieldname', 'values', `index` );
      %
      %     In case b), Container(`index`) = [] deletes the elements
      %     specified by the index. If `index` is a logical, it must be
      %     properly dimensioned (be a column vector with the same number 
      %     of rows as the Container object). If it is instead an array of
      %     numeric indices, an attempt will be made to convert it to a
      %     logical.
      %
      %     In case c) Container(`index`) = `container2` assigns the values
      %     of `container2` to the Container at the index specified by
      %     `index`. Again, `index` can be numeric or logical. If it is
      %     numeric, it must have the same number of elements as
      %     `container2` has rows. If it is logical, it must have the same
      %     number of true values as `container2` has rows.
      %
      %     // EXAMPLES //
      %
      %     cont = Container( data, labels );
      %
      %     cont.data = cell( shape(cont, 1), 10 ); % ok -- the number of
      %                                             % rows didn't change
      %
      %     cont.data -> M x N cell array
      %
      %     cont.data = 10
      %
      %     % Error: When overwriting the data property on the object, the
      %     % number of rows cannot change. Current number of rows is 16519; 
      %     % new values had 1 rows
      %
      %     cont.shape() %  [100 1]
      %
      %     cont(1:10) = []
      %
      %     cont.shape() %  [90 1]
      %
      %     unique( cont('monkeys') ) % { 'jodo', 'kuro', 'tarantino' }
      %
      %     cont('monkeys') = 'jodo'
      %
      %     unique( cont('monkeys') ) % { 'jodo' }
      
      switch ( s(1).type )
        case '.'
          top = subsref( obj, s(1) );
          prop = s(1).subs;
          s(1) = [];
          if ( ~isempty(s) )
            values = subsasgn( top, s, values );
          end
          %   validate the incoming property, and assign if valid.
          obj = set_property( obj, prop, values );
        case '()'
          assert( numel(s) == 1, ...
            'Nested assignments with ''()'' are illegal.' );
          subs = s(1).subs;
          switch class( subs{1} )
            %   if we're going to set a field of the Container.labels
            %   object, e.g., Container('monkeys') = 'jodo'
            case 'char'
              if ( numel(subs) == 1 )
                index = true( shape(obj, 1), 1 ); 
              elseif ( numel(subs) == 2 )
                index = double_to_logical( obj, subs{2} );
              else
                error( ['At maximum, two references can be made when' ...
                  , ' setting a field -- the first is the fieldname,' ...
                  , ' and the second is, optionally, the index.'] );
              end
              obj.labels = set_field( obj.labels, subs{1}, values, index );
            case 'double'
              %   if the format is Container(1:10) = `container_2` or 
              %   Container(ind) = [], i.e., if we're performing element 
              %   deletion, convert subs{1} to a logical index. If values 
              %   is [], return a new object without the elements 
              %   identified by `index`. Otherwise, attempt to assign the
              %   values to the container
              assert( numel(subs) == 1, '(row, col) assignment is not supported.' );
              index = double_to_logical( obj, subs{1} );
              if ( isequal(values, []) )
                obj = keep( obj, ~index );
              elseif ( isa(values, 'Container') )
                obj = overwrite( obj, values, index );
              else
                error( ['Currently, only element deletion with [] and' ...
                  , ' assignment of other Container objects is supported.'] );
              end
            otherwise
              error( ['Expected the first reference to be a char or number,' ...
                , ' but was a ''%s'''], class(subs{1}) );
          end
        otherwise
          error( 'Assignment via ''%s'' is not supported', s(1).type );
      end
    end
    
    function obj = overwrite(obj, B, index)
      
      %   OVERWRITE -- Assign the data and labels of another Container
      %     object to the current Container object at `index`.
      %
      %     Note that several checks as to the validity of the index and
      %     compatability of the two objects are handled in the call to
      %     `overwrite( obj.labels, B.labels, index )`.
      %
      %     IN:
      %       - `B` (Container) -- Object whose contents are to be
      %         assigned. Fields must match between objects.
      %       - `index` (logical) -- Index of where in the assigned-to
      %         object the new labels should be placed. Need have the same
      %         number of true elements as the incoming object, but the
      %         same number of *rows* as the assigned-to object.
      %     OUT:
      %       - `obj` (Container) -- Object with newly assigned values.
      
      if ( ~obj.IGNORE_CHECKS )
        assert__dtypes_match( obj, B );
        assert__columns_match( obj, B );
      end
      obj.labels = overwrite( obj.labels, B.labels, index );
      obj.data(index,:) = B.data;
    end
    
    %{
        REFERENCE
    %}
    
    function out = subsref(obj, s)
      
      %   SUBSREF -- reference properties and call methods on the Container
      %     object, as well as on the Container.labels object. 
      %
      %     Almost never will this function be called explicitly -- it's
      %     called when you do something like Container.('propertyname'), 
      %     or Container(10).
      %
      %     // '.' indexing -- i.e., Container.(subs) //
      %
      %     If `subs` is the name of a Container property, the
      %     property is returned. If `subs` is the name of a Container
      %     method, the method is called on the Container object, with
      %     whatever other inputs are passed. If `subs` is the name of a
      %     *Labels* method, the method is called on the Labels object in
      %     obj.labels, with whatever other inputs are passed. Note that,
      %     in cases where the Container and Container.labels objects have
      %     overlapping method or property names, the returned values or
      %     called methods are *always* those of the Container object.
      %
      %     // '()' indexing -- i.e., Container(subs) //
      %
      %     If `subs` is a cell array with 1 element, whose internal array 
      %     is a logical vector, keep() is called on the object with 
      %     subs{1} as the index. If the internal array is a double ( e.g.,
      %     if you call Container(3), or Container(3:8) ) the double array 
      %     will be converted to a logical array, and then keep() will be 
      %     called. If the internal array is a string / char, the 
      %     get_field() method of the Container.labels object will be 
      %     called with the char as input. In all cases, it is an error for 
      %     more than one item to be placed in parenthetical references. 
      %     E.g., Container(10, 4) is an error; Container('hi', 'hello') 
      %     is an error.
      %
      %     EXAMPLES:
      %
      %     //
      %
      %     cont = Container( data, labels );
      %
      %     cont.nfields();
      %   
      %     ans -> 7
      %
      %     Because nfields() is a method on the labels object in 
      %     cont.labels, it is called directly on that object, and the
      %     result is returned.
      %
      %     //
      %
      %     cont = Container( data, labels );
      %
      %     cont.shape()
      %
      %     ans -> [4, 1]
      %
      %     shape() is a method that exists on both the Container and
      %     Container.labels objects. But we only call the method with the 
      %     Container as input, and return the resulting output.
      %
      %     //
      %
      %     cont = Container( data, labels );
      %
      %     cont.fields
      %
      %     ERROR using Container/subsref: No properties or methods matched
      %     the name 'fields'
      %
      %     Even though fields is a property of the labels object in the
      %     Container, it is not accessible by referencing the Container.
      %     Only *methods* found in the labels object can be called /
      %     referenced, not properties.
      %
      %     //
      %
      %     c = cont([10 13]) % access the tenth and thirteenth rows
      %
      %     c.shape()
      %
      %     ans -> [2 1]
      %
      %     See also Container/subsasgn

      subs = s(1).subs;
      type = s(1).type;
      
      s(1) = [];

      proceed = true;
      
      switch ( type )
        case '.'
          %   if the ref is the name of a Container property, return the
          %   property
          if ( any(strcmp(properties(obj), subs)) && proceed )
            out = obj.(subs); proceed = false;
          end
          %   if the ref is the name of a Container method, call the method
          %   on the Container object (with whatever other inputs are
          %   passed), and return
          if ( any(strcmp(methods(obj), subs)) && proceed )
            func = eval( sprintf('@Container.%s', subs) );
            %   if the ref is to a method, but is called without (), an
            %   error is thrown. E.g., Container.eq -> error ...
            if ( numel(s) == 0 )
              error( ['''%s'' is the name of a Container method, but was' ...
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
            return; %   note -- in this case, we do not proceed
          end
          %   check if the ref is a method of the label object in
          %   Container.labels. If it is, call the method on the labels
          %   object (with whatever other inputs are passed), mutate the
          %   `obj.labels` object, and return
          label_methods = methods( obj.labels );
          if ( any(strcmp(label_methods, subs)) && proceed )
            func = eval( sprintf('@%s', subs) );
            %   if the ref is to a method, but is called without (), an
            %   error is thrown. E.g., Container.uniques -> error ...
            if ( numel(s) == 0 )
              error( ['''%s'' is the name of a Label method, but was' ...
                , ' referenced as if it were a property'], subs );
            end
            inputs = { s(:).subs{:} };
            %   if the output of the called function is a `Labels` object,
            %   assign it back to the Container.labels object, and return
            %   the object. Otherwise, return the output as is.
            labs = func( obj.labels, inputs{:} );
            if ( isa(labs, 'Labels') )
              obj.labels = labs; out = obj; return;
            else out = labs; return;
            end
          end
          if ( proceed )
            error( 'No properties or methods matched the name ''%s''', subs );
          end
        case '()'
          %   make sure we're not attempting to specify (row, col) indices.
          assert( numel(subs) == 1, ...
            ['(row, col) indexing is not supported. Specify monotonically' ...
            , ' increasing row indices only'] );
          %   if the ref is of type double, e.g., if the refs are [1:10],
          %   attempt to create a logical index where elements (1:10) are
          %   true. Will throw an error if any indices are out of bounds,
          %   or if the indices are not monotonically increasing (e.g.,
          %   Container([4 2]) is an error)
          if ( isa(subs{1}, 'double') )
            ind = double_to_logical( obj, subs{1} );
            out = keep( obj, ind ); proceed = false;
          end
          %   else, if subs{1} is already a logical, retain the elements
          %   associated with the index
          if ( isa(subs{1}, 'logical') && proceed )
            out = keep( obj, subs{1} ); proceed = false;
          end
          %   else, if subs{1} is a char, get the labels associated with the
          %   field subs{1]
          if ( isa(subs{1}, 'char') && proceed )
            out = get_fields( obj.labels, subs{1} ); proceed = false;
          end
          %   otherwise, we've attempted to pass an illegal type to the
          %   index
          if ( proceed )
            error( '() Referencing with values of class ''%s'' is not supported', ...
              class(subs{1}) );
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
        EQUALITY AND INTER-OBJECT COMPATIBILITY
    %}
    
    function tf = eq(obj, B)
      
      %   EQ -- test the equality of two Container objects. 
      %
      %     If the second input is not a Container object, false is 
      %     returned. Otherwise, objects are equal if they are of the same
      %     dimension, the same dtype, the same labels, and their data are 
      %     equal.
      %
      %     IN:
      %       - `B` (/any/) -- Input to test equality with.
      %     OUT:
      %       - `tf` (logical) -- true or false.
      
      tf = false;
      if ( ~isa(B, 'Container') ), return; end;
      if ( ~isequal(obj.dtype, B.dtype) ), return; end;
      if ( ne(obj.labels, B.labels) ), return; end;
      tf = isequal( obj.data, B.data );
    end
    
    function tf = ne(obj, B)
      
      %   NE -- opposite of eq(obj, B). See `help Container/eq` for more
      %     information.
      
      tf = ~eq( obj, B );
    end
    
    function tf = shapes_match(obj, B)
      tf = false;
      if ( ~isa(B, 'Container') ), return; end;
      tf = all( shape(obj) == shape(B) );
    end
    
    %{
        INTER-OBJECT FUNCTIONALITY
    %}
    
    function obj = append(obj, B)
      
      %   APPEND -- append one Container to an existing Container. 
      %
      %     If the existing container is empty, the new Container will be 
      %     returned unmodified. Otherwise, the incoming object must a) 
      %     have the same number of columns as the existing object, b) the 
      %     same dtype as the existing object, and c) equivalent labels 
      %     ( see `help Labels/append` for more info ).
      %
      %     IN:
      %       - `B` (Container) -- object to append.
      %     OUT:
      %       - `obj` (Container) -- object with `B` appended.
      
      Assertions.assert__isa( B, 'Container' );
      if ( isempty(obj) ), obj = B; return; end;
      assert__columns_match( obj, B );
      assert__dtypes_match( obj, B );
      obj.labels = append( obj.labels, B.labels );
      obj.data = [ obj.data; B.data ];
    end
    
    %{
        OPERATIONS
    %}
    
    function obj = op(obj, B, func, varargin)
      
      %   OP -- call a function `func` elementwise on the data in two 
      %     objects.
      %
      %     Several checks will take place before operations can occur.
      %     Both objects need have identical shapes, equivalent Label
      %     objects, and the same dtype. Further, the dtypes will have to
      %     be represented in the obj.SUPPORTED_DTYPES array that
      %     corresponds to the inputted function. This means that, 
      %     currently, the list of supported operations is limited to those
      %     in obj.SUPPORTED_DTYPES.
      %
      %     IN:
      %       - `B` (Container) -- second input to the function
      %       - `func` (function_handle) -- function to call on the
      %         objects. Note that `func` must be configured to accept the 
      %         data in `obj`, followed by the data in `B`, followed by any 
      %         other `varargin` inputs.
      %       - `varargin` (/any/) |OPTIONAL| -- additional arguments to 
      %         pass to the func.
      %     OUT:
      %       - `obj` (Container) -- Container object with the mutated
      %         data.
      %
      %     EXAMPLE:
      %       Add two objects:
      %           A = op( A, B, @plus ); % A + B
      %       Subtract two objects:
      %           B = op( A, B, @minus ); % A - B
      
      assert__capable_of_operations( obj, B, func2str(func) );
      switch ( obj.dtype )
        case 'double'
          obj.data = func( obj.data, B.data, varargin{:} );
        case 'cell'
          obj.data = Container.cellwise( func, obj.data, B.data, varargin{:} );
      end
    end
    
    function obj = plus(obj, B)
      
      %   PLUS -- add two Container objects. See `help Container/op` for
      %     more information on requirements for operations.
      
      obj = op( obj, B, @plus );
    end
    
    function obj = minus(obj, B)
      
      %   MINUS -- subtract the data in Container object `B` from the data 
      %     in `obj`. See `help Container/op` for more information on
      %     requirements for operations to occur.
      
      obj = op( obj, B, @minus );
    end
    
    %{
        COMPRESSION + DECOMPRESSION
    %}
    
    function comp = compress(obj, rows, comp)
      
      %   COMPRESS -- Group elements with the same label-set into a cell
      %     array, such that, after grouping all elements, each row of the
      %     compressed object will be identified by a unique label-set.
      %
      %     IN:
      %       - `rows` (double) |OPTIONAL| -- number of rows used to
      %         preallocate the compressed object. Defaults to the number 
      %         of rows in the inputted object.
      %       - `comp` (Labels) |INTERNAL USE ONLY| -- recursively 
      %         populating object. Do not specify this input directly; it 
      %         is used only in subsequent recursive calls to compress().
      %     OUT:
      %       - `comp` (Container) -- compressed Container object in which 
      %         each row of data is a cell array, and the number of rows 
      %         corresponds to the number of unique label-sets in the
      %         object.
      
      if ( nargin < 2 ), rows = shape(obj, 1); end;
      if ( nargin < 3 )
        comp = Container();
        comp = preallocate( comp, cell(rows, 1), nfields(obj.labels) );
      end
      if ( isempty(obj) ), comp = cleanup( comp ); return; end;
      if ( obj.VERBOSE )
        fprintf( '\n ! Container/compress: Remaining items: %d', shape(obj, 1) );
      end
      extr = subsref( obj, struct('type', '()', 'subs', {{1}}) );
      unqs = uniques( extr.labels ); unqs = [ unqs{:} ];
      ind = where( obj.labels, unqs );
      all_matching = keep( obj, ind );
      all_matching.data = { all_matching.data };
      all_matching.labels = extr.labels;
      all_matching.dtype = 'cell';
      comp = populate( comp, all_matching );
      obj = subsref( obj, struct('type', '()', 'subs', {{~ind}}) );
      comp = compress( obj, rows, comp );
    end
    
    function decomped = decompress(obj, rows)
      
      %   DECOMPRESS -- 'Flatten' cell array-stored data, preserving
      %     the labels of each item. If the inner-arrays of the outer array
      %     are matrices, they must have the same number of columns.
      %
      %     IN:
      %       - `rows` |OPTIONAL| -- number of rows to use to preallocate 
      %         the outputted object. By default, will use the current 
      %         number of rows in the object. Generally, this isn't the 
      %         most efficient solution -- if you know, for example, that 
      %         each cell-array contains 100 cell-arrays, it's best to 
      %         specify rows as a much larger value.
      %     OUT:
      %       - `decomped` (Container) -- flattened Container object.
      %
      %     EXAMPLE:
      %     
      %     //
      %   
      %     Let's say `container` is a Container object whose data are a
      %     2-by-1 cell array (i.e., a cell-array with 2 rows, and 1
      %     column). However, each of these arrays might hold matrices of
      %     differing sizes -- perhaps cell(1) is a 100-by-100 matrix, for
      %     example, and cell(2) is a 51-by-100 matrix. Calling decompress()
      %     will first create a new `Container` object preallocated with
      %     zeros. It'll then fill the first 100 rows of the new object with
      %     the values originally stored in cell(1), and it will repeat the
      %     associated labels 100 times. In this way, the original cell(1)
      %     will have been 'flattened'. The process is repeated for cell(2)
      %     -> cell(n). Note again that the number of columns must be
      %     consistent across all inner arrays.
      
      if ( nargin < 2 ), rows = shape(obj, 1); end;
      if ( ~obj.IGNORE_CHECKS )
        if ( isequal(obj.dtype, 'double') )
          opts.msg = 'The object is already decompressed';
        else opts.msg = 'Can only decompress objects with dtype ''cell''';
        end
        Assertions.assert__isa( obj.data, 'cell', opts );
      end
      
      decomped = Container();
      cols = size( obj.data{1}, 2 );
      
      switch class( obj.data{1} )
        case 'double'
          preallocate_with = zeros( rows, cols );
        case 'cell'
          preallocate_with = cell( rows, cols );
        otherwise
          error( ['Cannot decompress the object, because the contents are of type' ...
            , ' ''%s''', class(obj.data{1})] );
      end
      
      decomped = preallocate( decomped, preallocate_with, nfields(obj.labels) );
      
      for i = 1:shape(obj, 1)
        if ( obj.VERBOSE )
          fprintf( '\n ! Container/decompress: Remaining items: %d', ...
            shape(obj, 1)-i );
        end
        extr = subsref( obj, struct( 'type', '()', 'subs', {{i}} ) );
        data = extr.data{1}; %#ok<*PROPLC,*PROP>
        labels = extr.labels;
        appended = labels;
        rows = size( data, 1 );
        if ( rows > 1 )
          for j = 1:rows-1
            appended = append( appended, labels );
          end
        end
        extr.dtype = class( data );
        extr.data = data;
        extr.labels = appended;
        decomped = populate( decomped, extr );
      end
      decomped = cleanup( decomped );
    end    
    
    %{
        UTIL
    %}
    
    function disp(obj)
      fprintf('\n\n%d-by-%d %s Container with Labels:\n', ...
        shape(obj, 1), shape(obj, 2), obj.dtype );
      disp( obj.labels );
    end
    
    function print_labels(obj)
      disp( obj.labels.labels );
    end
    
    function logic = double_to_logical(obj, ind)
      
      %   DOUBLE_TO_LOGICAL -- helper function to convert an array of
      %     numeric indices to a logical index suitable for use by keep(),
      %     etc. 
      %
      %     The values in `ind` must be continuously increasing, greater
      %     than 0, and less than the number of rows in the object.
      %
      %     IN:
      %       - `ind` (double) -- vector of non-zero, non-repeating,
      %         increasing numbers. E.g., [1 2 4] is valid; [2 1 4] is an
      %         error.
      %     OUT:
      %       - 'logic' (logical) -- logical column vector true at each 
      %         value in `ind`, and false elsewhere.
      
      if ( islogical(ind) ), logic = ind; return; end;
      logic = false( shape(obj, 1), 1 );
      if ( isempty(ind) ), return; end;
      assert( isvector(ind), 'The array cannot be a matrix' );
      assert( all(ind > 0), 'The index to-be-converted cannot contain 0s' );
      assert( max(ind) <= shape(obj, 1), 'Requested index is out of bounds' );
      assert( all( sign(diff(ind)) == 1 ), 'The index must be continuously increasing' );
      logic(ind) = true;
    end
    
    %{
        CONVERSION
    %}
    
    function obj = to_data_object(obj)
      
      %   TO_DATA_OBJECT -- Convert the current Container object into a
      %     DataObject.
      %
      %     OUT:
      %       - `obj` (DataObject) -- DataObject representation of the data
      %         and labels in the Container.
      
      labels = label_struct( obj.labels );
      obj = DataObject( obj.data, labels );
    end
    
    %{
        HANDLE PROPERTY SETTING
    %}
    
    function obj = set_property( obj, prop, values )
      
      %   SET_PROPERTY -- internal function that validates and sets the
      %     `label` and `data` properties when subsasgn(obj) is called. 
      %
      %     For an overwritten `data` property to be valid, the new values 
      %     must have the same number of rows as the object. For an 
      %     overwritten `labels` property to be valid, the new values must 
      %     be a `Labels` object with the same number of rows as the 
      %     object. If the new `data` values are valid, the object's 
      %     `dtype` is updated to reflect the class of those values.
      %
      %     IN:
      %       - `prop` ('data' or 'labels') -- name of the property to 
      %         validate.
      %       - `values` (/restrictions apply, see above/) -- values to
      %         assign.
      %     OUT:
      %       - `obj` (Container) -- object with valid properties assigned. 
      %         If the incoming `prop` is 'data', the outputted object will 
      %         have its `dtype` set to the class of the new values.
      
      valid_prop = false;
      if ( strcmp(prop, 'data') )
        assert( shape(obj, 1) == size(values, 1), ...
          ['When overwriting the data property on the object, the number of rows' ...
          , ' cannot change. Current number of rows is %d; new values had %d rows' ...
          , ' %d'], shape(obj, 1), size(values, 1) );
        valid_prop = true;
        obj.dtype = class( values );
      end
      if ( strcmp(prop, 'labels') )
        opts = struct( 'msg', ['When overwriting the labels property on the object,' ...
          , ' the to-be-assigned values must be a Label object with the same shape' ...
          , ' as the Container object'] );
        Assertions.assert__isa( values, 'Labels', opts );
        assert( shape(obj, 1) == shape(values, 1), opts.msg );
        valid_prop = true;
      end
      if ( ~valid_prop )
        error( 'It is an error to directly set the ''%s'' property', prop );
      end
      obj.(prop) = values;
    end
    
    %{
        PREALLOCATION
    %}
    
    function obj = preallocate(obj, with, n_fields)
      
      %   PREALLOCATE -- return a preallocated object filled with the
      %     values in `with` and an empty `Labels` object of the
      %     appropriate size, with `n_fields` fields. 
      %
      %     The initial object must be empty (i.e., derived from an explicit 
      %     call to Container() without inputs); otherwise, an error will 
      %     be thrown.
      %
      %     Once a call to preallocate() has been made, the object is marked
      %     as IS_PREALLOCATING. Calls to populate() will then continuously
      %     fill the data and labels of the object; in this sense it behaves
      %     much like append(), but can be much faster, because the memory
      %     has (at least theoretically) already been allocated.
      %
      %     Once the object is considered fully populated, call cleanup() to
      %     remove excess preallocated values as necessary, and return the
      %     object ready to be used.
      %
      %     IN:
      %       - `with` (/any/) -- the array or matrix to be populated
      %       - `n_fields` (number) -- the number of fields in the
      %         preallocating object's `Labels` object.
      %     OUT:
      %       - `obj` (Container) -- Container object ready to be 
      %         preallocated
      %     EXAMPLE:
      %       cont = Container(); % needs to be empty to begin with
      %
      %       cont = preallocate( cont, zeros(10e3, 1), 8 );
      %
      %       % cont.data is now a 10e3-by-1 array of zeros, and 
      %       % cont.labels is a 10e3-by-8 cell-array-of-strings. I.e., 
      %       % cont.labels has 8 fields (8 columns), and 10e3 rows.
      
      assert( isempty(obj), ...
        'When preallocating, the starting object must be empty' );
      assert( numel(n_fields) == 1, ...
        ['Only specify the number of label fields (not the shape of the labels)' ...
        , ' when preallocating'] );
      
      obj.IS_PREALLOCATING = true;
      obj.PREALLOCATION_ROW = 1;
      obj.PREALLOCATION_SIZE = size( with );
      obj.dtype = class( with );
      obj.data = with;
      obj.labels = preallocate( obj.labels, [size(with, 1) n_fields] );
      
    end
    
    function obj = populate(obj, with)
      
      %   POPULATE -- fill a preallocating object with the contents of
      %     `with`. 
      %
      %     The incoming and preallocating object must share dtypes,
      %     have consistent column dimensions, and have consistent `Label`
      %     objects. Otherwise, an error is thrown. Contents are added
      %     starting at `obj.PREALLOCATION_ROW`, which is continuously
      %     updated with repated calls to populate(), until cleanup() is
      %     called.
      %
      %     IN:
      %       - `with` (Container) -- object whose contents are to be 
      %         stored in the preallocating object.
      %     OUT:
      %       - `obj` (Container) -- the preallocating object, filled with 
      %         the contents of `with`.
      
      assert( obj.IS_PREALLOCATING, ...
        'Can only populate after an explicit call to preallocate()' );
      
      if ( isempty(with) ), return; end;
      if ( ~obj.BEEN_POPULATED ), obj.BEEN_POPULATED = true; end
      
      assert__dtypes_match( obj, with );
      assert__columns_match( obj, with );
      
      start = obj.PREALLOCATION_ROW;
      terminus = start + shape(with, 1) - 1;
      obj.data(start:terminus, :) = with.data;
      obj.labels = populate( obj.labels, with.labels );
      obj.PREALLOCATION_ROW = terminus + 1;
    end
    
    function obj = cleanup(obj)
      
      %   CLEANUP -- Remove excess rows in the preallocating object as 
      %     necessary, and mark that the object is done preallocating. 
      %
      %     Call this function only after the object is fully populated. It
      %     is an error to call cleanup() before at least one call to
      %     populate() has been made.
      
      if ( ~obj.IS_PREALLOCATING ), return; end;
      assert( obj.BEEN_POPULATED, ...
        'The object must be populated before it can be cleaned up' );
      obj.IS_PREALLOCATING = false;
      obj.BEEN_POPULATED = false;
      
      if ( obj.PREALLOCATION_ROW < obj.PREALLOCATION_SIZE(1) )
        obj.data = obj.data( 1:obj.PREALLOCATION_ROW-1, : );
      end
      
      obj.PREALLOCATION_ROW = NaN;
      obj.PREALLOCATION_SIZE = NaN;
      obj.labels = cleanup( obj.labels );
      
      assert( shape(obj, 1) == shape(obj.labels, 1), ...
        ['Preallocation failed: The shapes of the data and label components' ...
        , ' of the object do not match'] );
    end
    
    %{
        OBJECT-SPECIFIC ASSERTIONS
    %}
    
    function assert__shapes_match(obj, B)
      Assertions.assert__isa( B, 'Container' );
      assert( shapes_match(obj, B), 'The shapes of the objects do not match' );
    end
    
    function assert__columns_match(obj, B)
      Assertions.assert__isa( B, 'Container' );
      assert( shape(obj, 2) == shape(B, 2), ...
        'The objects are not equal in the second (column) dimension' );
    end
    
    function assert__dtypes_match(obj, B)
      Assertions.assert__isa( B, 'Container' );
      assert( isequal(obj.dtype, B.dtype), 'The dtypes of the objects do not match' );
    end
    
    function assert__capable_of_operations(obj, B, op_kind)
      assert__shapes_match(obj, B);
      assert__dtypes_match(obj, B);
      assert( eq(obj.labels, B.labels), ...
        ['In order to perform operations, the label objects between two Container' ...
        , ' objects must match exactly'] );
      supports = obj.SUPPORTED_DTYPES.( op_kind );
      assert( any(strcmp(supports, obj.dtype)), ...
        'The ''%s'' operation is not supported with objects of type ''%s''', ...
        op_kind, obj.dtype );      
    end
    
  end
  
  methods (Static = true)
    function [data, labels] = validate__initial_input(data, labels)
      %   make sure labels is a Labels object, or else try converting it
      %   into one
      if ( ~isa(labels, 'Labels') )
        try
          labels = Labels( labels ); 
        catch err
          fprintf( ['\nThe following error occurred when attempting to' ...
            , ' create a `Labels` object:\n\n%s\n'], err.message );
          error( ...
            ['Labels must be a label object or valid input to a label object.' ...
            , ' See `help Labels` for more information'] );
        end
      end
      %   make sure the dimensions are compatible
      assert( size(data, 1) == shape(labels, 1), ...
        'Data must have the same number of rows as labels' );
    end
    
    function A = cellwise(func, A, B, varargin)
      
      %   CELLWISE -- call a function with inputs matched between arrays
      %     `A` and `B`. 
      %
      %     There are no checks on the inputs here, because this is an 
      %     internal function meant to speed up operations between
      %     objects of dtype 'cell'.
      %
      %     IN:
      %       - `func` (function_handle)
      %       - `A` (cell array) -- Must match `B`s dimensions.
      %       - `B` (cell array) -- Must match `A`s dimensions.
      %       - `varargin` (/any/) -- Other inputs to pass into `func`.
      %     OUT:
      %       - `A` (cell array) -- elementwise output of func(A, B).
      
      for i = 1:numel(A)
        A{i} = func( A{i}, B{i}, varargin{:} );
      end
    end
    
    function obj = create_from(obj)
      
      %   CREATE_FROM -- create a Container from another class of object.
      %     Currently, only `DataObject`s are supported.
      %
      %     IN:
      %       - `obj` (DataObject) -- object to convert
      %     OUT:
      %       - `obj` (Container) -- converted object
      
      if ( isa(obj, 'DataObject') )
        obj = Container( obj.data, obj.labels ); return;
      end
      error( 'Cannot create a Container from type ''%s''', class(obj) );
    end
  end
  
end