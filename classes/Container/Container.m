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
    LABELS_ARE_SPARSE = false;
  end
  
  methods
    function obj = Container(data, labels)
      if ( nargin == 0 ), return; end;
      [data, labels] = Container.validate__initial_input( data, labels );
      obj.data = data;
      obj.labels = labels;
      obj.dtype = class( data );
      obj = update_label_sparsity( obj );
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
    
    function obj = update_label_sparsity(obj)
      
      %   UPDATE_LABEL_SPARSITY -- Indicate whether the object currently
      %     has SparseLabels or regular Labels.
      
      obj.LABELS_ARE_SPARSE = isa( obj.labels, 'SparseLabels' );
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
      colons = repmat( {':'}, 1, ndims(obj.data)-1 );
      obj.data = obj.data( ind, colons{:} );
    end
    
    function obj = keep_one(obj, N)
      
      %   KEEP_ONE -- Obtain a single row of the object.
      %
      %     IN:
      %       - `N` (double) |SCALAR| -- Numeric index specifying the
      %         row-number to obtain. Must be greater than 0 and less than
      %         the number of rows in the object.
      %     OUT:
      %       - `obj` (Container) -- Object with one row's worth of data
      %         and labels.
      
      Assertions.assert__isa( N, 'double' );
      assert( isscalar(N), 'Specify a scalar numeric index' );
      ref_struct = struct( 'type', '()', 'subs', {{N}} );
      obj = subsref( obj, ref_struct );      
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
      colons = repmat( {':'}, 1, ndims(obj.data)-1 );
      obj.data = obj.data( ~ind, colons{:} );
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
    
    function [objs, indices, combs] = enumerate(obj, fields)
      
      %   ENUMERATE -- Obtain a cell array of objects, indices, and label
      %     combinations that contain values associated with each unique
      %     combination of labels in the specified fields.
      %
      %     OUT:
      %       - `objs` (cell array of Containers) -- cell array where each
      %         objs{i} is a Container containing the unique combination of
      %         labels present in combs(i, :)
      %       - `indices` (cell array of logicals) -- indices associated 
      %         with the labels identified by each row of `c`
      %       - `combs` (cell array of strings) -- the unique combinations 
      %         of labels in `fields`; each row of combs is identified by
      %         the corresponding row of `indices`.
      
      [indices, combs] = get_indices( obj, fields );
      objs = cell( size(indices) );
      for i = 1:numel(objs)
        objs{i} = keep( obj, indices{i} );
      end
    end
    
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
        OVERLOADED LABELS
    %}
    
    function unqs = uniques(obj, varargin)
      
      %   UNIQUES -- Get unique labels in each field of `obj.labels`
      %
      %     See `help Labels/uniques` for more information.
      %
      %     OUT:
      %       - `unqs` (cell array of cell array(s) of strings)
      
      unqs = uniques( obj.labels, varargin{:} );
    end
    
    function obj = replace(obj, search_for, with)
      
      %   REPLACE -- Replace labels in `search_for` with those in `with`.
      %
      %     See `help Labels/replace` for more information.
      %
      %     IN:
      %       - `search_for` (cell array of strings, char) -- Labels to
      %         replace.
      %       - `with` (char) -- Label to replace-with.
      %     OUT:
      %       - `obj` (Container) -- Container object with its labels
      %         mutated.
      
      obj.labels = replace( obj.labels, search_for, with );
    end
    
    function obj = rm_fields(obj, fields)
      
      %   RM_FIELDS -- Remove specified fields from the labels object.
      %
      %     See `help Labels/rm_fields` for more info.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- Fields to remove.
      %     OUT:
      %       - `obj` (Container) -- Container object with its labels
      %         mutated.
      
      obj.labels = rm_fields( obj.labels, fields );
    end
    
    function obj = add_field(obj, field, set_as)
      
      %   ADD_FIELD -- Add a new field of labels to the labels object.
      %
      %     See `help Labels/add_field` for more info.
      %
      %     IN:
      %       - `field` (char) -- Name of the new field.
      %       - `set_as` (cell array of strings, char) -- Labels to set to
      %         the new field.
      %     OUT:
      %       - `obj` (Container) -- Container object with its labels
      %         mutated.
      
      obj.labels = add_field( obj.labels, field, set_as );
    end
    
    function fields = field_names(obj)
      
      %   FIELD_NAMES -- Get the field / category names of the labels in
      %     the object.
      %
      %     OUT:
      %       - `fields` (cell array of strings) -- Field / category names.
      
      if ( obj.LABELS_ARE_SPARSE )
        fields = unique( obj.labels.categories );
      else fields = obj.labels.fields;
      end      
    end
    
    function [fields, field_names] = full_fields(obj, varargin)
      
      %   FULL_CATEGORIES -- Obtain a cell array of strings whose rows are
      %     labels and columns are categories.
      %
      %     See `help SparseLabels/full_categories` for more info.
      
      [fields, field_names] = full_fields( obj.labels, varargin{:} );
    end
    
    function obj = collapse(obj, fields)
      
      %   COLLAPSE -- Replace labels in a field or fields with a
      %     repeated, field-namespaced expression: 'all__`field`'.
      %
      %     See `help Labels/collapse_fields` for more info.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- Fields to
      %         collapse.
      %     OUT:
      %       - `obj` (Container) -- Container object with its labels
      %         mutated.
      
      obj.labels = collapse( obj.labels, fields );
    end
    
    function obj = collapse_except(obj, fields)
      
      %   COLLAPSE_EXCEPT -- Collapse all fields except those specified.
      %
      %     See `help Labels/collapse_fields` for more info.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- Fields to
      %         collapse.
      %     OUT:
      %       - `obj` (Container) -- Container object with its labels
      %         mutated.
      
      obj.labels = collapse_except( obj.labels, fields );
    end
    
    function obj = collapse_non_uniform(obj)
      
      %   COLLAPSE_NON_UNIFORM -- Collapse categories for which there is
      %     more than one label present in the category.
      %
      %     See `help SparseLabels/get_uniform_categories` for more info.
      
      obj.labels = collapse_non_uniform( obj.labels );
    end
    
    function obj = collapse_if_non_uniform(obj, varargin)
      
      %   COLLAPSE_IF_NON_UNIFORM -- Collapse a given number of categories,
      %     but only if they are non-uniform.
      %
      %     See `help SparseLabels/collapse_non_uniform` for more info.
      
      obj.labels = collapse_if_non_uniform( obj.labels, varargin{:} );
    end
    
    function obj = collapse_uniform(obj)
      
      %   COLLAPSE_UNIFORM -- Collapse categories for which there is
      %     only one label present in the category.
      %
      %     See `help SparseLabels/get_uniform_categories` for more info.
      
      obj.labels = collapse_uniform( obj.labels );
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
      %     must be a `Labels`, or a `SparseLabels` object, and have the 
      %     same number of rows as the `Container`.
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
      %     If labels is a Labels object, you can optionally input an 
      %     index after 'fieldname' to specify which elements in 
      %     'fieldname' are overwritten:
      %
      %     Container('fieldname', `index`) = 'values', which is equivalent
      %     to:
      %
      %     Container.labels = ...
      %       Container.labels.set_field( 'fieldname', 'values', `index` );
      %
      %     Note that indexing is not possible if the labels are
      %     SparseLabels.
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
            values = builtin( 'subsasgn', top, s, values );
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
              if ( isequal(subs{1}, ':') )
                error( 'Assignment with '':'' is not supported.' );
              end
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
            case { 'double', 'logical' }
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
        assert( obj.LABELS_ARE_SPARSE == B.LABELS_ARE_SPARSE, ...
          ['The to-be-assigned object must have the same class of labels' ...
          , ' object as the assigned-to object.'] );
      end
      obj.labels = overwrite( obj.labels, B.labels, index );
      obj.data(index, :) = B.data;
    end
    
    %{
        REFERENCE
    %}
    
    function varargout = subsref(obj, s)
      
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
          if ( proceed && any(strcmp(properties(obj), subs)) )
            out = obj.(subs); proceed = false;
          end
          %   if the ref is the name of a Container method, call the method
          %   on the Container object (with whatever other inputs are
          %   passed), and return
          if ( proceed && any(strcmp(methods(obj), subs)) )
            func = eval( sprintf('@%s', subs) );
            %   if the ref is to a method, but is called without (), an
            %   error is thrown. E.g., Container.eq -> error ...
            if ( numel(s) == 0 )
              error( ['''%s'' is the name of a %s method, but was' ...
                , ' referenced as if it were a property.'], subs, class(obj) );
            end
            inputs = [ {obj} {s(:).subs{:}} ];
            %   assign `out` to the output of func() and return
            [varargout{1:nargout()}] = func( inputs{:} );
            return; %   note -- in this case, we do not proceed
          end
          %   check if the ref is a method of the label object in
          %   Container.labels. If it is, call the method on the labels
          %   object (with whatever other inputs are passed), mutate the
          %   `obj.labels` object, and return
          label_methods = methods( obj.labels );
          if ( proceed && any(strcmp(label_methods, subs)) )
            func = eval( sprintf('@%s', subs) );
            %   if the ref is to a method, but is called without (), an
            %   error is thrown. E.g., Container.uniques -> error ...
            if ( numel(s) == 0 )
              error( ['''%s'' is the name of a %s method, but was' ...
                , ' referenced as if it were a property'], subs, ...
                class(obj.labels) );
            end
            inputs = { s(:).subs{:} };
            %   if the output of the called function is a `Labels` object,
            %   assign it back to the Container.labels object, and return
            %   the object. Otherwise, return the output as is.
            labs = func( obj.labels, inputs{:} );
            if ( isa(labs, 'Labels') || isa(labs, 'SparseLabels') )
              obj.labels = labs; varargout{1} = obj; return;
            else varargout{1} = labs; return;
            end
          end
          if ( proceed )
            %   if we've reached this point, it's because we couldn't find
            %   a property or method that matched the incoming `subs`. In
            %   that case, let's do a check to see if there are any
            %   almost-matches to `subs`. If there are, display them 
            %   before throwing an error.
            matches = maybe_you_meant( obj, subs );
            if ( ~isempty(matches) )
              fprintf( '\n Perhaps you meant ... \n' );
              cellfun( @(x) fprintf('\n - %s', x), matches ); fprintf( '\n\n' );
            end
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
          %   else, if subs{1} is ':', convert the object's data to a
          %   column vector (consistent with the built-in behavior
          %   associated with (:))
          if ( proceed && isequal(subs{1}, ':') )
            out = make_column( obj ); proceed = false;
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
        varargout{1} = out;
        return;
      end
      %   continue referencing if this is a nested reference, e.g.
      %   obj.labels.labels
      [varargout{1:nargout()}] = subsref( out, s );
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
    
    function obj = extend(obj, varargin)
      
      %   EXTEND -- append any number of Container objects to an existing
      %     object, sequentially.
      %
      %     See `help Container/append` for restrictions on appending.
      %
      %     IN:
      %       - `varargin` (cell array of Container objects) -- Objects to
      %         append (in order) to the current object.
      %     OUT:
      %       - `obj` (Container) -- Container with each object in
      %         `varargin` appended to it.
      
      for i = 1:numel(varargin)
        obj = append( obj, varargin{i} );
      end
    end
    
    %{
        OPERATIONS
    %}
    
    function obj = opc(obj, B, fields, func, varargin)
      
      %   OPC -- Perform operations *after* collapsing the given fields of
      %     both inputted objects.
      %
      %     In all other respects, `opc()` is equivalent to `op`. See `help
      %     Container/op` for more information on formatting inputs.
      %
      %     IN:
      %       - `B` (Container) -- Second object passed to the function.
      %       - `fields` (cell array of strings, char) -- Field(s) to
      %         collapse before operations are performed.
      %       - `func` (function_handle) -- Function to call.
      %       - `varargin` (/any/) -- Any additional inputs to pass to each
      %         call of `func`.
      
      collapsed = collapse( obj, fields );
      B = collapse( B, fields );
      obj = op( collapsed, B, func, varargin{:} );
    end
    
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
    
    function obj = rdivide(obj, B)
      
      %   RDIVIDE -- divide the data in the object by the data in `B`. 
      %     See `help Container/op` for more information on requirements 
      %     for operations to occur.
      
      obj = op( obj, B, @rdivide );
    end
    
    function obj = make_column(obj)
      
      %   MAKE_COLUMN -- Convert the data in the object to a column
      %     vector, and repeat labels to match.
      %
      %     Used in obj(:);
      
      n_repeats = shape( obj, 2 );
      obj.data = obj.data(:);
      obj.labels = repeat( obj.labels, n_repeats );
    end
    
    function new_obj = do_across(obj, fields, func, varargin)
      
      %   DO_ACROSS -- Apply a function to the data associated with each
      %     unique combination of labels in the fields of the object,
      %     *except* those specified by `fields.`
      %
      %     The specified function must be configured to accept a Container
      %     object as its first input; additional inputs (applied with each
      %     call to the function) can be passed with varargin. Crucially,
      %     the function must return a Container object; an error is thrown
      %     otherwise.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- Fields to
      %         collapse-across.
      %       - `func` (function_handle) -- Handle to the function
      %         configured as specified above.
      %       - `varargin` (/any/) -- Additional inputs to pass to each
      %       	function call.
      %     OUT:
      %       - `new_obj` (Container) -- Cumulative result of all
      %         function-calls.
      
      obj = collapse_if_non_uniform( obj, fields );
      within = setdiff( field_names(obj), fields );
      if ( isempty(within) )
        error( 'It is an error to specify all fields of the object.' );
      end
      new_obj = do_per( obj, within, func, varargin{:} );
    end
    
    function new_obj = do_per(obj, fields, func, varargin)
      
      %   DO_PER -- Apply a function to the data associated with each
      %     unique combination of labels in the specified fields.
      %
      %     The specified function must be configured to accept a Container
      %     object as its first input; additional inputs (applied with each
      %     call to the function) can be passed with varargin. Crucially,
      %     the function must return a Container object; an error is thrown
      %     otherwise.
      %
      %     See also Labels/combs
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- Fields from which
      %         to draw unique combinations of labels. An error is thrown
      %         if any of the fields do not exist in the labels object.
      %       - `func` (function_handle) -- Handle to the function
      %         configured as specified above.
      %       - `varargin` (/any/) -- Additional inputs to pass to each
      %       	function call.
      %     OUT:
      %       - `new_obj` (Container) -- Cumulative result of all
      %         function-calls.
      
      assert( isa(func, 'function_handle'), ['Expected a function_handle' ...
        , ' as input; was a ''%s'''], class(func) );
      c = combs( obj.labels, fields );
      new_obj = Container();
      for i = 1:size(c, 1)
        ind = where( obj, c(i, :) );
        if ( ~any(ind) ), continue; end;
        extr = keep( obj, ind );
        result = func( extr, varargin{:} );
        assert( isa(result, 'Container'), ['The returned value of a function' ...
          , ' called with do_per() must be a Container; was a ''%s'''] ...
          , class(result) );
        new_obj = append( new_obj, result );
      end
    end
    
    function obj = row_op(obj, func, varargin)
      
      %   ROW_OP -- Execute a function that collapses the object's data
      %     across the first-dimension.
      %
      %     The resulting object will be of size 1xNx ... and thus have
      %     uniform labels. Non-uniform fields of the inputted object will
      %     be collapsed.
      %
      %     This function is not meant to be called directly; instead, it
      %     is the generalized form of functions such as mean, sum, std,
      %     etc.
      %
      %     It is an error to call a function via row_op whose result is a
      %     matrix with more than one row (i.e., the result must be of size
      %     1xMx ... ).
      %
      %     The object must be of dtype 'double'.
      %
      %     IN:
      %       - `func` (function_handle) -- Function to execute.
      %       - `varargin` (/any/) -- Any additional inputs to pass to the
      %         function (usually, dimension specifiers).
      %     OUT:
      %       - `obj` (Container) -- Object whose data are a 1xNx ...
      %         matrix, and whose labels are uniform.
      
      assert( isa(func, 'function_handle'), ['Expected a function_handle' ...
        , ' as input; was a ''%s'''], class(func) );
      assert__dtype_is( obj, 'double' );
      data = func( obj.data, varargin{:} );
      assert( size(data, 1) == 1, ['Data in the inputted object are improperly' ...
        , ' dimensioned; executing function ''%s'' resulted in an object' ...
        , ' whose data have more than one row'] );
      obj = collapse_non_uniform( obj );
      obj = keep_one( obj, 1 );
      obj.data = data;
    end
    
    function obj = n_dimension_op(obj, func, varargin)
      
      %   N_DIMENSION_OP -- Execute a function that mutates the data in the
      %     object along a dimension greater than 1.
      %
      %     The output of the given function must contain the same number
      %     of rows as the original object; the object's dtype must be
      %     'double'.
      %
      %     This function is not meant to be called directly; instead, it
      %     is the generalized form of functions like mean, std, etc. when
      %     acting along a non-row dimension.
      %
      %     IN:
      %       - `func` (function_handle) -- Function to execute.
      %       - `varargin` (/any/) -- Any additional inputs to pass to the
      %         function (usually, dimension specifiers).
      %     OUT:
      %       - `obj` (Container) -- Object whose data are an NxMx ...
      %         matrix, where N is equal to the number of rows in the
      %         inputted object, but where M, ... are not necessarily
      %         equal to the corresponding values 
      
      assert( isa(func, 'function_handle'), ['Expected a function_handle' ...
        , ' as input; was a ''%s'''], class(func) );
      assert__dtype_is( obj, 'double' );
      original_rows = size( obj.data, 1 );
      data = func( obj.data, varargin{:} );
      assert( size(data, 1) == original_rows, ['When executing a function on' ...
        , ' the data in the object along a dimension greater than 1,' ...
        , ' the number of rows in the function''s output must match' ...
        , ' the number of rows in the inputted object.'] );
      obj.data = data;
    end
    
    function obj = mean(obj, dim)
      
      %   MEAN -- Return an object whose data have been averaged across a
      %     given dimension.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- Dimension specifier. Defaults
      %         to 1.
      %
      %     See `help Container/row_op`, `help Container/n_dimension_op` 
      %     for more information.
      
      if ( nargin < 2 ), dim = 1; end;
      if ( isequal(dim, 1) )
        obj = row_op( obj, @mean, 1 );
      else obj = n_dimension_op( obj, @mean, dim );
      end
    end
    
    function obj = sum(obj, dim)
      
      %   SUM -- Return an object whose data have been summed across a
      %     given dimension.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- Dimension specifier. Defaults
      %         to 1.
      %
      %     See `help Container/row_op`, `help Container/n_dimension_op` 
      %     for more information.
      
      if ( nargin < 2 ), dim = 1; end;
      if ( isequal(dim, 1) )
        obj = row_op( obj, @sum, 1 );
      else obj = n_dimension_op( obj, @sum, dim );
      end
    end
    
    function obj = min(obj, dim)
      
      %   MIN -- Return an object whose data are the minimum across a given
      %     dimension.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- Dimension specifier. Defaults
      %         to 1.
      %
      %     See `help Container/row_op`, `help Container/n_dimension_op` 
      %     for more information.
      
      if ( nargin < 2 ), dim = 1; end;
      if ( isequal(dim, 1) )
        obj = row_op( obj, @min, [], 1 );
      else obj = n_dimension_op( obj, @min, [], dim );
      end
    end
    
    function obj = max(obj, dim)
      
      %   MAX -- Return an object whose data are the maximum across a given
      %     dimension.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- Dimension specifier. Defaults
      %         to 1.
      %
      %     See `help Container/row_op`, `help Container/n_dimension_op` 
      %     for more information.
      
      if ( nargin < 2 ), dim = 1; end;
      if ( isequal(dim, 1) )
        obj = row_op( obj, @max, [], 1 );
      else obj = n_dimension_op( obj, @max, [], dim );
      end
    end
    
    function obj = std(obj, dim)
      
      %   STD -- Return an object whose data are the standard-deviation of
      %     the data in the inputted object, across a given dimension.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- Dimension specifier. Defaults
      %         to 1.
      %
      %     See `help Container/row_op`, `help Container/n_dimension_op` 
      %     for more information.
      
      if ( nargin < 2 ), dim = 1; end;
      if ( isequal(dim, 1) )
        obj = row_op( obj, @std, [], 1 );
      else obj = n_dimension_op( obj, @std, [], dim );
      end
    end
    
    function obj = sem(obj, dim)
      
      %   SEM -- Return an object whose data are the standard-error of
      %     the data in the inputted object, across a given dimension.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- Dimension specifier. Defaults
      %         to 1.
      %
      %     See `help Container/row_op`, `help Container/n_dimension_op` 
      %     for more information.
      
      if ( nargin < 2 ), dim = 1; end;
      if ( isequal(dim, 1) )
        obj = row_op( obj, @Container.sem_nd, 1 );
      else obj = n_dimension_op( obj, @Container.sem_nd, dim );
      end
    end
    
    %{
        DATA MANIPULATION
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
      
      assert( ~obj.LABELS_ARE_SPARSE, ['Cannot compress a Container with' ...
        , ' SparseLabels.'] );
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
        SPARSITY
    %}
    
    function obj = full(obj)
      
      %   FULL -- Convert the SparseLabels object in `obj.labels` to a full
      %     Labels object.
      %
      %     A warning is printed if the object's labels are already full.
      
      if ( obj.LABELS_ARE_SPARSE )
        obj.labels = full( obj.labels );
        obj.LABELS_ARE_SPARSE = false;
      else fprintf( '\n ! Container/full: labels are already full Labels' );
      end
    end
    
    function obj = sparse(obj)
      
      %   SPARSE -- Convert the Labels object in `obj.labels` to a
      %     SparseLabels object.
      %
      %     A warning is printed if the object's labels are already
      %     SparseLabels.
      
      if ( obj.LABELS_ARE_SPARSE )
        fprintf( '\n ! Container/sparse: labels are already SparseLabels' );
        return;
      end
      obj.LABELS_ARE_SPARSE = true;
      obj.labels = sparse( obj.labels );
    end
    
    %{
        UTIL
    %}
    
    function s = struct(varargin)
      
      %   STRUCT -- Convert the object to a struct with data and labels
      %     fields.
      %
      %     The labels object will be converted to a struct whose
      %     fields are fields/categories in the labels object, and whose
      %     values are a cell array of strings identifying rows of data.
      %
      %     OUT:
      %       - `s` (struct)
      
      if ( ~isa(varargin{1}, 'Container') )
        s = builtin( 'struct', varargin{:} );
        return;
      else
        narginchk( 1, 1 );
        obj = varargin{1};
      end
      if ( obj.LABELS_ARE_SPARSE )
        obj = full( obj );
      end
      s = struct();
      s.data = obj.data;
      s.labels = label_struct( obj.labels );
    end
    
    function disp(obj)
      
      %   DISP -- Print the size of the data in the object, the class of
      %     data in the object, and the object's labels.
      
      n_dims = ndims( obj.data );
      size_str = num2str( size(obj.data, 1) );
      for i = 2:n_dims
        size_str = sprintf( '%s-by-%d', size_str, size(obj.data, i) );
      end
      fprintf('\n\n%s %s Container with %s:\n', ...
        size_str, obj.dtype, class(obj.labels) );
      disp( obj.labels );
    end
    
    function print_labels(obj)
      disp( obj.labels.labels );
    end
    
    function obj = counts(obj, fields)
      
      %   COUNTS -- Obtain the number of rows associated with each label in
      %     the given fields.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- Fields from which
      %         labels are to be drawn.
            
      obj.data = ones( shape(obj, 1), 1 );
      obj.dtype = class( obj.data );
      obj = do_per( obj, fields, @sum );
    end
    
    function all_matches = maybe_you_meant(obj, str)
      
      %   MAYBE_YOU_MEANT -- Return a cell array of potentially valid
      %     method and/or property names given an invalid property or
      %     method name.
      %
      %     Searches the properties and labels of both the Container and
      %     labels objects, and identifies methods as
      %     `obj_type`/`method_name` if a potential match is a method, or
      %     `obj_type`.`prop_name` if a potential match is a property.
      %
      %     IN:
      %       - str (char) -- The invalid reference string.
      %     OUT:
      %       - all_matches (cell array of strings, empty cell array) --
      %         The potential matches as identified by
      %         `Container.matches_substring()`. See `help
      %         Container/matches_substring` for more information on how
      %         potential matches are computed. If no matches are found,
      %         `all_matches` is an empty cell array.
      
      obj_kinds = { 'Container', class(obj.labels) };
      ref_kinds = { 'methods', 'properties' };
      
      all_matches = {};
      
      for i = 1:numel(obj_kinds)
        obj_kind = obj_kinds{i};
        for j = 1:numel(ref_kinds)
          ref_kind = ref_kinds{j};
          if ( isequal(ref_kind, 'properties') )
            func = @properties; reformatted_format = '%s.%s';
          else func = @methods; reformatted_format = '%s/%s()';
          end
          if ( isequal(obj_kind, 'Container') )
            current_obj = obj;
          else current_obj = obj.labels;
          end
          matches = Container.matches_substring( str, func(current_obj), 2, 4 );
          if ( isempty(matches) ), continue; end;
          matches = ...
            cellfun( @(x) sprintf(reformatted_format, obj_kind, x), matches, ...
            'UniformOutput', false );
          all_matches = [all_matches; matches(:)];
        end
      end
      
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
      
      if ( obj.LABELS_ARE_SPARSE )
        obj = full( obj );
      end
      labels = label_struct( obj.labels );
      obj = DataObject( obj.data, labels );
    end
    
    function tbl = to_table(obj, rows_are, cols_are)
      
      %   TO_TABLE -- Convert the current Container object into a table
      %   	with row and column labels specified by the given fields.
      %
      %     IN:
      %       - `rows_are` (cell array of strings, char)
      %       - `cols_are` (cell array of strings, char) |OPTIONAL| -- If
      %         unspecified, the table will have one column with a dummy
      %         variable header.
      %     OUT:
      %       - `tbl` (table) -- table whose items are cell arrays.
      
      if ( nargin < 3 )
        %   If no column fields are specified, create a new dummy field
        %   with one unique label. Ensure the dummy field and label do 
        %   not already exist in the object.
        stp = 1;
        do_continue = true;
        while ( do_continue )
          dummy_field = sprintf( 'Var%d', stp );
          do_continue = contains_fields(obj.labels, dummy_field) || ...
            contains(obj.labels, dummy_field);
          stp = stp + 1;
        end
        obj = add_field( obj, dummy_field, dummy_field );
        cols_are = dummy_field;
      end
      [~, row_labs] = get_indices( obj, rows_are );
      [~, col_labs] = get_indices( obj, cols_are );
      n_rows = size( row_labs, 1 );
      n_cols = size( col_labs, 1 );
      cols = cell( 1, n_cols );
      cols = cellfun( @(x) cell(n_rows, 1), cols, 'un', false );
      for i = 1:n_rows
        for j = 1:n_cols
          extr = only( obj, [row_labs(i, :), col_labs(j, :)] );
          if ( isempty(extr) ), continue; end;
          cols{j}{i} = extr.data;
        end
      end
      tbl = table( cols{:}, 'VariableNames', str_joiner(col_labs, '_') );
      tbl.Properties.RowNames = str_joiner( row_labs );
      function str = str_joiner( arr, delimiter )
        if ( nargin < 2 ), delimiter = ' | '; end;
        str = cell( size(arr, 1), 1 );
        for ii = 1:size( arr, 1 )
          str{ii} = strjoin( arr(ii, :), delimiter );
        end
      end
    end
    
    function tbl = table(obj, varargin)
      
      %   TABLE -- Alias for `to_table`.
      %
      %     See `help Container/to_table` for more info.
      
      tbl = to_table( obj, varargin{:} );
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
      %     object, or a `SparseLabels` object of the appropriate
      %     dimensions. The object's `LABELS_ARE_SPARSE` private property
      %     will be updated to reflect the class of labels object
      %     to-be-assigned. If the new `data` values are valid, the 
      %     object's `dtype` is  updated to reflect the class of those 
      %     values.
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
          , ' the to-be-assigned values must be a Labels or SparseLabels object' ...
          , ' with the same number of rows as the Container object.'] );
        assert( isa(values, 'Labels') || isa(values, 'SparseLabels'), opts.msg );
        assert( shape(obj, 1) == shape(values, 1), opts.msg );
        obj.LABELS_ARE_SPARSE = isa( values, 'SparseLabels' );
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
    
    function assert__dtype_is(obj, kind)
      assert( strcmp(obj.dtype, kind), ['Expected the object''s dtype to be ''%s''' ...
        , ' but was ''%s'''], kind, obj.dtype );
    end
    
  end
  
  methods (Static = true)
    function [data, labels] = validate__initial_input(data, labels)
      %   make sure labels is a Labels object, or else try converting it
      %   into one
      if ( ~isa(labels, 'Labels') && ~isa(labels, 'SparseLabels') )
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
    
    function y = sem_1d(data)
      
      %   SEM_1D -- Standard error across the first dimension of data.
      %
      %     IN:
      %       - `data` (double)
      %     OUT:
      %       - `y` (double) -- Vector of size 1xM, where M is the number
      %       of columns in `data`.
      
      N = size( data, 1 );
      y = std( data, [], 1 ) / sqrt( N );
    end
    
    function y = sem_nd(data, dim)
      
      %   SEM_ND -- Standard error along a given dimension of data.
      %
      %     IN:
      %       - `data` (double)
      %       - `dim` (double) -- Dimension specifier.
      %     OUT:
      %       - `y` (double) -- Vector of size 1xM, where M is the number
      %       of columns in `data`.
      
      N = size( data, dim );
      y = std( data, [], dim ) / sqrt( N );
    end
    
    function obj = prealc(varargin)
      
      %   PREALC -- Shortcut to instantiate and preallocate a new Container
      %     object.
      %   
      %     See `help Container/preallocate` for more information on
      %     formatting inputs.
      %
      %     OUT:
      %       - `obj` (Container) -- Empty Container object preallocated
      %         with the specified values.
      
      obj = Container();
      obj = preallocate( obj, varargin{:} );
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
    
    function matches = matches_substring(str, comparitors, min_length, max_length)
      
      %   MATCHES_SUBSTRING -- Return elements of a cell array of strings
      %     that include and begin with a given string. 
      %
      %     Specify minimum and max-lengths for the incoming string. If the 
      %     string is longer than the given `max_length`, it
      %     will be truncated to `max_length`. If the string is shorter
      %     than the given `min_length`, the function returns an empty cell
      %     array.
      %
      %     IN:
      %       - `str` (char) -- String to search for.
      %       - `comparitors` (cell array) -- Cell array of strings to
      %         search through.
      %       - `min_length` (number) -- The fewest number of elements the
      %         `str` can have in order to proceed to search for a match.
      %         E.g., one may not wish to search a 10e3-by-10e3 cell array
      %         of strings if the incoming `str` is a single character 'a'.
      %       - `max_length` (number) -- The longest the given `str` can
      %         be. If `str` is longer than `max_length`, the string will
      %         be truncated to `max_length`.
      
      matches = {};
      Assertions.assert__isa( str, 'char' );
      Assertions.assert__is_cellstr( comparitors );
      assert( max_length > 0, 'Maximum string length must be greater than 0' );
      assert( max_length > min_length, ...
        'Maximum string length must be greater than minimum string length' );
      if ( numel(str) < min_length ), return; end;
      if ( numel(str) > max_length ), str = str(1:max_length); end;
      too_big = cellfun( @(x) numel(x) < numel(str), comparitors );
      comparitors(too_big) = [];
      if ( isempty(comparitors) ), return; end;
      does_match = cellfun( @(x) any(min(strfind(x, str)) == 1), comparitors );
      matches = comparitors( does_match );
      
    end
  end
  
end