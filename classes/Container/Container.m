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
    function obj = Container(varargin)
      
      %   CONTAINER -- Instantiate a Container object.
      %
      %     cont = Container( data, labels_object ) creates a Container
      %     object from `data` and a Labels or SparseLabels object 
      %     `labels_object`.
      %
      %     cont = Container( data, labels_struct ) creates a Container
      %     object from `data` and a struct `labels_struct`, which must
      %     be valid input to a Labels object. Each field of
      %     `labels_struct` must be an Mx1 cell array of strings where M is
      %     equal to the number of rows in `data`.
      %
      %     cont = Container( data, 'field1', {'label1'; 'label2'}, ... )
      %     creates a Container object from `data` and a variable number of
      %     (field, {labels}) pairs, which are parsed to create a struct as
      %     above.
      %
      %     Ex. //
      %
      %     data = rand( 20, 1 );
      %     outs = repmat( {'self'; 'both'; 'other'; 'none'}, 5, 1 );
      %     rwds = repmat( {'low'; 'medium'; 'high'; 'highest'}, 5, 1 );
      %     outs = outs( randperm(numel(outs)) );
      %     rwds = rwds( randperm(numel(rwds)) );
      %     cont = Container( data, 'outcomes', outs, 'rewards', rwds );
      %
      %     See also Container/parfor_each, Container/subsref
      
      if ( nargin == 0 ), return; end
      if ( nargin == 2 )
        data = varargin{1};
        labels = varargin{2};
        [data, labels] = Container.validate__initial_input( data, labels );
        obj.data = data;
        obj.labels = labels;
        obj.dtype = class( data );
        obj = update_label_sparsity( obj );
        %   MARK: Made labels sparse by default.
        obj = sparse( obj );
      else
        try
          obj = Container.create( varargin{:} );
        catch err
          throwAsCaller( err );
        end
      end
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
      
      if ( nargin < 2 ), return; end
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
      
      %   SHAPE -- Return the size of the data in the object.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- dimension(s) of the data to 
      %         query.
      %     OUT:
      %       - `s` (double) -- dimensions.
      
      s = size( obj.data );
      if ( nargin < 2 ), return; end
      s = s( dim );
    end
    
    function n = nels(obj)
      
      %   NELS -- Return the total number of data elements in the object.
      %
      %     OUT:
      %       - `n` (double) |SCALAR|
      
      n = numel( obj.data );
    end
    
    function n = nfields(obj)
      
      %   NFIELDS -- Return the number of label fields in the labels
      %     object.
      %
      %     OUT:
      %       - `n` (double) |SCALAR|
      
      n = nfields( obj.labels );
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
      
      if ( nargin < 2 ), N = 1; end
      Assertions.assert__isa( N, 'double' );
      assert( isscalar(N), 'Specify a scalar numeric index' );
      ref_struct = struct( 'type', '()', 'subs', {{N}} );
      obj = subsref( obj, ref_struct );      
    end
    
    function obj = one(obj)
      
      %   ONE -- Obtain a single element.
      %
      %     newobj = one( obj ); returns a 1x1 Container whose data are NaN
      %     and whose labels are like those of `obj`, except that
      %     the non-uniform fields of `obj` are collapsed.
      %
      %     See also Container/keep_one, Container/row_op, Container/mean
      
      obj = collapse_non_uniform( obj );
      obj = keep_one( obj );
      obj = set_property( obj, 'data', NaN );
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
      
      %   RM -- shorthand alias for remove().
      %
      %     See also Container/remove
      
      [obj, ind] = remove( obj, selectors );
    end
    
    function [obj, ind] = only(obj, selectors)
      
      %   ONLY -- retain elements in `obj.data` that match the index of the
      %     `selectors`.
      %
      %     See also Labels/only, Labels/where
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
    
    function [obj, ind] = only_substr(obj, substrs)
      
      %   ONLY_SUBSTR -- retain elements in `obj.data` that match the 
      %     index associated with labels identified by `substrs`.
      %
      %     See also Container/only
      %
      %     IN:
      %       - `substrs` (cell array of strings, char) -- Substrings to
      %         identify labels to keep.
      %     OUT:
      %       - `obj` (Container)
      %       - `ind` (logical) -- The index used to select rows of the 
      %         object.
      
      ind = where_substr( obj.labels, substrs );
      obj = keep( obj, ind );
    end
    
    function [ind, fields] = where(obj, selectors, varargin)
      
      %   WHERE -- generate an index of the labels in `selectors`.
      %
      %     See also Labels/where
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
    
    function [ind, fields] = where_substr(obj, substrs)
      
      %   WHERE_SUBSTR -- Return an index of rows identified by substrs.
      %
      %     See also Container/where
      %
      %     IN:
      %       - `substrs` (cell array of strings, char) -- Substrings to
      %         search for.
      %     OUT:
      %       - `ind` (logical) -- index of the elements in `selectors`.
      %       - `fields` (cell array) -- fields associated with each 
      %         element in `substrs`.
      
      [ind, fields] = where_substr( obj.labels, substrs );
    end
    
    function tf = contains(obj, labs)
      
      %   CONTAINS -- Return whether the given labels are present in the
      %     Container's labels object.
      %
      %     tf = contains( obj, 'ny' ) returns true if 'ny' is a label
      %     present in the Container's labels object.
      %
      %     tf = contains( obj, {'ny', 'la'} ) returns a 1x2 logical array
      %     where tf(1) corresponds to 'ny', and tf(2) to 'la'.
      %
      %     See also Labels/contains, SparseLabels/contains
      %
      %     IN:
      %       - `labs` (cell array of strings, char)
      %     OUT:
      %       - `tf` (logical)
      
      tf = contains( obj.labels, labs );
    end
    
    %{
        ITERATION
    %}
    
    function [objs, indices, combs] = enumerate(obj, fields)
      
      %   ENUMERATE -- Enumerate objects for combinations of labels.
      %
      %     objs = enumerate( obj, 'cities' ) returns an Mx1 cell array of
      %     Container objects, in which each element contains only one
      %     label in the field / category 'cities'.
      %
      %     objs = enumerate( obj, {'cities', 'states'} ) works as above,
      %     except that each element contains only one 'cities' x 'states'
      %     pair.
      %
      %     [objs, indices, combs] = enumerate( ... ) also returns the
      %     indices and combinations of labels in `fields` used to select
      %     each object.
      %
      %     IN:
      %       - `fields` (cell array of strings, char, {})
      %     OUT:
      %       - `objs` (cell array of Containers)
      %       - `indices` (cell array of logicals)
      %       - `combs` (cell array of strings)
      
      if ( isempty(fields) )
        objs = { obj };
        indices = { logic(obj, true) };
        combs = {};
        return;
      end
      [indices, combs] = get_indices( obj, fields );
      objs = cellfun( @(x) keep(obj, x), indices, 'un', false );
    end
    
    function c = combs(obj, fields)
      
      %   COMBS -- Return all possible combinations of labels.
      %
      %     c = combs( obj, {'cities', 'states'} ) returns an Mx2 cell
      %     array of M possible combinations of 'cities' x 'states' labels,
      %     not all of which necessarily exist in `obj`.
      %
      %     See also Container/pcombs
      %
      %     IN:
      %       - `fields` (cell array of strings, char)
      %     OUT:
      %       - `c` (cell array of strings)
      
      c = combs( obj.labels, fields );
    end
    
    function c = pcombs(obj, fields)
      
      %   PCOMBS -- Return present unique combinations of labels.
      %
      %     c = pcombs( obj, {'cities', 'states'} ) returns an Mx2 cell
      %     array of M combinations of labels in the fields 'cities' and 
      %     'states'. Each combination is guaranteed to exist in `obj`.
      %
      %     See also SparseLabels/rget_indices, Container/combs
      %
      %     IN:
      %       - `fields` (cell array of strings, char)
      %     OUT:
      %       - `c` (cell array of strings)
      
      [~, c] = get_indices( obj, fields );
    end
    
    function [indices, comb] = get_indices(obj, fields)
      
      %   GET_INDICES -- Get indices of label combinations.
      %
      %     See also SparseLabels/rget_indices
      %
      %     IN:
      %       - `fields` (cell array of strings, char)
      %     OUT:
      %       - `indices` (cell array of logicals) -- indices associated 
      %         with the labels identified by each row of `c`.
      %       - `comb` (cell array of strings) -- the unique combinations 
      %         of labels in `fields`; each row of c is identified by the
      %         corresponding row of `indices`.
      
      [indices, comb] = rget_indices( obj.labels, fields );
    end
    
    %{
        OVERLOADED LABELS
    %}
    
    function unqs = uniques(obj, varargin)
      
      %   UNIQUES -- Get unique labels in each field of `obj.labels`
      %
      %     See also Labels/uniques
      %
      %     OUT:
      %       - `unqs` (cell array of cell array(s) of strings)
      
      unqs = uniques( obj.labels, varargin{:} );
    end
    
    function obj = replace(obj, search_for, with)
      
      %   REPLACE -- Replace labels in `search_for` with those in `with`.
      %
      %     See also Labels/replace
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
      %     See also Labels/rm_fields
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- Fields to remove.
      %     OUT:
      %       - `obj` (Container) -- Container object with its labels
      %         mutated.
      
      obj.labels = rm_fields( obj.labels, fields );
    end
    
    function obj = rm_uniform_fields(obj)
      
      %   RM_UNIFORM_FIELDS -- Remove fields for which there is
      %     only one unique label present.
      
      obj.labels = rm_uniform_fields( obj.labels );
    end
    
    function obj = add_field(obj, varargin)
      
      %   ADD_FIELD -- Add a new field of labels to the labels object.
      %
      %     See also Labels/add_field
      %
      %     IN:
      %       - `varargin` (cell array of strings, char) -- Name of the new
      %         field, and optionally the labels to set to the new field.
      %     OUT:
      %       - `obj` (Container) -- Container object with its labels
      %         mutated.
      
      obj.labels = add_field( obj.labels, varargin{:} );
    end
    
    function obj = require_fields(obj, fs)
      
      %   REQUIRE_FIELDS -- Add fields if they do not already exist.
      %
      %     IN:
      %       - `fs` (cell array of strings, char) -- Fields to require.
      
      fs = SparseLabels.ensure_cell( fs );
      Assertions.assert__is_cellstr( fs );
      if ( isempty(fs) ), return; end
      are_present = contains_fields( obj.labels, fs );
      if ( all(are_present) ), return; end
      new_fs = fs( ~are_present );
      for i = 1:numel(new_fs)
        obj = obj.add_field( new_fs{i} );
      end
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
    
    function cats = categories(obj)
      
      %   CATEGORIES -- Alias for `field_names`.
      
      cats = field_names( obj );
    end
    
    function [fields, field_names] = full_fields(obj, varargin)
      
      %   FULL_CATEGORIES -- Obtain a cell array of strings whose rows are
      %     labels and columns are categories.
      %
      %     See also SparseLabels/full_categories
      
      [fields, field_names] = full_fields( obj.labels, varargin{:} );
    end
    
    function obj = collapse(obj, fields)
      
      %   COLLAPSE -- Replace labels in a field or fields with a
      %     repeated, field-namespaced expression: 'all__`field`'.
      %
      %     See also Labels/collapse_fields
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
      %     See also Labels/collapse_fields
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
      %     See also SparseLabels/get_uniform_categories
      
      obj.labels = collapse_non_uniform( obj.labels );
    end
    
    function obj = collapse_if_non_uniform(obj, varargin)
      
      %   COLLAPSE_IF_NON_UNIFORM -- Collapse a given number of categories,
      %     but only if they are non-uniform.
      %
      %     See also SparseLabels/collapse_non_uniform
      
      obj.labels = collapse_if_non_uniform( obj.labels, varargin{:} );
    end
    
    function obj = collapse_uniform(obj)
      
      %   COLLAPSE_UNIFORM -- Collapse categories for which there is
      %     only one label present in the category.
      %
      %     See also SparseLabels/get_uniform_categories
      
      obj.labels = collapse_uniform( obj.labels );
    end
    
    %{
        ASSIGNMENT
    %}
    
    function obj = subsasgn(obj, s, values)
      
      %   SUBSASGN -- Assign values to the object.
      %
      %     obj.data = newdata assigns new data to the object. Incoming
      %     data must have the same 1st-dimension size as the overwritten
      %     data.
      %
      %     obj.labels = newlabels assigns new labels to the object.
      %     Incoming labels must be a `SparseLabels` or `Labels` object
      %     with the same 1st-dimension shape as the overwritten labels.
      %
      %     obj( 'date' ) = 'May-05-2017', where 'date' is a category /
      %     field of labels, assigns each element of 'date' to 
      %     'May-05-2017'.
      %
      %     obj('date', :) = 'May-05-2017' is the same as above.
      %
      %     obj( 'date', index ) = 'May-05-2017' overwrites labels in
      %     'date' at `index`. `index` can be logical or numeric; if it
      %     is numeric, it must be continuously increasing, and cannot
      %     contain duplicate values.
      %
      %     obj(1) = [] deletes the first element of `obj`.
      %
      %     obj(1:10) = otherobj replaces elements 1:10 in `obj` with
      %     `otherobj`. `otherobj` must be a Container whose data are of
      %     the same class and size (beyond the 1-st dimension) as that of
      %     `obj`. The labels in `otherobj` must have the same fields /
      %     categories as `obj`, and be of the same class.
      %
      %     See also Container/subsref, SparseLabels/set_field
      %
      %     IN:
      %       - `s` (struct) -- Reference struct.
      %       - `values` (/any/) -- Values to assign.
      
      try
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
                  if ( ischar(subs{2}) && strcmp(subs{2}, ':') )
                    index = logic( obj, true );
                  else
                    assert( isa(subs{2}, 'double') || ...
                      isa(subs{2}, 'logical'), ['Expected the index' ...
                      , ' to be a double or logical; was a ''%s''.'] ...
                      , class(subs{2}) );
                    index = double_to_logical( obj, subs{2} );
                  end
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
                assert( numel(subs) == 1, ['Multidimensional assignment is not' ...
                  , ' supported in this context.'] );
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
      catch err
        throwAsCaller( err );
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
      
      %   SUBSREF -- Get properties and call methods of the object.
      %
      %     prop = obj.labels or prop = obj.('labels') returns the property
      %     'labels'.
      %
      %     output = obj.for_each(in1, in2, ... in_n) calls the Container
      %     method `for_each` with inputs `in1` ... `in_n`.
      %
      %     newobj = obj(1) returns the first element of `obj`.
      %
      %     newobj = obj([1; 100; 4]) returns the 1st, 100th, and 4th
      %     elements of `obj`, in that order.
      %
      %     newobj = obj([true; false; false]), where `obj` is a 3-by-N-by-
      %     ... Container, returns the first element of `obj`.
      %
      %     newobj = obj( 'dates' ), where 'dates' is a field of labels, 
      %     returns the unique labels in 'dates'.
      %
      %     newobj = obj( 'dates', [5; 6] ), where 'dates' is a field of 
      %     labels, returns the labels in 'dates' at rows 5:6.
      %
      %     newobj = obj( 'dates', : ) returns the full field of 'dates'.
      %
      %     IN:
      %       - `s` (struct) -- Reference struct.
      %
      %     See also Container/subsasgn
      
      try
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
                s(1).subs = {};
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
            nsubs = numel( subs );
            %   ensure we're not doing x()
            assert( nsubs ~= 0, ['Attempted to reference a variable' ...
              , ' as if it were a function.'] );
            %   ensure we're not doing x(1, 2, 3)
            if ( ~ischar(subs{1}) )
              assert( nsubs == 1, ['Multidimensional indexing is not' ...
                , ' supported in this context.'] );
            end
            %   use a numeric index
            if ( isa(subs{1}, 'double') )
              out = numeric_index( obj, subs{1} );
              proceed = false;
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
              assert( nsubs == 1, ['Multidimensional indexing is not' ...
                , ' supported in this context.'] );
              out = make_column( obj ); proceed = false;
            end
            %   obj('images') returns the unique labels in 'images'.
            %   obj('images', 100) returns the 100th label in the field
            %   'images'.
            %   obj('images', :) returns the full field of 'images'.
            if ( isa(subs{1}, 'char') && proceed )
              assert( nsubs <= 2, 'Too many subscripts.' );
              if ( numel(subs) == 1 )
                out = get_fields( obj.labels, subs{1} );
              else
                ind_ = subs{2};
                if ( isa(ind_, 'logical') )
                  assert__is_properly_dimensioned_logical( obj.labels, ind_ );
                elseif ( isa(ind_, 'double') )
                  assert__is_valid_numeric_index( obj.labels, ind_ );
                else
                  msg = sprintf( ['Label-field referencing with values of' ...
                    , ' class ''%s'' is not supported.'], class(ind_) );
                  assert( ischar(ind_), msg);
                  assert( strcmp(ind_, ':'), msg ); 
                end
                out = full_fields( obj, subs{1} );
                out = out( ind_ );
              end
              proceed = false;
            end
            %   otherwise, we've attempted to pass an illegal type to the
            %   index
            if ( proceed )
              error( '() Referencing with values of class ''%s'' is not supported.', ...
                class(subs{1}) );
            end
          otherwise
            error( 'Referencing with ''%s'' is not supported', type );
        end

        if ( isempty(s) )
          varargout{1} = out;
          return;
        end
        %   continue referencing if this is a nested reference, e.g.
        %   obj.labels.labels
        [varargout{1:nargout()}] = subsref( out, s );
      catch err
        throwAsCaller( err );
      end
    end
    
    function s = end(obj, ind, N)
      
      %   END -- Return the number of rows in the object.
      
      s = shape( obj, 1 );
    end
    
    function obj = numeric_index(obj, ind)
      
      %   NUMERIC_INDEX -- Apply a numeric index to the object.
      %
      %     newobj = numeric_index( obj, [2; 3; 4] ) returns a new
      %     3-by-M-by-... object whose data and labels are the 2nd, 3rd, 
      %     and 4th rows of `obj`.
      %
      %     newobj = numeric_index( obj, [2; 2; 2; 2] ) returns a new
      %     4-by-M-by-... object whose data and labels are duplicates of
      %     the 2nd row of `obj`.
      %
      %     IN:
      %       - `ind` (double) |VECTOR|
      
      try
        obj.labels = numeric_index( obj.labels, ind );
        colons = repmat( {':'}, 1, ndims(obj.data)-1 );
        obj.data = obj.data( ind, colons{:} );
      catch err
        throwAsCaller( err );
      end
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
      if ( ~isa(B, 'Container') ), return; end
      if ( ~isequal(obj.dtype, B.dtype) ), return; end
      if ( ne(obj.labels, B.labels) ), return; end
      tf = isequaln( obj.data, B.data );
    end
    
    function tf = ne(obj, B)
      
      %   NE -- opposite of eq(obj, B). See `help Container/eq` for more
      %     information.
      
      tf = ~eq( obj, B );
    end
    
    function tf = shapes_match(obj, B)
      
      %   SHAPES_MATCH -- True if two Container objects have matching
      %     shapes.
      
      tf = false;
      if ( ~isa(B, 'Container') ), return; end
      tf = all( shape(obj) == shape(B) );
    end
    
    function tf = eq_contents(obj, B)
      
      %   EQ_CONTENTS -- Return whether two objects have equal contents.
      %
      %     Two Container objects A and B are said to have equal contents
      %     if, for each unique set of labels in A, the subsets of A and B
      %     identified by that label-set are equal. 
      %
      %     For example, if A and B are two Container objects, 
      %     C = append( A, B ), and D = append( B, A ), then:
      %
      %     C == D               % false
      %     eq_contents( C, D )  % true
      %
      %     IN:
      %       - `B` (/any/) -- Values to test.
      %     OUT:
      %       - `tf` (logical) |SCALAR|
      
      tf = false;
      if ( eq(obj, B) ), tf = true; return; end
      if ( ~isa(B, 'Container') ), return; end
      if ( ~isequal(obj.dtype, B.dtype) ), return; end
      if ( ~shapes_match(obj, B) ), return; end
      if ( ~shapes_match(obj.labels, B.labels) ), return; end
      while ( ~isempty(obj) )
        %   take the first row of `obj`
        first = keep_one( obj );
        %   get the labels of that first row
        unqs = flat_uniques( first.labels, categories(obj) );
        %   locate all elements that match these labels in both `obj` and
        %   `B`
        ind_a = where( obj, unqs );
        ind_b = where( B, unqs );
        if ( sum(ind_a) ~= sum(ind_b) ), return; end
        A2 = keep( obj, ind_a );
        B2 = keep( B, ind_b );
        %   if the subsets of `obj` and `B` identified by `unqs` are not
        %   equal, the contents are not equal.
        if ( ne(A2, B2) ), return; end
        obj = keep( obj, ~ind_a );
      end
      tf = true;
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
      if ( isempty(obj) ), obj = B; return; end
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
    
    function obj = vertcat(obj, varargin)
      
      %   VERTCAT -- Alias for `extend()`.
      %
      %     See `help Container/extend` for more info.
      
      obj = extend( obj, varargin{:} );
    end
    
    function varargout = horzcat(varargin)
      
      %   HORZCAT -- Throw a more descriptive error when attempting
      %     horizontal concatenation.
      
      error( ['Horizontal / column-wise concatenation is not supported.' ...
        , ' Use vertical concatenation or the append() method.'] );
    end
    
    %{
        OPERATIONS
    %}
    
    function obj = opc(obj, B, fields, func, varargin)
      
      %   OPC -- Perform operations after collapsing the given fields of
      %     both inputted objects.
      %
      %     In all other respects, `opc()` is equivalent to `op()`.
      %
      %     EXAMPLE:
      %
      %     A = opc( A, B, {'dates', 'places'}, @minus ) collapses the
      %     fields 'dates' and 'places' in both A and B, and then calls the
      %     function @minus with A and B as inputs. I.e., in this case, A =
      %     A - B.
      %
      %     See also Container/op
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
      
      %   OP -- Call a function element-wise on the data in two objects.
      %
      %     obj = op( A, B, func ) is the generalized form of binary
      %     operations like + and - .
      %
      %     obj = op( A, B, @minus ) is equivalent to A - B.
      %
      %     A and B need have identical shapes, compatible label
      %     objects, and matching `dtype`s; `dtype` can be 'double' or
      %     'cell'. Labels objects are considered compatible if they are of 
      %     the same class and equivalent apart from their uniform fields.
      %
      %     For example, let:
      %
      %     A = Container( [10; 11] ...
      %       , 'dose', 'high' ...
      %       , 'date', {'May-04-2017'; 'May-05-2017'} ...
      %     );
      %
      %     B = Container( [12; 13] ...
      %       , 'dose', 'low' ...
      %       , 'date', {'May-04-2017'; 'May-05-2017'} ...
      %     );
      %
      %     C = Container( [14; 15] ...
      %       , 'dose', 'low' ...
      %       , 'date', {'May-06-2017'; 'May-07-2017'} ...
      %     );
      %
      %     D = Container( [14; 15; 16] ...
      %       , 'dose', 'low' ...
      %       , 'date', 'May-08-2017' ...
      %     );
      %
      %     obj = op( A, A, @minus ) works: the shape of A matches the
      %     shape of A, and the label objects of A and A are identical.
      %     obj.data is A.data - A.data, and the labels in `obj` are
      %     identical to the labels in A.
      %       
      %     obj = op( A, B, @minus ) works: the non-uniform fields of A and
      %     B ('date') are equivalent. The data in `obj` is A.data -
      %     B.data. The uniform fields of A and B for which A and B have 
      %     different labels ('dose') are modified to reflect the 
      %     operation: the 'dose' field of `obj` becomes 'high_minus_low'.
      %
      %     obj = op( B, C, @minus ) does not work: the non-uniform fields
      %     of B and C ('date') are different.
      %
      %     obj = op( B, D, @minus ) does not work: the shapes of B and D
      %     are different.
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
      %       - `obj` (Container) -- Container object with mutated
      %         data and labels.
      
      try
        name = func2str( func );
        assert__capable_of_operations( obj, B, name );
        switch ( obj.dtype )
          case 'double'
            obj.data = func( obj.data, B.data, varargin{:} );
          case 'cell'
            obj.data = Container.cellwise( func, obj.data, B.data ...
              , varargin{:} );
        end
        un = get_uniform_fields( obj.labels );
        for i = 1:numel(un)
          unq_a = char( flat_uniques(obj.labels, un{i}) );
          unq_b = char( flat_uniques(B.labels, un{i}) );
          if ( strcmp(unq_a, unq_b) ), continue; end
          joined = sprintf( '%s_%s_%s', unq_a, name, unq_b );
          obj.labels = set_field( obj.labels, un{i}, joined );
        end
      catch err
        throwAsCaller( err );
      end
    end
    
    function obj = plus(obj, B)
      
      %   PLUS -- Add two Container objects.
      %
      %     See also Container/op
      
      obj = op( obj, B, @plus );
    end
    
    function obj = minus(obj, B)
      
      %   MINUS -- Subtract one Container object from another.
      %
      %     See also Container/op
      
      obj = op( obj, B, @minus );
    end
    
    function obj = rdivide(obj, B)
      
      %   RDIVIDE -- Divide one Container object by another.
      %
      %     See also Container/op
      
      obj = op( obj, B, @rdivide );
    end
    
    function obj = times(obj, B)
      
      %   TIMES -- Element-wise multiplication of two Container objects.
      %
      %     See also Container/op
      
      obj = op( obj, B, @times );
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
        if ( ~any(ind) ), continue; end
        extr = keep( obj, ind );
        result = func( extr, varargin{:} );
        assert( isa(result, 'Container'), ['The returned value of a function' ...
          , ' called with do_per() must be a Container; was a ''%s'''] ...
          , class(result) );
        new_obj = append( new_obj, result );
      end
    end
    
    function obj = do_recursive(obj, varargin)
      
      %   DO_RECURSIVE -- Alias for `for_each`.
      %
      %     See also Container/for_each
      
      try
        obj = for_each( obj, varargin{:} );
      catch err
        throwAsCaller( err );
      end
    end
    
    function obj = do(obj, varargin)
      
      %   DO -- Alias for `do_recursive`.
      %
      %     See also Container/do_recursive
      
      obj = do_recursive( obj, varargin{:} );
    end
    
    function out = parfor_each(obj, varargin)
      
      %   PARFOR_EACH -- Apply a function to the unique combinations of
      %     labels in the given fields, in parallel.
      %
      %     obj = parfor_each( obj, 'date', @mean ) creates separate
      %     data subsets for each 'date', distributes those subsets
      %     among N workers, and allows each worker to independently
      %     calculate a mean for each 'date' in its subset. N is either the
      %     number of workers in the current parpool, or the number of
      %     'date's, if there are fewer 'date's than workers. If no pool
      %     exists, no pool is created, and the non-parellelized version of
      %     for_each is called instead.
      %
      %     obj = parfor_each( obj, {'date', 'region'}, @mean ) works the
      %     same as above, but subsets are drawn from the unique
      %     combinations of 'date' and 'region'.
      %
      %     obj = parfor_each( obj, {'date', 'region'}, 'date', @mean )
      %     works the same as above, but subsets are drawn only from
      %     'date'. Specifying 'date' in this way does not change the
      %     output `obj`; it only changes the way subsets of `obj` are
      %     distributed among workers.
      %
      %     obj = parfor_each( obj, ..., func, in1, in2, ... inN ) applies
      %     the inputs `in1` ... `inN` to each call of `func`.
      %
      %     IN:
      %       - `varargin` (cell array)
      %
      %     See also Container/for_each
      
      narginchk( 3, Inf );
      within = Labels.ensure_cell( varargin{1} );
      Assertions.assert__is_cellstr( within );
      dup_msg = 'At least one duplicate %s field was specified.';
      assert( numel(unique(within)) == numel(within), dup_msg, 'within' );
      within = unique( within );
      p = gcp( 'nocreate' );
      if ( ~isempty(p) )
        psize = p.NumWorkers;
      else
        psize = 0;
      end
      if ( isa(varargin{2}, 'function_handle') )
        func = varargin{2};
        if ( ~isempty(p) )
          %   Choose the fields / categories to form the label-sets to be
          %   distributed to each worker. Choose the combination of fields
          %   (up to MAX_CHOOSE) that minimizes the difference between the
          %   number of label-sets and the number of workers.
          MAX_CHOOSE = 2;
          n_unqs = cellfun( @(x) numel(x), uniques(obj, within) );
          max_n = min( MAX_CHOOSE, numel(within) );
          ids = 1:numel( n_unqs );
          combs_n = combnk( n_unqs, max_n );
          combs_ids = combnk( ids, max_n );
          product = prod( combs_n, 2 );
          difference = abs( product - psize );
          difference_single = abs( n_unqs - psize );
          min_mult = min( difference );
          min_single = min( difference_single );
          if ( min_single < min_mult )
            all_inds = 1:numel( n_unqs );
            min_single_ind = find( difference_single == min_single, 1, 'first' );
            first = within( min_single_ind );
            rest = within( setdiff(all_inds, min_single_ind) );
          else
            min_mult_ind = find( difference == min_mult, 1, 'first' );
            row_ids = combs_ids( min_mult_ind, : );
            first = within( row_ids );
            rest = within( setdiff(combs_ids(:), row_ids) );
          end
        end
        varargin(1:2) = [];
      else
        msg = sprintf( ['Expected input #3 to be a ''function_handle''' ...
          , ' instead was a ''%s'''], class(varargin{2}) );
        assert( nargin > 3, 'Incorrect number of inputs.' );
        assert( isa(varargin{3}, 'function_handle'), msg );
        parlabs = Labels.ensure_cell( varargin{2} );
        Assertions.assert__is_cellstr( parlabs );
        assert( numel(unique(parlabs)) == numel(parlabs), dup_msg, 'parallel' );
        assert( isempty(setdiff(parlabs, within)), ['If specifying fields' ...
          , ' from which to create separate distributions, those fields' ...
          , ' must be contained in `within`.'] );
        func = varargin{3};
        first = parlabs;
        rest = setdiff( within, parlabs );
        varargin(1:3) = [];
      end
      %   call non-parellelized function if not parpool exists.
      if ( isempty(p) )
        warning( 'No parallel pool exists. Using non-parallelized function.' );
        out = for_each( obj, within, func, varargin{:} );
        return;
      end
      C = pcombs( obj, first );
      NC = size( C, 1 );
      if ( psize > NC )
        N = NC;
      else
        N = psize;
      end
      if ( NC > N )
        cmbs = cell( 1, N );
        n_per = floor( NC / N );
        stp = 1;
        i = 1;
        should_continue = true;
        while ( should_continue )
          cmbs{i} = C(stp:stp+n_per-1, :);
          i = i + 1;
          stp = stp + n_per;
          should_continue = (stp+n_per-1) < NC && i < N;
        end
        cmbs{end} = C(stp:end, :);
      else
        cmbs = cell( 1, N );
        for i = 1:size(C, 1)
          cmbs{i} = C(i, :);
        end
      end
      spmd (N)
        C_ = cmbs{labindex};
        subset_out = Container();
        for i = 1:size(C_, 1)
          subset = obj;
          row = C_(i, :);
          subset = only( subset, row );
          subset = for_each( subset, rest, func, varargin{:} );
          subset_out = append( subset_out, subset );
        end
      end
      out = extend( subset_out{:} );
    end
    
    function out = for_each(obj, varargin)
      
      %   FOR_EACH -- Apply a function to the data associated with each
      %     unique combination of labels in the specified fields.
      %
      %     out = for_each( obj, {'doses', 'images'}, @mean );
      %     calculates a mean for each unique (dose x image) pair of labels
      %     in 'doses' and 'images'.
      %
      %     out = for_each( obj, 'doses', @percentages, 'images' );
      %     calculates the percentage of trials associated with each image
      %     label in 'images', separately for each dose in 'doses'.
      %
      %     See also Container/pcombs
      %
      %     IN:
      %       - `varargin` (cell array)
      %     OUT:
      %       - `out` (Container) -- Container object
      
      if ( isa(varargin{1}, 'cell') || isa(varargin{1}, 'char') )
        narginchk( 3, Inf );
        %   first iteration.
        within = SparseLabels.ensure_cell( varargin{1} );
        func = varargin{2};
        out = Container();
        varargin(1:2) = [];
        Assertions.assert__isa( func, 'function_handle' );
      else
        out = varargin{1};
        within = varargin{2};
        func = varargin{3};
        varargin(1:3) = [];
      end   
      if ( isempty(within) )
        %   we're at the most specific level, so call the function.
        next = func( obj, varargin{:} );
        assert( isa(next, 'Container'), ['The returned value of a function' ...
          , ' called with for_each() must be a Container; was a ''%s''.'] ...
          , class(next) );
        out = append( out, next );
        return;
      end      
      objs = enumerate( obj, within(1) );
      within(1) = [];
      for i = 1:numel(objs)
        out = for_each( objs{i}, out, within, func, varargin{:} );
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
      %     See also Container/row_op, Container/n_dimension_op
      
      if ( nargin < 2 ), dim = 1; end
      if ( isequal(dim, 1) )
        obj = row_op( obj, @mean, 1 );
      else obj = n_dimension_op( obj, @mean, dim );
      end
    end
    
    function obj = nanmean(obj, dim)
      
      %   MEAN -- Return an object whose data have been averaged across a
      %     given dimension, excluding NaN values.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- Dimension specifier. Defaults
      %         to 1.
      %
      %     See also Container/row_op, Container/n_dimension_op
      
      if ( nargin < 2 ), dim = 1; end
      if ( isequal(dim, 1) )
        obj = row_op( obj, @nanmean, 1 );
      else obj = n_dimension_op( obj, @nanmean, dim );
      end      
    end
    
    function obj = median(obj, dim)
      
      %   MEDIAN -- Return an object whose data are a median across a given
      %     dimension.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- Dimension specifier. Defaults
      %         to 1.
      %
      %     See also Container/row_op, Container/n_dimension_op
      
      if ( nargin < 2 ), dim = 1; end
      if ( isequal(dim, 1) )
        obj = row_op( obj, @median, 1 );
      else obj = n_dimension_op( obj, @median, dim );
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
      %     See also Container/row_op, Container/n_dimension_op
      
      if ( nargin < 2 ), dim = 1; end
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
      %     See also Container/row_op, Container/n_dimension_op
      
      if ( nargin < 2 ), dim = 1; end
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
      %     See also Container/row_op, Container/n_dimension_op
      
      if ( nargin < 2 ), dim = 1; end
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
      %     See also Container/row_op, Container/n_dimension_op
      
      if ( nargin < 2 ), dim = 1; end
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
      %     See also Container/row_op, Container/n_dimension_op
      
      if ( nargin < 2 ), dim = 1; end
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
      if ( nargin < 2 ), rows = shape(obj, 1); end
      if ( nargin < 3 )
        comp = Container();
        comp = preallocate( comp, cell(rows, 1), nfields(obj.labels) );
      end
      if ( isempty(obj) ), comp = cleanup( comp ); return; end
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
      
      if ( nargin < 2 ), rows = shape(obj, 1); end
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
    
    function new_obj = subsample(obj, fields, n, can_replace)
      
      %   SUBSAMPLE -- Select, at random, a subset of label combinations,
      %     with or without replacement.
      %
      %     newobj = subsample( obj, 'date', 10 ); returns a new object
      %     containing data associated with 10 'date's, selected at random,
      %     without replacement. In this case, there must be at least 10
      %     'date' labels in the object.
      %
      %     newobj = subsample( obj, 'date', 10, true ) works as above, but
      %     allows replacement. In this case, there can be fewer than 10
      %     'date' labels in the object.
      %
      %     newobj = subsample( obj, {'date', 'city'}, 10 ) works as above,
      %     but selects 10 'date' x 'city' pairs.
      
      if ( nargin < 4 ), can_replace = false; end
      assert( isscalar(n), 'Specify the number of samples as a scalar number.' );
      C = pcombs( obj, fields );
      NC = size( C, 1 );
      if ( ~can_replace )
        assert( NC >= n, ['If subsampling without replacement,' ...
          , ' the maximum number of samples for this set of label' ...
          , ' combinations is %d; %d were requested.'], NC, n );
        ind = randperm( NC, n );
      else
        ind = datasample( 1:NC, n, 'Replace', true );
      end
      sub_combs = C( ind, : );
      ind = logic( obj, false );
      for i = 1:size(sub_combs, 1)
        ind = ind | where( obj, sub_combs(i, :) );
      end
      new_obj = keep( obj, ind );
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
        MATCHING
    %}
    
    function obj = require(obj, labs)
      
      %   REQUIRE -- Require labels to be present in the object.
      %
      %     If the labels are not found, the object is made to be empty.
      %
      %     This function is primarily designed to be used with the
      %     `for_each` function.
      %
      %     obj = obj.for_each( 'days', @require, obj('outcomes') );
      %     removes days in the object for which not all 'outcomes' are
      %     present.
      %
      %     See also Container/combs Container/for_each
      %
      %     IN:
      %       - `labs` (cell array of strings) -- Label combinations.
      %         Expected to be an MxN array as obtained from `combs`.
      %     OUT:
      %       - `obj` (Container) -- Empty Container object if not all
      %         `labs` are present in the object, else the original object.
      
      labs = Labels.ensure_cell( labs );
      Assertions.assert__is_cellstr( labs );
      for i = 1:size(labs, 1)
        if ( ~any(where(obj, labs(i, :))) )
          obj = keep_one( obj );
          obj = keep( obj, false );
          return;
        end
      end
    end
    
    %{
        DESCRIPTIVES
    %}
    
    function obj = describe(obj, dim, funcs)
      
      %   DESCRIBE -- Return descriptive stats within the given
      %     specificity.
      %
      %     obj = describe( obj ) returns the mean, standard-deviation,
      %     median, min, and max of the data in the object, across the 1st
      %     dimension (rows). The resulting `obj` has a new field
      %     'measures' identifying each descriptive statistic.
      %     Consequently, the incoming object must not have a 'measures'
      %     field.
      %
      %     obj = describe( ..., dim ) calculates the descriptive stats
      %     across `dim`, instead of 1 (rows).
      %
      %     obj = describe( ..., funcs ) uses the functions in `funcs`,
      %     instead of @mean, @std, @median, @min, and @max.
      %
      %     IN:
      %       - `dim` (double) -- Dimension specifier. Defaults to 1.
      %       - `funcs` (cell array of function_handle) -- Functions to use
      %         to calculate the descriptives.
      
      if ( nargin < 3 )
        funcs = { @mean, @median, @std, @min, @max };
      end
      if ( nargin < 2 )
        dim = 1; 
      end
      fs = field_names( obj );    
      assert( ~any(strcmp(fs, 'measures')), ['The object cannot have' ...
        , ' a ''measures'' field.'] );
      objs = cellfun( @(x) x(obj, dim), funcs, 'un', false );
      objs = cellfun( @(x) add_field(x, 'measures'), objs, 'un', false );
      for i = 1:numel(funcs)
        func_name = func2str( funcs{i} );
        objs{i}.labels = set_field( objs{i}.labels, 'measures', func_name );
      end
      obj = extend( objs{:} );
    end
    
    function obj = counts(obj, varargin)
      
      %   COUNTS -- Obtain the number of observations in the given fields.
      %
      %     C = counts( obj, 'days' ) returns an object whose data are the
      %     number of each label in the field 'days'.
      %
      %     C = counts( obj, 'days', days ) returns an object whose data
      %     are the number of each element of `days`. `days` is an Mx1 cell
      %     array of strings (such as that returned by `combs()` or
      %     `pcombs()`). Use this syntax when you wish to count `days` that
      %     might not be present in the object, in which case those `days`
      %     will have a count of 0.
      %
      %     C = counts( obj, {'days', 'blocks'}, c ) returns an object
      %     whose data are the number of rows associated with each 'days' x
      %     'blocks' combination in `c`. `c`, in this case, is an Mx2 cell
      %     array of strings.
      %
      %     See also Container/proportions, Container/for_each
      %
      %     IN:
      %       - `varargin` (cell array of strings, char) -- Fields from
      %         which labels are to be drawn, and optionally the labels to
      %         query.
      %     OUT:
      %       - `obj` (Container) -- Object whose data are an Mx1 column
      %         vector of integers, with each M(i) corresponding to a
      %         unique set of labels in `fields`.
      
      if ( nargin == 3 )
        obj = counts_of( obj, varargin{:} );
        return;
      end
      narginchk( 2, 2 );
      fields = varargin{1};
      obj.data = ones( shape(obj, 1), 1 );
      obj.dtype = class( obj.data );
      obj = for_each( obj, fields, @sum );
    end
    
    function new_obj = counts_of(obj, fields, labs)
      
      %   COUNTS_OF -- Obtain the number of rows associated with the given
      %     labels in the given fields.
      %
      %     `counts_of()` ensures that each set of labels associated with 
      %     each row of `labs` is represented in the output. I.e., if a 
      %     row of `labs` does not exist, the `counts_of` associated with 
      %     that row will be 0.
      %
      %     The given `fields` must be present in the object.
      %
      %     See also Container/counts
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- Fields
      %         identifying columns of `labs`.
      %       - `labs` (cell array of strings) -- MxN matrix of label
      %         combinations (as obtained by `combs()`). N must equal the
      %         number of `fields`.
      %     OUT:
      %       - `new_obj` (Container) -- Container object whose data are an
      %         Mx1 column vector identifying the number of elements
      %         associated with each row of `labs`.
      
      fields = Labels.ensure_cell( fields );
      Assertions.assert__is_cellstr( labs );
      Assertions.assert__is_cellstr( fields );
      assert__contains_fields( obj.labels, fields );
      assert( numel(fields) == size(labs, 2), ['The number of fields' ...
        , ' must match the number of columns of labels. Expected labels' ...
        , ' to have %d columns; %d were present.'], numel(fields) ...
        , size(labs, 2) );
      new_obj = Container();
      obj.data = ones( shape(obj, 1), 1 );
      collapsed = collapse_non_uniform( obj );
      for i = 1:size(labs, 1)
        ind = where( obj, labs(i, :) );
        collapsed = keep_one( collapsed, 1 );
        for j = 1:numel(fields)
          collapsed.labels = set_field( collapsed.labels, fields{j} ...
            , labs{i, j} );
        end
        collapsed.data = full( sum(ind) );
        new_obj = append( new_obj, collapsed );
      end
    end
    
    function obj = proportions(obj, varargin)
      
      %   PROPORTIONS -- Obtain the proportion of rows associated with a
      %     set of labels.
      %
      %     proportions( obj, {'field1', 'field2'} ); returns a proportion
      %     for each unique combination of labels in fields 'field1' and
      %     'field2'.
      %
      %     proportions( obj, fields, C ); returns a
      %     proportion for each row of labels in `C`. The number of
      %     `fields` must match the number of columns in `C`.
      %
      %     See also Container/counts
      %
      %     IN:
      %       - `varargin` (cell array)
      %
      %     OUT:
      %       - `obj` (Container) -- Object whose data are an Mx1 column
      %         vector of double, with each M(i) corresponding to a
      %         unique set of labels in `fields`.
      
      N = shape( obj, 1 );
      obj = counts( obj, varargin{:} );
      obj.data = obj.data / N;
    end
    
    function obj = percentages(obj, varargin)
      
      %   PROPORTIONS -- Obtain the percentage of rows associated with a
      %     set of labels.
      %
      %     See also Container/proportions
      %
      %     IN:
      %       - `varargin` (cell array)
      %
      %     OUT:
      %       - `obj` (Container) -- Object whose data are an Mx1 column
      %         vector of double, with each M(i) corresponding to a
      %         unique set of labels in `fields`.
      
      obj = proportions( obj, varargin{:} );
      obj.data = obj.data * 100;
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
    
    function pair = field_label_pairs(obj)
      
      %   FIELD_LABEL_PAIRS -- Return an array of 'field', {'label'} pairs.
      %
      %     pairs = field_label_pairs( obj ); returns a 1xN cell array
      %     where N is the number of label fields times 2. pairs{1} is a
      %     field name, and pairs{2} is the full-field of labels in that
      %     field.
      %
      %     Ex. //
      %
      %     a = Container( zeros(100, 1), 'months', 'May' );
      %
      %     b = one( a );
      %
      %     pair = field_label_pairs( b );
      %
      %     c = Container( zeros(2, 1), pair{:} );
      %
      %     See also Container/create
      %
      %     OUT:
      %       - `pair` (cell array)
      
      s = struct( obj );
      labs = s.labels;
      fs = fieldnames( labs );
      pair = cell( 1, numel(fs) * 2 );
      stp = 1;
      for i = 1:2:numel(fs)*2
        field = fs{stp};
        pair{i} = field;
        pair{i+1} = labs.(field);
        stp = stp + 1;
      end
    end
    
    function disp(obj)
      
      %   DISP -- Print the size of the data in the object, the class of
      %     data in the object, and the object's labels.
      
      n_dims = ndims( obj.data );
      size_str = num2str( size(obj.data, 1) );
      for i = 2:n_dims
        size_str = sprintf( '%s-by-%d', size_str, size(obj.data, i) );
      end
      fprintf('  %s %s %s with %s:\n', ...
        size_str, obj.dtype, class(obj), class(obj.labels) );
      disp( obj.labels );
    end
    
    function obj = columnize(obj)
      
      %   COLUMNIZE -- Ensure labels and categories are stored row-wise
      %     in SparseLabels
      
      if ( ~obj.LABELS_ARE_SPARSE ), return; end
      obj.labels = columnize( obj.labels );      
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
      
      objs = { obj, obj.labels };
      obj_kinds = cellfun( @(x) class(x), objs, 'un', false );
      ref_kinds = { 'methods', 'properties' };
      
      all_matches = {};
      
      for i = 1:numel(obj_kinds)
        obj_kind = obj_kinds{i};
        current_obj = objs{i};
        for j = 1:numel(ref_kinds)
          ref_kind = ref_kinds{j};
          if ( isequal(ref_kind, 'properties') )
            func = @properties; reformatted_format = '%s.%s';
          else func = @methods; reformatted_format = '%s/%s()';
          end
          matches = Container.matches_substring( str, func(current_obj), 2, 4 );
          if ( isempty(matches) ), continue; end
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
      
      if ( islogical(ind) ), logic = ind; return; end
      logic = false( shape(obj, 1), 1 );
      if ( isempty(ind) ), return; end
      assert( isvector(ind), 'The array cannot be a matrix' );
      assert( all(ind > 0), 'The index to-be-converted cannot contain 0s' );
      assert( max(ind) <= shape(obj, 1), 'Requested index is out of bounds' );
      assert( all( sign(diff(ind)) == 1 ), 'The index must be continuously increasing' );
      logic(ind) = true;
    end
    
    function tfs = logic(obj, tf)
      
      %   LOGIC -- Return a logical column-vector with the same number of
      %     rows as the object.
      %
      %     IN:
      %       - `tf` (true, false)
      %     OUT:
      %       - `tfs` (logical)
      
      Assertions.assert__isa( tf, 'logical' );
      if ( tf )
        tfs = true( shape(obj, 1), 1 );
      else
        tfs = false( shape(obj, 1), 1 );
      end
    end
    
    %{
        PLOTTING
    %}
    
    function [h, pl] = plot_(obj, func, varargin)
      
      %   PLOT_ -- Generalized call to ContainerPlotter plotting function.
      %
      %     IN:
      %       - `func` (function_handle) -- ContainerPlotter plotting
      %         function.
      %       - `varargin` (cell array)
      %     OUT:
      %       - `h` (axis handle)
      %       - `pl` (ContainerPlotter) -- Plotting object used to
      %         construct `h`.
      
      assert__container_plotter_present( obj );
      narginchk( 3, Inf );
      if ( isa(varargin{1}, 'ContainerPlotter') )
        pl = varargin{1};
        varargin(1) = [];
      else
        pl = ContainerPlotter();
      end
      h = func( pl, obj, varargin{:} );
    end
    
    function [h, pl] = bar(obj, varargin)
      
      %   BAR -- Construct a bar plot from the data in the object.
      %
      %     bar( obj, 'outcomes' ) creates a bar plot with bars for each
      %     label in 'outcomes'.
      %
      %     bar( obj, 'outcomes', 'doses' ) creates a grouped bar plot
      %     whose x-axis is 'outcomes', grouped-by 'doses'.
      %
      %     bar( obj, 'outcomes', 'doses', 'images' ) creates a separate
      %     grouped bar plot for each 'images'.
      %
      %     bar( obj, pl, ... ) uses the ContainerPlotter object `pl` to
      %     construct the bar plot, instead of a new (default)
      %     ContainerPlotter object.
      %
      %     h = bar( obj, ... ) returns an array of axis handles for each
      %     created subplot.
      %
      %     [h, pl] = bar( obj, ... ) also returns the ContainerPlotter
      %     object used to construct `h`.
      %
      %     See also ContainerPlotter/bar
      %
      %     IN:
      %       - `varargin` (cell array)
      %     OUT:
      %       - `h` (axis handles array) -- Array of axes handles for each
      %         subplot
      %       - `pl` (ContainerPlotter)
      
      [h, pl] = plot_( obj, @bar, varargin{:} );
    end
    
    function [h, pl] = plot(obj, varargin)
      
      %   PLOT -- Plot data in the object as lines or single points.
      %
      %     plot( obj, 'outcomes' ) creates a plot whose data-series are
      %     drawn from the unique labels in 'outcomes'. If data in the
      %     object are a matrix or row-vector, each data-series will be
      %     rendered as a line. If data are instead a column-vector or
      %     scalar, each data-series will be a single point.
      %
      %     plot( obj, 'outcomes', 'doses' ) creates a separate line- or
      %     point-plot for each 'doses'.
      %
      %     plot( obj, pl, ... ) uses the ContainerPlotter object `pl` to
      %     construct the plot, instead of a new (default) ContainerPlotter
      %     object.
      %
      %     h = plot( obj, ... ) returns an array of axis handles for each
      %     created subplot.
      %
      %     [h, pl] = plot( obj, ... ) also returns the ContainerPlotter
      %     object used to construct `h`.
      %
      %     See also ContainerPlotter/plot
      %
      %     IN:
      %       - `varargin` (cell array)
      %     OUT:
      %       - `h` (axis handles array) -- Array of axes handles for each
      %         subplot
      %       - `pl` (ContainerPlotter)
      
      [h, pl] = plot_( obj, @plot, varargin{:} );
    end
    
    function [h, pl] = plot_by(obj, varargin)
      
      %   PLOT_BY -- Plot data in the object with error bars.
      %
      %     plot_by( obj, 'outcomes' ) creates an error-bar line plot 
      %     whose x-axis is formed by the unique labels in 'outcomes'.
      %
      %     plot_by( obj, 'outcomes', 'doses' ) creates lines for each
      %     'doses'.
      %
      %     plot_by( obj, 'outcomes', 'doses', 'images' ) creates a
      %     separate plot for each 'images'.
      %
      %     plot_by( obj, pl, ... ) uses the ContainerPlotter object `pl`
      %     to construct the bar plot, instead of a new (default)
      %     ContainerPlotter object.
      %
      %     h = plot_by( obj, ... ) returns an array of axis handles for
      %     each created subplot.
      %
      %     [h, pl] = plot_by( obj, ... ) also returns the ContainerPlotter
      %     object used to construct `h`.
      %
      %     See also ContainerPlotter/plot_by
      %
      %     IN:
      %       - `varargin` (cell array)
      %     OUT:
      %       - `h` (axis handles array) -- Array of axes handles for each
      %         subplot
      %       - `pl` (ContainerPlotter)
      
      [h, pl] = plot_( obj, @plot_by, varargin{:} );
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
    
    function tbl = to_table(obj, varargin)
      
      %   TO_TABLE -- Convert the current Container object into a table.
      %
      %     You can specify which fields should form the rows and / or
      %     columns of the table, or attempt to have them selected
      %     automatically.
      %
      %     If no row or column fields are specified, rows and columns will
      %     be assigned automatically from the subset of fields in the
      %     object that are non-uniform. If there are no non-uniform
      %     fields, rows will be the first field (alphabetically) in the
      %     object, and the column will be a dummy field. If there is 
      %     only one field in the object, the row will be that field,
      %     and the column a dummy field.
      %
      %     However, if the optional flag '-distribute' or '-dist' is
      %     passed, rows and columns will be determined from the subset of
      %     fields in the first input.
      %
      %     If row OR column fields are specified, but not both, the
      %     unspecified dimension will be a non-uniform field that is not
      %     contained in the specified dimension. If all non-uniform fields
      %     are present in the specified dimension, or if there is only one
      %     field in the object, the unspecified dimension will be a dummy
      %     field.
      %
      %     Note that calling to_table() without specifiers can 
      %     result in out-of-memory errors if the number of non-uniform
      %     fields is very high.
      %
      %     Also note that Matlab requires column headers to be valid
      %     variable names. Thus, if manually or automatically
      %     specified column fields contain labels that are not valid
      %     Matlab variable names, an error will be thrown.
      %
      %     EX. //
      %
      %     tbl = table( obj ) creates a table with rows and columns
      %     drawn from the non-uniform fields of obj.
      %
      %     tbl = table( obj, 'doses', 'images' ) creates a table with rows
      %     as 'doses' and columns as 'images'.
      %
      %     tbl = table( obj, 'doses' ) creates a table with rows as
      %     'doses', and columns as either a) the non-uniform fields of
      %     obj OR b) a new, dummy field, if 'doses' is the only uniform
      %     field (or only field) in obj.
      %
      %     tbl = table( obj, [], 'doses' ) creates a table as above,
      %     except with *columns* as 'doses', and rows as either a) or b).
      %
      %     tbl = table( obj, {'doses', 'images', 'subjects'} )
      %     creates a table whose rows and columns are automatically
      %     selected from 'doses', 'images', and 'subjects'. The field with
      %     the fewest number of unique labels forms the columns, and rows
      %     are the remaining fields. If only one field is given, a dummy
      %     field is added. If no fields are given, table() is called with
      %     the original object as input, and no additional inputs, as
      %     above.
      %
      %     IN:
      %       - `varargin` (cell array of strings, char, []) -- Optionally
      %         specify row-fields, column-fields, or a '-distribute' flag.
      %         See above for examples.
      %     OUT:
      %       - `tbl` (table) -- table whose items are cell arrays.
      
      assert( ~isempty(obj), 'The object is empty.' );
      flag_exists = strcmp(varargin, '-distribute') | strcmp(varargin, '-dist');
      if ( any(flag_exists) )
        assert( nargin == 3, ['If passing the ''-distribute'' flag,' ...
          , ' there must be one (and only one) array of fields.'] );
        to_rm = setdiff( field_names(obj), varargin{1} );
        obj2 = obj;
        if ( ~isempty(to_rm) )
          obj2 = rm_fields( obj2, to_rm );
          if ( nfields(obj2) == 0 ), obj2 = obj; end
        end
        tbl = to_table( obj2 );
        return;
      end
      if ( nargin < 2 )
        cols_are = [];
        rows_are = [];
      elseif ( nargin < 3 )
        rows_are = Labels.ensure_cell( varargin{1} );
        if ( numel(rows_are) > 0 )
          tbl = to_table( obj, rows_are, '-dist' );
          return;
        end
        cols_are = [];
      else
        narginchk( 3, 3 );
        rows_are = varargin{1};
        cols_are = varargin{2};
      end
      
      cols_empty = isempty( cols_are );
      rows_empty = isempty( rows_are );
      both_empty = cols_empty & rows_empty;
      one_empty = xor( cols_empty, rows_empty );
            
      if ( one_empty || both_empty )
        auto_set = get_non_uniform_categories( obj.labels );
        all_fields = field_names( obj );
        if ( isempty(auto_set) ), auto_set = all_fields(1); end
      end
      if ( one_empty )
        %   If rows are specified OR columns are specified, but not both,
        %   the non-specified dimension is the fields of `auto_set` that
        %   are not present in the specified dimension. If all values of
        %   `auto_set` are contained in the specified dimension, the
        %   unspecified dimension will be a dummy field.
        need_dummy_field = false;
        if ( cols_empty )
          manual_set = rows_are;
        else
          manual_set = cols_are;
        end
        if ( numel(all_fields) > 1 )
          auto_set = setdiff( auto_set, manual_set );
          if ( isempty(auto_set) ), need_dummy_field = true; end
        else
          need_dummy_field = true;
        end
        if ( need_dummy_field )
          auto_set = get_dummy_field( obj );
          obj = add_field( obj, auto_set, auto_set );
        end
        if ( cols_empty )
          cols_are = auto_set;
        else
          rows_are = auto_set;
        end
      end
      if ( both_empty )
        %   If no row or column fields are specified, rows are initially
        %   `auto_set`. If there is only one field in the object, a new
        %   dummy field is created to serve as the column. Otherwise, the
        %   field with the fewest unique labels is selected to be 
        %   `cols_are`, and the remaining fields are `rows_are`.
        rows_are = Labels.ensure_cell( auto_set );
        if ( numel(rows_are) > 1 )
          to_col = smallest_field_index( obj, rows_are );
          cols_are = rows_are( to_col );
          rows_are( to_col ) = [];
        else
          cols_are = get_dummy_field( obj );
          obj = add_field( obj, cols_are, cols_are );
        end
      end
      try 
        [~, row_labs] = get_indices( obj, rows_are );
        [~, col_labs] = get_indices( obj, cols_are );
      catch err
        if ( ~isempty(strfind(err.identifier, 'SizeLimitExceeded')) )
          msg = ['There are too many unique labels to sort through' ...
            , ' automatically. Add specifiers to manually set row and' ...
            , ' column identities.'];
        else
          msg = sprintf( ['\nThe following error occurred when' ...
            , ' attempting to generate a table:\n\n%s'] ...
            , err.message );
        end
        error( msg );
      end
      n_rows = size( row_labs, 1 );
      n_cols = size( col_labs, 1 );
      cols = cell( 1, n_cols );
      cols = cellfun( @(x) cell(n_rows, 1), cols, 'un', false );
      for i = 1:n_rows
        for j = 1:n_cols
          extr = only( obj, [row_labs(i, :), col_labs(j, :)] );
          if ( isempty(extr) ), continue; end
          cols{j}{i} = extr.data;
        end
      end
      try
        col_names = matlab.lang.makeValidName( str_joiner(col_labs, '_') );
        tbl = table( cols{:}, 'VariableNames', col_names );
      catch err
        if ( ~isempty(strfind(err.identifier, 'InvalidVariableName')) )
          msg = [ 'Each column label in a table must be a valid Matlab' ...
            , ' variable name. Some labels in the fields specified for' ...
            , ' columns (either automatically or manually) are not valid' ...
            , ' variable names. Place these fields in rows, or omit them.' ];
        else
          msg = sprintf( ['\nThe following error occurred when' ...
            , ' attempting to generate a table:\n\n%s'] ...
            , err.message );
        end
        error( msg );
      end
      tbl.Properties.RowNames = str_joiner( row_labs );
      function str = str_joiner( arr, delimiter )
        %   STR_JOINER -- Join a cell array of cell arrays of strings such
        %     that each row of `str` is a char
        if ( size(arr, 2) == 1 ), str = arr; return; end
        if ( nargin < 2 ), delimiter = ' | '; end
        str = cell( size(arr, 1), 1 );
        for ii = 1:size( arr, 1 )
          str{ii} = strjoin( arr(ii, :), delimiter );
        end
      end
      function dummy_field = get_dummy_field( obj )
        %   DUMMY_FIELD -- Get a dummy field name that is not already
        %     contained in the object.
        stp = 1;
        do_continue = true;
        while ( do_continue )
          dummy_field = sprintf( 'Var%d', stp );
          do_continue = contains_fields(obj.labels, dummy_field) || ...
            contains(obj.labels, dummy_field);
          stp = stp + 1;
        end
      end
      function fewest = smallest_field_index( obj, rows_are )
        %   SMALLEST_FIELD_INDEX -- Get an index of the fieldname in
        %     `rows_are` with the fewest number of unique labels.
        ns = cellfun( @(x) numel(unique(get_fields(obj.labels, x))) ...
          , rows_are );
        [~, fewest] = min( ns );
      end
    end
    
    function tbl = table(obj, varargin)
      
      %   TABLE -- Alias for `to_table`.
      %
      %     See `help Container/to_table` for more info.
      
      try
        tbl = to_table( obj, varargin{:} );
      catch err
        throwAsCaller( err );
      end
    end
    
    function out = array(obj)
      
      %   ARRAY -- Convert the object to a cell array whose data are the
      %     first column, and labels the remaining columns.
      %
      %     OUT:
      %       - `out` (cell array)
      
      if ( obj.LABELS_ARE_SPARSE ), obj = full( obj ); end
      dat = cell( shape(obj, 1), 1 );
      for i = 1:numel(dat)
        dat{i} = obj.data(i, :);
      end
      header = [ {'data'}, obj.labels.fields ];
      out = [ dat, obj.labels.labels ];
      out = [ header; out ];
    end
    
    function [structs, c] = to_subsets(obj, fields)
      
      %   TO_SUBSETS -- Convert an object to an array of struct, whose
      %     values are identified by the unique labels in `fields`.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- Fields from which
      %         to draw labels. Can be thought of as the specificity of
      %         each subset.
      %     OUT:
      %       - `structs` (cell array of struct)
      %       - `c` (cell array of strings) -- MxN cell array of strings
      %       	where each `c(i, :)` corresponds to each `structs`(i), and
      %       	each `c(:, j)` corresponds to each `fields`(j).
      
      [objs, ~, c] = enumerate( obj, fields );
      structs = cellfun( @(x) struct(x), objs, 'un', false );
    end
    
    function [structs, c] = subsets(obj, fields)
      
      %   SUBSETS -- Alias for `to_subsets()`.
      %
      %     See `help Container/to_subsets` for more info.
      
      [structs, c] = to_subsets( obj, fields );
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
        error( 'It is an error to directly set the ''%s'' property.', prop );
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
      
      if ( isempty(with) ), return; end
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
      
      if ( ~obj.IS_PREALLOCATING ), return; end
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
      assert( shapes_match(obj, B), 'The shapes of the objects do not match.' );
    end
    
    function assert__columns_match(obj, B)
      Assertions.assert__isa( B, 'Container' );
      assert( shape(obj, 2) == shape(B, 2), ...
        'The objects are not equal in the second (column) dimension.' );
    end
    
    function assert__dtypes_match(obj, B)
      Assertions.assert__isa( B, 'Container' );
      assert( isequal(obj.dtype, B.dtype), 'The dtypes of the objects do not match.' );
    end
    
    function assert__capable_of_operations(obj, B, op_kind)
      assert__shapes_match(obj, B);
      assert__dtypes_match(obj, B);
      assert( eq_non_uniform(obj.labels, B.labels), ['In order to use' ...
        , ' ''%s'', the non-uniform fields of each labels object must' ...
        , ' match.'], op_kind );
%       assert( eq(obj.labels, B.labels), ...
%         ['In order to perform operations, the label objects between two Container' ...
%         , ' objects must match exactly'] );
      supports = obj.SUPPORTED_DTYPES.( op_kind );
      assert( any(strcmp(supports, obj.dtype)), ...
        'The ''%s'' operation is not supported with objects of type ''%s''.', ...
        op_kind, obj.dtype );      
    end
    
    function assert__dtype_is(obj, kind)
      assert( strcmp(obj.dtype, kind), ['Expected the object''s dtype to be ''%s''' ...
        , ' but was ''%s''.'], kind, obj.dtype );
    end
    
    function assert__container_plotter_present(obj)      
      str = which( 'ContainerPlotter' );
      assert( ~isempty(str), ['The required library ''ContainerPlotter.m''' ...
        , ' could not be located.'] );
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
            , ' See `help Labels` for more information.'] );
        end
      end
      %   make sure the dimensions are compatible
      assert( size(data, 1) == shape(labels, 1), ...
        'Data must have the same number of rows as labels.' );
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
    
    function obj = from(obj)
      
      %   FROM -- Alias for `create_from()`.
      %
      %     See also Container/create_from
      
      obj = Container.create_from( obj );
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
    
    function obj = create(varargin)
      
      %   CREATE -- Create a Container object from data and a variable
      %     number of ('field', {'labels}) pairs.
      %
      %     IN:
      %       - `varargin` (/any/)
      %     OUT:
      %       - `obj` (Container)
      %
      %     Ex. //
      %
      %     obj = Container.create( 10, 'cities', 'NY' );
      %     creates a 1x1 Container whose `data` are 10 and whose labels
      %     have a single field, 'cities', and a single label 'NY'.
      %
      %     obj = Container.create( [10; 11], 'cities', {'NY'; 'LA'} );
      %     creates a 2x1 Container whose `data` are [10; 11] and whose
      %     labels have a single field, 'cities'. The label 'NY' is
      %     associated with the first datapoint (10), while the label 'LA'
      %     identifies the second datapoint (11).
      
      narginchk( 3, Inf );
      
      data = varargin{1};
      labs = varargin(2:end);
      assert( mod(numel(labs)/2, 1) == 0 ...
        , '(field, {labels}) pairs are incomplete.' );
      fs = labs(1:2:end);
      cellfun( @(x) Assertions.assert__isa(x, 'char'), fs );
      labels = labs(2:2:end);
      labels = cellfun( @(x) Labels.ensure_cell(x), labels, 'un', false );
      cellfun( @(x) Assertions.assert__is_cellstr(x), labels );
      for i = 1:numel(labels)
        lab = labels{i};
        if ( size(data, 1) ~= numel(lab) )
          assert( numel(lab) == 1, ['The number of labels must' ...
            , ' match the number of rows in `data`, unless there is only' ...
            , ' one label.'] );
          labels{i} = repmat( lab, size(data, 1), 1 );
        end
      end
      labels = cellfun( @(x) x(:), labels, 'un', false );
      labels = cellfun( @(x) {x}, labels, 'un', false );
      struct_input = cell( size(labs) );
      struct_input(1:2:end) = fs;
      struct_input(2:2:end) = labels;
      try
        s = struct( struct_input{:} );
        obj = Container( data, s );
      catch err
        fprintf( ['\n The following error occurred when attempting to' ...
          , ' instantiate a Container'] );
        error( err.message );
      end
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
      if ( numel(str) < min_length ), return; end
      if ( numel(str) > max_length ), str = str(1:max_length); end
      too_big = cellfun( @(x) numel(x) < numel(str), comparitors );
      comparitors(too_big) = [];
      if ( isempty(comparitors) ), return; end
      does_match = cellfun( @(x) any(min(strfind(x, str)) == 1), comparitors );
      matches = comparitors( does_match );
      
    end
  end
  
end