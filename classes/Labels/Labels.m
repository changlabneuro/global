%   LABELS -- Create a searchable array of labels to identify rows of data.
%
%     // INSTANTIATION
%
%     IN:
%       - `s` (struct) |OPTIONAL| -- A struct whose N fields are M-by-1
%         cell arrays of strings (labels). I.e., each field in `s` must
%         have the same number of rows, and only one column. Additionally,
%         the same string cannot appear in multiple fields of `s`; that is, 
%         the unique values of each field cannot overlap in any way. If 
%         specified, the returned object will have a `labels` property that 
%         is an MxN cell array of strings, and a `fields` property that is
%         a 1-by-N cell array of strings derived from the fieldnames in
%         `s`. Each `field`(i) identifies the column of `labels`(:, i).
%
%         If unspecified, the returned object has `labels` and `field`
%         properties that are both empty 0x0 cell arrays. Note that the
%         object is not designed to be incrementally constructed in this
%         way; it's intended to facilitate preallocation *only*. 
%         See `help Labels/preallocate` for more information.
%
%     // EXAMPLE
%
%     s.rewards = { 'high'; 'low'; 'medium' };
%     s.trialtypes = { 'cued'; 'choice'; 'cued' };
%
%     labels = Labels(s);
%
%     disp( labels );
%
%     labels = 
%
%       * trialtypes
%           - choice (1)
%           - cued (2)
%       * rewards
%           - high (1)
%           - low (1)
%           - medium (1)
%
%     labels.where( {'cued'} )
%
%     -> [ 1; 0; 1 ];
%
%     labels.where( {'choice', 'low'} );
%
%     -> [ 0; 1; 0;];
%
%     // PROPERTIES
%
%       //  PUBLIC
%           
%           - `labels` (cell array of strings) -- An MxN cell array of
%             strings in which each column `n` denotes a `field`, or
%             category, of labels, and each row `m` a set of labels. It is
%             an error for the same label to appear in multiple columns of
%             `labels`.
%           - `fields` (cell array of string) -- Category names; names that
%             identify each column of `labels`.
%
%       //  PROTECTED
%
%           - `IGNORE_CHECKS` (logical) |SCALAR| -- Specifies whether to
%             more thoroughly check the validity of inputs to several
%             methods, in order to avoid cryptic error messages. Is used
%             internally to avoid such checks when there are many repeated
%             calls to a given method; in that case, the input is validated
%             before the repeated function call.
%           - `IS_PREALLOCATING` (logical) |SCALAR| -- Indicates whether
%             the object is or is not currently preallocating. Is set
%             `true` after a call to preallocate(), and `false` after a
%             call to `cleanup()`. See `help Labels/preallocate`, `help
%             Labels/populate`, `help Labels/cleanup` for more information.
%           - `BEEN_POPULATED` (logical) |SCALAR| -- `true` if a call to
%             preallocate() has been made followed by a valid call to
%             populate(); `false` otherwise.
%           - `PREALLOCATION_EXPRESSION` (char) -- Indicates the expression
%             each cell will be filled with in the preallocated cell array
%             after a call to preallocate(). See `help Labels/preallocate`
%             for more information.
%           - `PREALLOCATION_ROW` (number, NaN) -- Indicates the row of the
%             cell array of strings `obj.labels` at which a call to
%             to populate() will begin assigning values to the array. NaN
%             if the object is not currently preallocating.
%           - `PREALLOCATION_SIZE` (number, NaN) -- Indicates the number of
%             rows specified in the original call to preallocate(); NaN if
%             the object is not currently preallocating.
%           - `EMPTY_FIELDNAME` (char) -- Indicates how each empty field
%             will be identified after a call to preallocate().
%           - `COLLAPSED_EXPRESSION` (char) -- Indicates the string that
%             will be prepended to the `field` in a call to
%             collapse_fields(). See `help Labels/collapse_fields` for more
%             information.
%           - `VERBOSE` (logical) |SCALAR| -- Indicates whether methods
%             should display more or less verbose warning / status / debug
%             information.
%           - `MAX_DISPLAY_ITEMS` (number) -- Indicates the maximum number
%             of unique labels to display in a call to disp() when 
%             VERBOSE is `false`. 
%
%     // METHODS
%     
%     Type `help Labels/NAME` to get more information about the methods
%     listed here
%
%       //  NON-STATIC
%
%           - `Labels`
%           - `verbosity`
%           - `shape`
%           - `nfields`
%           - `uniques`
%           - `uniques_in_fields`
%           - `combs`
%           - `replace`
%           - `get_fields`
%           - `get_fields_except`
%           - `rename_field`
%           - `set_field`
%           - `rm_fields`
%           - `add_field`
%           - `collapse_fields`
%           - `collapse`
%           - `keep`
%           - `remove`
%           - `rm`
%           - `only`
%           - `contains`
%           - `find_fields`
%           - `where`
%           - `get_indices`
%           - `fields_match`
%           - `shape_match`
%           - `eq`
%           - `ne`
%           - `preallocate`
%           - `populate`
%           - `cleanup`
%           - `append`
%           - `disp`
%           - `create_index`
%           - `label_struct`
%           - `eq`
%           - `ne`
%           - `preallocate`
%           - `populate`
%           - `cleanup`
%           - `append`
%           - `disp`
%           - `create_index`
%           - `label_struct`
%           - `assert__contains_fields`
%           - `assert__does_not_contain_fields`
%           - `assert__fields_and_shapes_match`         
%           - `assert__fields_match`
%           - `assert__is_properly_dimensioned_logical`
%
%       //  STATIC
%
%           - `validate__initial_input`
%           - `ensure_cell`

classdef Labels
  
  properties (Access = public)
    fields = {};
    labels = {};
  end
  
  properties (Access = protected)
    IGNORE_CHECKS = false;
    IS_PREALLOCATING = false;
    BEEN_POPULATED = false;
    PREALLOCATION_EXPRESSION = '/*/';
    PREALLOCATION_ROW = NaN;
    PREALLOCATION_SIZE = NaN;
    EMPTY_FIELDNAME = 'EMPTY FIELD';
    COLLAPSED_EXPRESSION = 'all__';
    VERBOSE = false;
    MAX_DISPLAY_ITEMS = 10;
  end
  
  methods
    function obj = Labels(S)
      if ( nargin < 1 ), return; end;
      Labels.validate__initial_input( S );
      obj.fields = fieldnames( S )';
      labs = cellfun( @(x) {S.(x)}, obj.fields )';
      obj.labels = [ labs{:} ];
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
      if ( isequal(to, 'on') ), obj.VERBOSE = true; return; end
      if ( isequal(to, 'off') ), obj.VERBOSE = false; return; end
    end
    
    %{
        SIZE / SHAPE
    %}
    
    function s = shape(obj, dim)
      
      %   SHAPE -- get the size of the labels cell array.
      %
      %     IN:
      %       - `dim` |OPTIONAL| (double) -- dimension of the array of 
      %         labels to query. E.g., size(obj, 1).
      
      if ( nargin < 2 ), s = size( obj.labels ); return; end;
      s = size( obj.labels, dim );
    end
    
    function n = nfields(obj)
      
      %   NFIELDS -- get the current number of fields in the object
      
      n = numel( obj.fields );
    end
    
    function tf = isempty(obj)
      tf = isempty( obj.labels );
    end
    
    %{
        LABEL HANDLING
    %}
    
    function unqs = uniques(obj, labels)
      
      %   UNIQUES -- get the unique elements in each column of obj.labels.
      %     Alternatively, if labels are specified, get the unique elements
      %     of the specified labels.
      %
      %     IN:
      %       - `labels` (cell array of strings) |OPTIONAL| -- labels to 
      %         obtain uniques-of. Usually, this input will be left 
      %         unspecified, in which case the labels will be those in 
      %         `obj.labels`.
      %     OUT:
      %       - `unqs` (cell array of cell array of strings) -- cell array
      %         where each cell{i} contains the unique labels in each 
      %         column of `labels`. If `labels` is unspecified, each 
      %         column (i) of `unqs` corresponds to each field(i) in 
      %         `obj.fields`.
      
      if ( nargin < 2 ), labels = obj.labels; end;
      unqs = cell( 1, size(labels, 2) );
      for i = 1:numel(unqs)
        unqs{i} = unique( labels(:,i) );
      end
    end
    
    function unqs = uniques_in_fields(obj, fields)
      
      %   UNIQUES_IN_FIELDS -- get the unique elements in the desired
      %     fields. Note that fields can be repeated, and that each 
      %     column(i) of unqs will match fields(i).
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- desired fields.
      %     OUT:
      %       - `unqs` (cell array of cell arrays of strings) -- the unique
      %       each of the specified fields.
      
      labs = get_fields( obj, fields );
      unqs = uniques( obj, labs );
    end
    
    function unqs = flat_uniques(obj, fs)
      
      %   FLAT_UNIQUES -- Obtained a flattened cell array of the unique
      %     values in the given categories.
      %
      %     Rather than a 1xM array of unique values per M categories, the
      %     output is a 1xM array of all M unique values in the specified
      %     categories.
      %
      %     IN:
      %       - `cats` (cell array of strings, char) -- Categories from
      %         which to draw labels.
      %     OUT:
      %       - `unqs` (cell array of strings) -- Unique labels in a
      %         flattened cell array.
      
      if ( nargin < 2 ), fs = obj.fields; end;
      unqs = uniques_in_fields( obj, fs );
      unqs = cellfun( @(x) x(:)', unqs, 'un', false );
      assert( all(cellfun(@(x) isrow(x), unqs)), ['Not all unique values' ...
        , ' were a row vector. This is possibly due to manually overwriting' ...
        , ' the labels property of the object'] );
      unqs = [ unqs{:} ];
    end
    
    function c = combs(obj, fields)
      
      %   COMBS -- get the unique combinations of unique labels in the
      %     object. Specify `fields` as a second input in order to limit 
      %     the resulting combinations to those fields.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) |OPTIONAL| -- fields
      %         from which to draw unique elements. If unspecified, all 
      %         fields will be used.
      %
      %         NOTE: The order of elements of `fields` is not respected in 
      %         the output `c`. Instead, the columns of `c` are ordered 
      %         with respect to the index of the field in `obj.fields`.
      %     OUT:
      %       - `c` (cell array of strings) -- M*N cell array, where M is 
      %         the number of unique combinations, and N is the number of 
      %         fields in `fields` (or the number of fields in `obj.fields`, 
      %         if unspecified). Each cell contains a label, and each column
      %         contains the array of labels for a given field.
      
      unqs = uniques( obj );
      if ( nargin < 2 ), c = allcomb( unqs ); return; end;
      ind = unique( sort(find_fields(obj, fields)) );
      c = allcomb( unqs(:, ind) );
    end
    
    function obj = replace(obj, search_for, with)
      
      %   REPLACE -- replace a given number of labels with a single label.
      %
      %     All of the to-be-replaced labels must be in the same field; it 
      %     is an error to place the same label in multiple fields. If no
      %     elements are found, a warning is printed, and the original 
      %     object is returned.
      %
      %     IN:
      %       - `search_for` (cell array of strings, char) -- Labels to
      %         replace. If an element cannot be found, that element will 
      %         be ignored, and a warning will be printed.
      %     OUT:
      %       - `obj` (Labels) -- Object with its labels property updated
      %         to reflect the replacements
      
      search_for = Labels.ensure_cell( search_for );
      Assertions.assert__is_cellstr( search_for );
      Assertions.assert__isa( with, 'char' );
      cols = nan(1, numel(search_for) );
      labs = obj.labels;
      for i = 1:numel(search_for)
        [ind, field] = where( obj, search_for{i} );
        if ( isequal(field{1}, -1) )
          fprintf( '\n ! Labels/replace: Could not find ''%s''\n', search_for{i} );
          continue;
        end;
        cols(i) = find_fields( obj, field );
        if ( numel(unique(cols(~isnan(cols)))) > 1 )
          error( 'It is an error to replace an element in multiple fields' );
        end
        labs(ind, cols(i)) = { with };
        fprintf( '\n ! Labels/replace: Made %d replacements\n', sum(ind) );
      end
      if ( all(isnan(cols)) )
        fprintf( ['\n ! Labels/replace: Could not find any of the search' ...
          , ' terms; made 0 replacements\n\n'] );
        return;
      end
      obj.labels = labs;
    end
    
    %{
        FIELD HANDLING
    %}
    
    function uniform = get_uniform_fields(obj)
      
      %   GET_UNIFORM_FIELDS -- Return an array of field names for
      %     which there is only one unique label present in the field.
      %
      %     OUT:
      %       - `uniform` (cell array of strings) -- Category names.
      
      uniform_ind = false( 1, size(obj.labels, 2) );
      for i = 1:size(obj.labels, 2)
        uniform_ind(i) = numel( unique(obj.labels(:, i)) ) == 1;
      end
      uniform = obj.fields( uniform_ind );
    end
    
    function labs = get_fields(obj, fields)
      
      %   GET_FIELDS -- obtain labels in the fields `fields`. 
      %
      %     If any fields in `fields` are not in the object, an error is 
      %     thrown. Fields are allowed to be repeated.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- fields from which 
      %         to draw labels.
      %     OUT:
      %       - `labs` (cell array of strings) -- columns of `obj.labels` 
      %         that match the fields in `fields`.
      
      inds = find_fields( obj, fields );
      labs = obj.labels(:, inds);
    end
    
    function [labs, fields] = get_fields_except(obj, fields)
      
      %   GET_FIELDS_EXCEPT -- obtain the labels in all fields except those
      %     in `fields`. 
      %
      %     If any fields in `fields` are not in the object, an error is 
      %     thrown. If all fields in the object are specified, an error is 
      %     thrown. Note that the order of columns of the outputted labels 
      %     are not guarenteed to match those of the inputted fields;
      %     for this reason, you can specify a second output `fields` to
      %     properly identify columns of `labels`.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- fields to ignore. 
      %     OUT:
      %       - `labs` (cell array of strings) -- labels in the object that
      %         correspond to the non-desired fields.
      %       - `fields` (cell array of strings) -- fields that correspond 
      %         to the returned labels.
      
      desired = sort( setdiff( 1:numel(obj.fields), find_fields(obj, fields)) );
      assert( ~isempty(desired), ...
        'It is an error to specify all the fields in the object' );
      labs = obj.labels(:, desired );
      fields = obj.fields( desired );
    end
    
    function obj = rename_field(obj, field, name)
      
      %   RENAME_FIELD -- change the fieldname of `field` to `name`. 
      %
      %     If `field` does not exist in the object, an error is thrown. If
      %     `name` is already the name of a field in the object, an error 
      %     is thrown.
      %
      %     IN:
      %       - `field` (char) -- name of field to rename.
      %       - `name` (char) -- new name of the field.
      %     OUT:
      %       - `obj` (Labels) -- object with the renamed field.
      
      Assertions.assert__isa( field, 'char' );
      Assertions.assert__isa( name, 'char' );
      ind = find_fields( obj, field );
      assert( ~any(strcmp(obj.fields, name)), ...
        'The name ''%s'' is already a field in the object', name );
      obj.fields(ind) = { name };
    end
    
    function obj = set_field(obj, field, values, index)
      
      %   SET_FIELD -- set the contents of a given `field` at a given
      %     `index` to the desired `values`. 
      %
      %     If no index is specified, the entire field is attempted to be 
      %     replaced. If `values` is a cell array of strings, and `index` 
      %     is specified, the number of values must match the sum of the 
      %     index. Otherwise, if `index` is unspecified, the number of 
      %     values must match the number of rows in the Labels object. If 
      %     `values` is a char, the values will be repeated and placed at 
      %     each point in the index.
      %
      %     IN:
      %       - `field` (char) -- Field in which labels are to be set.
      %       - `values` (cell array, char) -- New labels to set. If 
      %         `values` is a cell array and `index` is unspecified, the 
      %         number of values must equal the current number of labels in 
      %         the field. If `values` is a cell array and `index` is 
      %         specified, the number of values must equal the number of 
      %         true elements in the index.
      %       - `index` (logical) |COLUMN| |OPTIONAL| -- index of which
      %         elements in the field are to be replaced / set.
      %     OUT:
      %       - `obj` (Labels) -- updated Labels object.
      
      if ( nargin < 4 ), index = true( shape(obj, 1), 1 ); end
      if ( ~obj.IGNORE_CHECKS )
        Assertions.assert__isa( field, 'char' );
        if ( isa(values, 'cell') )
          assert( numel(values) == sum(index) | numel(values) == 1, ...
            ['Attempting to assign too many or too few labels to the' ...
            , ' field ''%s'''], field );
        else values = { values };
        end
        Assertions.assert__is_cellstr( values );
        assert__is_properly_dimensioned_logical( obj, index );
        %   ensure none of the incoming values exist in another field of
        %   the object.
        [labels, other_fields] = get_fields_except( obj, field );
        unique_values = unique( values );
        for i = 1:numel(unique_values)
          [ind, check_field] = where( obj, unique_values{i}, labels, other_fields );
          assert( ~any(ind), ['Cannot assign ''%s'' to' ...
            , ' field ''%s'' because it already exists in field ''%s'''] ...
            , unique_values{i}, field, check_field{1} );
        end
      end
      ind = find_fields( obj, field );
      obj.labels( index, ind ) = values;
    end
    
    function obj = rm_fields(obj, fields)
      
      %   RM_FIELDS -- remove specified field(s) from the object.
      %
      %     An error is thrown if even one of the specified fields is not 
      %     found. It is ok to delete all fields from the object.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- field or fields 
      %         to remove from the object.
      %     OUT:
      %       - `obj` (Labels) -- object with the desired fields removed.
      
      inds = find_fields( obj, fields );
      obj.fields(inds) = [];
      obj.labels(:, inds) = [];
    end
    
    function obj = add_field(obj, field, set_as)
      
      %   ADD_FIELD -- Add a new field of labels to the object.
      %
      %     You cannot add multiple fields in one function call. You must
      %     also provide the labels to assign to the new field. If the
      %     given `field` already exists, an error is thrown. Note that you
      %     must assign a full field's worth of labels -- i.e., you cannot
      %     supply an index to assign only part of the new field.
      %
      %     IN:
      %       - `field` (char) -- New field name.
      %     OUT:
      %       - `set_as` (cell array of strings, char) -- Values to assign
      %         to the new field. See `help Labels/set_field` for more
      %         information on input restrictions (although note that the
      %         `index` input is not supported here).
      
      Assertions.assert__isa( field, 'char' );
      assert( ~isempty(obj), ['Cannot add fields to an empty object.' ...
        , ' See `help Labels/preallocate()` for information on how to assign' ...
        , ' values to an empty object.'] );
      opts.msg = '\nThe field ''%s'' already exists in the object';
      assert__does_not_contain_fields( obj, field, opts );
      obj.fields{end+1} = field;
      obj.labels(:, end+1) = { obj.EMPTY_FIELDNAME };
      ind = true( shape(obj,1), 1 );
      obj = set_field( obj, field, set_as, ind );      
    end
    
    function obj = collapse_fields(obj, fields)
      
      %   COLLAPSE_FIELDS -- Replace labels in a field or fields with a
      %     repeated, field-namespaced expression: 'all__`field`'.
      %
      %     An error is thrown if even one of the specified fields is not
      %     found.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- field or fields
      %         to collapse.
      %     OUT:
      %       - `obj` (Labels) -- object with the appropriate fields
      %         collapsed.
      
      fields = unique( Labels.ensure_cell(fields) );
      inds = find_fields( obj, fields );
      for i = 1:numel( fields )
        obj.labels(:, inds(i)) = { [obj.COLLAPSED_EXPRESSION fields{i}] };
      end
    end
    
    function obj = collapse(obj, fields)
      
      %   COLLAPSE -- Shorthand alias for `collapse_fields()`.
      %
      %     See `help Labels/collapse_fields` for more info.
      
      obj = collapse_fields( obj, fields );
    end
    
    function obj = collapse_non_uniform(obj)
      
      %   COLLAPSE_NON_UNIFORM -- Collapse fields for which there is
      %     more than one label present in the field.
      %
      %     See `help Labels/get_uniform_fields` for more info.
      
      uniform = get_uniform_fields( obj );
      non_uniform = setdiff( obj.fields, uniform );
      obj = collapse_fields( obj, non_uniform );
    end
    
    function obj = collapse_except(obj, fields)
      
      %   COLLAPSE_EXCEPT -- Collapse all fields except the given
      %     fields.
      %
      %     IN:
      %       - `cats` (Cell array of strings, char) -- field or
      %       fields to avoid collapsing.
      
      assert__contains_fields( obj, fields );
      fields = Labels.ensure_cell( fields );
      to_collapse = setdiff( obj.fields, fields );
      if ( isempty(to_collapse) ), return; end;
      obj = collapse( obj, to_collapse );
    end
    
    %{
        INDEXING
    %}    
    
    function obj = keep(obj, ind)
      
      %   KEEP -- given a logical column vector, return a `Labels` object
      %     where the rows of `obj.labels` correspond to the true elements 
      %     of the input vector. The number of elements in the vector must 
      %     equal the number of rows in the object.
      %
      %     IN:
      %       - `ind` (logical) |COLUMN VECTOR| -- index of elements to 
      %         retain. numel( `ind` ) must equal shape(obj, 1) (i.e., the 
      %         number of rows in the object).
      %     OUT:
      %       - `obj` (Labels) -- same as the input object, but with false
      %         elements of `ind` removed
      
      if ( ~obj.IGNORE_CHECKS )
        assert__is_properly_dimensioned_logical( obj, ind );
      end
      obj.labels = obj.labels(ind, :);
    end
    
    function [obj, full_ind] = remove(obj, selectors)
      
      %   REMOVE -- remove rows of labels for which any of the labels in
      %     `selectors` are found.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- labels to 
      %         identify rows to remove.
      %     OUT:
      %       - `obj` (Labels) -- object with `selectors` removed.
      %       - `full_ind` (logical) |COLUMN| -- index of the removed 
      %         elements, with respect to the inputted (non-mutated) 
      %         object.
      
      if ( ~obj.IGNORE_CHECKS )
        selectors = Labels.ensure_cell( selectors );
        Assertions.assert__is_cellstr( selectors );
      end
      full_ind = false( shape(obj, 1), 1 );
      for i = 1:numel(selectors)
        full_ind = full_ind | where( obj, selectors{i} );
      end
      obj = keep( obj, ~full_ind );
      if ( obj.VERBOSE )
        fprintf( '\n ! Labels/remove: Removed %d rows', sum(full_ind) );
      end
    end
    
    function [obj, full_ind] = rm(obj, selectors)
      
      %   RM -- shorthand alias for `remove()`. See `help Labels/remove`.
      
      [obj, full_ind] = remove( obj, selectors );
    end
    
    function [obj, ind] = only(obj, selectors)
      
      %   ONLY -- retain the labels that match the labels in `selectors`.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- labels to
      %       retain.
      %     OUT:
      %       - `obj` (Labels) -- object with only the labels in
      %       `selectors`.
      %       - `ind` (logical) -- the index used to select the labels in
      %         the outputted object.
      
      ind = where( obj, selectors );
      obj = keep( obj, ind );
    end    
    
    %{
        ELEMENT LOCATION
    %}
    
    function tf = contains(obj, selectors, unqs)
      
      %   CONTAINS -- check if the object contains any of the labels in
      %     `selectors`.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- labels to
      %         query.
      %       - `unqs` (cell array of cell arrays of strings) |OPTIONAL| -- 
      %         the unique elements against which the `selectors` will be
      %         compared. This will usually be used only internally, in
      %         order to avoid repeated calls to uniques() when the object
      %         is not being mutated.
      %     OUT:
      %       - `tf` (bool) -- index of whether the object contains the
      %         given selectors. Each tf(i) corresponds to selectors(i).
      
      if ( ~obj.IGNORE_CHECKS )
        selectors = Labels.ensure_cell( selectors );
        Assertions.assert__is_cellstr( selectors );
      end
      if ( nargin < 3 )
        unqs = cellfun( @(x) x', uniques(obj), 'UniformOutput', false );
        unqs = [ unqs{:} ];
      end
      tf = false( 1, numel(selectors) );
      for i = 1:numel(selectors)
        tf(i) = any( strcmp(unqs, selectors{i}) );
      end
    end
    
    function tf = contains_fields(obj, fs)
      
      %   CONTAINS_FIELDS -- Determine whether the desired fields are in
      %     the object.
      %
      %     IN:
      %       - `fs` (cell array of strings, char) -- Fields to test.
      %     OUT:
      %       - `tf` (logical) -- Index of whether the `fs`(i) is a field
      %         in the object.
  
      if ( ~obj.IGNORE_CHECKS )
        fs = Labels.ensure_cell( fs );
        Assertions.assert__is_cellstr( fs );
      end
      
      tf = cellfun( @(x) any(strcmp(obj.fields, x)), fs );
    end
    
    function ind = find_fields(obj, fields)
      
      %   FIND_FIELDS -- get the index of where each desired field is stored
      %     in `obj.fields`.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- fields to locate.
      %         Note that fields can be repeated.
      %
      %     OUT:
      %       - `ind` (double) -- corresponding location of the field(s) in
      %         `obj.fields`.
      
      fields = Labels.ensure_cell( fields );
      assert__contains_fields( obj, fields );
      ind = cellfun( @(x) find(strcmp(obj.fields, x)), fields );
    end
    
    function [full_index, found_fields] = where(obj, selectors, labs, fields)
      
      %   WHERE -- obtain an index of the rows associated with desired
      %     labels in `selectors`. 
      %
      %     ACROSS fields, indices are AND indices; WITHIN a field, indices 
      %     are OR indices. If any of the labels in `selectors` is not 
      %     found, the entire index is false. Also returns the field 
      %     associated with each label in `seletors`. If a given 
      %     `selectors`{i} is not found, the `found_fields`{i} will be -1.
      %     `found_fields` will always be of the same dimensions as
      %     `selectors`; i.e., the function is guaranteed to list the field
      %     associated with `selectors`(i), even if, say, the very first
      %     element of `selectors` is not found.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- Desired
      %         labels.
      %       - `labs` (cell array of strings) |OPTIONAL| -- The labels to
      %         search through. ALMOST NEVER will this input be specified
      %         by the user; `labs` is, by default, the labels in
      %         `obj.labels`. However, it is occassionally useful to search
      %         through a truncated array of labels, when, for example, 
      %         there are many label fields, and it is known in advance in 
      %         which fields our `selectors` should reside. In this case, 
      %         you can call get_fields() to obtain a truncated array of 
      %         labels from the object, and pass that array into this
      %         function. Also in that case, you must provide the `fields` 
      %         that correspond to the inputted `labels`.
      %       - `fields` (cell array of strings) -- fields that correspond
      %         to the manually inputted labels.
      %     OUT:
      %       - `full_index` (logical) |COLUMN| -- Index of which rows
      %         correspond to the `selectors`.
      %       - `found_fields` (cell array) -- The field associated with
      %         the found `selectors`(i), or else -1 if `selectors`(i) is
      %         not found.
      
      if ( nargin < 3 )
        labs = obj.labels; 
        fields = obj.fields; %#ok<*PROPLC>
      else
        %   make sure we specify both labels and fields if we're manually
        %   overriding the default behavior (which is to take the labels
        %   and fields from the object). Ensure the labels and fields are
        %   properly formatted.
        narginchk(4, 4);
        if ( ~obj.IGNORE_CHECKS )
          Assertions.assert__is_cellstr( labs );
          Assertions.assert__is_cellstr( fields );
          assert( size(labs, 2) == numel(fields), ...
            ['If manually specifying fields and labels, the number of fields' ...
            , ' must match the number of columns in labels'] );
        end
      end;
      if ( ~obj.IGNORE_CHECKS )
        selectors = Labels.ensure_cell( selectors );
        Assertions.assert__is_cellstr( selectors );
        assert( ~obj.IS_PREALLOCATING, ...
            ['The object is currently preallocating; it is an error to search' ...
            , ' a preallocating object. If the object is fully populated, call' ...
            , ' cleanup() to finish the preallocation process.'] );
      end
      
      N = shape( obj, 1 );
      selectors = unique( selectors );
      indices = false( N, numel(selectors) );
      found_fields = cell( 1, numel(selectors) );
      full_index = false( N, 1 );
      all_false = false;
      cols = nan( size(found_fields) );
      
      for i = 1:numel(selectors)
        ind = strcmp( labs, selectors{i} );
        if ( ~any(ind(:)) ), found_fields{i} = -1; all_false = true; continue; end;
        cols(i) = find( sum(ind) >= 1 );
        found_fields{i} = fields{ cols(i) };
        indices(:, i) = sum( ind, 2 );
      end
      
      if ( all_false ), return; end;
      
      unqs = unique( cols );
      n_unqs = numel( unqs );
      
      if ( n_unqs == numel(cols) )
        full_index = all( indices, 2 ); return;
      end
      
      %   find the repeated columns in `indices` -- these repeats will be
      %   ORed, and then ANDed with the non-repeats. We choose to do this
      %   calculation 'post-hoc', because, most of the time, columns will
      %   *not* be repeated.
      
      reps = false( size(cols) );
      repeats = nan( size(cols) );
      
      for i = 1:numel(cols)
        if ( sum(cols == cols(i)) > 1 ), reps(i) = true; repeats(i) = cols(i); end;
      end
      repeats = unique( repeats(~isnan(repeats)) );
      others = ~reps;
      full_index(:) = true;
      for i = 1:numel( repeats );
        inds = any( indices(:, cols == repeats(i) ), 2 );
        full_index = full_index & inds;
        if ( ~any(full_index) ), return; end;
        if ( ~any(others) ), continue; end;
        full_index = full_index & all( indices(:, others), 2 );
      end      
      
    end
    
    %{
        ITERATION
    %}
    
    function [indices, c] = get_indices(obj, fields)
      
      %   GET_INDICES -- return an array of indices corresponding to all
      %     unique combinations of labels in the specified fields for which
      %     there is a match. 
      %
      %     I.e., some unique combinations of labels might not exist in the 
      %     object, and if so, the index of their location is not returned. 
      %     Thus when calling keep() on the object with each index returned 
      %     by get_indices(), it is guarenteed that the object will not be 
      %     empty. The idea behind this function is to avoid nested loops 
      %     -- instead, you can call get_indices with the desired 
      %     specificty, and then only loop through the resulting indices.
      %
      %     IN:
      %       - `fields` (cell array of strings, char) -- Fields from which 
      %         to draw unique combinations of labels. Can be thought of as 
      %         the specificity of the indexing.
      %     OUT:
      %       - `indices` (cell array of logical column vectors) -- Indices
      %         of the unique combinations of labels in `c`. Each row (i)
      %         in `indices` corresponds to the unique labels in `c`(i).
      %       - `c` (cell array of strings) -- Unique combinations
      %         identified by each index in `indices`(i).
      
      fields = Labels.ensure_cell( fields );
      Assertions.assert__is_cellstr( fields );
      c = combs( obj, fields );
      labels = get_fields( obj, fields );
      indices = cell( size(c,1), 1 );
      remove = false( size(indices) );
      obj.IGNORE_CHECKS = true;
      for i = 1:size(c, 1)
        if ( obj.VERBOSE )
          fprintf( '\n ! Labels/get_indices: Processing %d of %d', i, size(c, 1) ); 
        end
        ind = where( obj, c(i,:), labels, fields );
        if ( ~any(ind) ), remove(i) = true; continue; end;
        indices{i} = ind;
      end
      indices(remove) = [];
      c(remove, :) = [];
    end    
    
    %{
        EQUALITY AND INTER-OBJECT COMPATIBILITY
    %}
    
    function tf = fields_match(obj, B)
      
      %   FIELDS_MATCH -- Check if the fields of two `Labels` objects
      %     match. 
      %
      %     If the tested input is not a `Labels` object, tf is false.
      %
      %     IN:
      %       - `B` (/any/) -- values to test.
      %     OUT:
      %       - `tf` (bool) -- true if `B` is a Labels object with fields
      %         that match the other object.
      
      tf = false;
      if ( ~isa(B, 'Labels') ), return; end;
      tf = isequal( obj.fields, B.fields );
    end
    
    function tf = shapes_match(obj, B)
      
      %   SHAPES_MATCH -- Check if the shapes of two `Labels` objects
      %     match.
      %   
      %     If the tested input is not a `Labels` object, tf is false.
      %
      %     IN:
      %       - `B` (/any/) -- values to test
      %     OUT:
      %       - `tf` (bool) -- true if `B` is a Labels object with a shape 
      %         that matches the shape of the other object.
      
      tf = false;
      if ( ~isa(B, 'Labels') ), return; end;
      tf = all( shape(obj) == shape(B) );
    end
    
    function tf = eq(obj, B)
      
      %   EQ -- Check equality between two `Labels` objects. If the tested
      %     input is not a `Labels` object, the output is false.
      %
      %     IN:
      %       - `B` (/any/) -- values to test.
      %     OUT:
      %       - `tf` (bool) -- true if `B` is a Labels object with fields,
      %       shape, and labels that match the other object.
      
      tf = false;
      if ( ~isa(B, 'Labels') ), return; end;
      if ( ~fields_match(obj, B) ), return; end;
      if ( ~shapes_match(obj, B) ), return; end;
      compared = strcmp( obj.labels, B.labels );
      tf = all( compared(:) );
    end
    
    function tf = ne(obj, B)
      
      %   NE -- ~eq(). See `help Labels/eq` for more information.
      
      tf = ~eq(obj, B);
    end
    
    %{
        PREALLOCATION
    %}
    
    function obj = preallocate(obj, sizes)
      
      %   PREALLOCATE -- return a preallocated object in which the cells of
      %     `obj.labels` are filled with a predefined expression: '/*/'. 
      %
      %     The initial object must be empty (i.e., derived from a call to
      %     Labels() without input arguments). Otherwise, an error will be
      %     thrown. Depending on the size of the object, preallocating can 
      %     be much faster than using the append() method, which simply
      %     concatenates label arrays.
      %
      %     Call populate() to continuously fill the object with new
      %     `Labels`. Then call cleanup() to remove excess elements as
      %     necessary.
      %
      %     IN:
      %       - `sizes` (2 element double) -- Specify the size of the
      %         labels cell array. Note that, in order to properly populate 
      %         the object, the number of columns must match the number of 
      %         columns in the target (to-fill-with) object. 
      
      assert( isempty(obj), 'When preallocating, the starting object must be empty' );
      assert( numel(sizes) == 2, 'Specify two dimensions' );
      obj.IS_PREALLOCATING = true;
      obj.PREALLOCATION_ROW = 1;
      obj.PREALLOCATION_SIZE = sizes(1);
      obj.labels = repmat( {obj.PREALLOCATION_EXPRESSION}, sizes );
      obj.fields = repmat( {obj.EMPTY_FIELDNAME}, [1, sizes(2)] );
    end
    
    function obj = populate(obj, B)
      
      %   POPULATE -- fill a preallocating object with the contents of
      %     another object. 
      %
      %     If the preallocating object is empty ( i.e., if this is the 
      %     first call to populate() after preallocate() ), the fields of 
      %     the preallocating object will be overwritten with the fields of 
      %     the incoming object. Subsequent calls to populate() will then 
      %     require the fields of the incoming object to match those of 
      %     the preallocating object.
      %   
      %     With each call to populate(), the function will fill labels
      %     starting from `obj.PREALLOCATION_ROW`; the index is updated at
      %     the end of the function call.
      %
      %     IN:
      %       - `B` (Labels) -- The incoming object with which to populate
      %         the preallocating object
      %     OUT:
      %       - `obj` (Labels) -- The populated object          
      
      assert( obj.IS_PREALLOCATING, ...
        'Can only populate after an explicit call to preallocate()' );
      if ( obj.BEEN_POPULATED )
        assert__fields_match( obj, B );
      else
        assert( shape(obj, 2) == shape(B, 2), ...
          [ 'Incorrect number of columns in the preallocated object' ...
           , ' - expected %d, but there were %d' ], shape(B, 2), shape(obj, 2));
        nfields = numel( B.fields );
        assert( nfields == numel(unique(B.fields)), ...
            'The incoming object has duplicate fields, which is an error' );
        obj.fields = B.fields;
        obj.BEEN_POPULATED = true;
      end
      start = obj.PREALLOCATION_ROW;
      terminus = start + shape(B, 1) - 1;
      obj.labels(start:terminus, :) = B.labels;
      obj.PREALLOCATION_ROW = terminus + 1;
    end
    
    function obj = cleanup(obj)
      
      %   CLEANUP -- removes excess `PREALLOCATION_EXPRESSION` rows in the
      %     object as necessary, and marks that the object is done
      %     preallocating.
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
        obj.labels = obj.labels( 1:obj.PREALLOCATION_ROW-1, : );
      end
      
      obj.PREALLOCATION_ROW = NaN;
      obj.PREALLOCATION_SIZE = NaN;
    end
    
    %{
        INTER-OBJECT FUNCTIONALITY
    %}
    
    function obj = append(obj, B)
      
      %   APPEND -- append the contents of one `Labels` object to another.
      %     If the first object is empty, the second will be returned.
      %     Otherwise, the fields of the two objects must match.
      %
      %     IN:
      %       - `B` (Labels) -- object to append.
      %     OUT:
      %       - `obj` (Labels) -- object with `B` appended.
      
      Assertions.assert__isa( B, 'Labels' );
      if ( isempty(obj) ), obj = B; return; end;
      assert__fields_match( obj, B );
      obj.labels = [obj.labels; B.labels];
    end
    
    function obj = overwrite(obj, B, index)
      
      %   OVERWRITE -- Assign the contents of another Label object to the
      %     current object at a given `index`.
      %
      %     IN:
      %       - `B` (Labels) -- Object whose contents are to be assigned.
      %         Fields must match between objects.
      %       - `index` (logical) -- Index of where in the assigned-to
      %         object the new labels should be placed. Need have the same
      %         number of true elements as the incoming object, but the
      %         same number of *rows* as the assigned-to object.
      %     OUT:
      %       - `obj` (Labels) -- Object with newly assigned values.
      
      if ( ~obj.IGNORE_CHECKS )
        assert__fields_match( obj, B );
        assert__is_properly_dimensioned_logical( obj, index );
        assert( sum(index) == shape(B, 1), ['The number of true elements' ...
          , ' in the index must match the number\n of rows in the' ...
          , ' incoming object'] );
      end
      obj.labels(index, :) = B.labels;
    end
    
    %{
        UTIL
    %}
    
    function str = repr(obj)
      
      %   REPR -- obtain a string representation of  the categories and 
      %     labels in the object, and the frequency of each label.
      
      unqs = uniques( obj );
      fields = obj.fields; %#ok<*PROP>
      str = '';
      for i = 1:numel(fields)
        current = unqs{i};
        str = sprintf( '%s\n * %s', str, fields{i} );
        if ( obj.VERBOSE )
          nprint = numel( current );
        else nprint = min( [obj.MAX_DISPLAY_ITEMS, numel(current)] );
        end
        for j = 1:nprint
          N = sum( strcmp(obj.labels(:,i), current{j}) );
          str = sprintf( '%s\n\t - %s (%d)', str, current{j}, N );
        end
        remaining = numel(current) - j;
        if ( remaining > 0 )
          str = sprintf( '%s\n\t - ... and %d others', str, remaining );
        end
      end
      str = sprintf( '%s\n\n', str );
    end
    
    function disp(obj)
      
      %   DISP -- print the fields and labels in the object, and indicate
      %     the frequency of each label.
      
      unqs = uniques( obj );
      fields = obj.fields; %#ok<*PROP>
      for i = 1:numel(fields)
        current = unqs{i};
        fprintf( '\n * %s', fields{i} );
        if ( obj.VERBOSE )
          nprint = numel( current );
        else nprint = min( [obj.MAX_DISPLAY_ITEMS, numel(current)] );
        end
        for j = 1:nprint
          N = sum( strcmp(obj.labels(:,i), current{j}) );
          fprintf( '\n\t - %s (%d)', current{j}, N );
        end
        remaining = numel(current) - j;
        if ( remaining > 0 )
          fprintf( '\n\t - ... and %d others', remaining );
        end
      end
      fprintf( '\n\n' );
    end
    
    function obj = repeat(obj, N)
      
      %   REPEAT -- Duplicate the labels in the object N times.
      %
      %     IN:
      %       - `N` (number) -- Number of repetitions.
      
      assert( isscalar(N), 'Specify number of repeats as a single value.' );
      obj.labels = repmat( obj.labels, N, 1 );
    end
    
    function obj = sparse(obj)
      
      %   SPARSE -- Conver the current Labels object to a SparseLabels
      %     object.
      %
      %     See `help SparseLabels/SparseLabels` for more information.
      %
      %     IN:
      %       - `obj` (Labels) -- Object to convert.
      %     OUT:
      %       - `obj` (SparseLabels) -- Object converted to a SparseLabels
      %         object.
      
      obj = SparseLabels( obj );
    end
    
    function ind = create_index(obj, tf)
      
      %   CREATE_INDEX -- Generate an all-false or all-true column index
      %     with the same number of rows as the object.
      %
      %     IN:
      %       - `tf` (logical) -- If true, `ind` is all true, otherwise all
      %         false.
      %     OUT:
      %       - `ind` (logical) |COLUMN| -- Returned index.
      
      rows = shape( obj, 1 );
      if ( tf ), ind = true( rows, 1 ); else ind = false( rows, 1 ); end;
    end
    
    function s = label_struct(obj)
      
      %   LABEL_STRUCT -- Convert an object's cell array of labels into a
      %     struct with fields `obj.fields`.
      %
      %     OUT:
      %       - `s` (struct) -- Structure with fields `obj.fields`; each
      %         field contains one column of labels from `obj.labels`.
      
      fields = obj.fields;
      for i = 1:numel(fields)
        s.(fields{i}) = obj.labels(:,i);
      end
    end
    
    function [celled, fs] = full_fields(obj, fs)
      
      %   FULL_FIELDS -- Alias for `get_fields` to match the syntax of a
      %     SparseLabels object.
      %
      %     See `help SparseLabels/full_categories` for more info.
      
      if ( nargin < 2 ), fs = obj.fields; end;
      celled = get_fields( obj, fs );
    end
    
    %{
        LABELS-SPECIFIC ASSERTIONS
    %}
    
    function assert__is_properly_dimensioned_logical(obj, B, opts)
      if ( nargin < 3 )
        opts.msg = sprintf( ['The index must be a column vector with the same number' ...
          , ' of rows as the object (%d). The inputted index had (%d) elements'] ...
          , shape(obj, 1), numel(B) );
      end
      assert( islogical(B), opts.msg );
      assert( iscolumn(B), opts.msg );
      assert( size(B, 1) == shape(obj, 1), opts.msg );
    end
    
    function assert__fields_and_shapes_match(obj, B, opts)
      if ( nargin < 3 )
        opts.msg = 'Fields and shapes must match between objects'; 
      end
      assert( isa(B, 'Labels'), 'The second input must be a Labels object' );
      assert( fields_match(obj, B) & shapes_match(obj, B), opts.msg );
    end
    
    function assert__fields_match(obj, B, opts)
      if ( nargin < 3 ), opts.msg = 'Fields must match between objects'; end;
      assert( isa(B, 'Labels'), 'The second input must be a Labels object' );
      assert( fields_match(obj, B), opts.msg );
    end
    
    function assert__does_not_contain_fields(obj, fields, opts)
      if ( nargin < 3 )
        opts.msg = [ 'Cannot complete the operations because the field ''%s''' ...
          , ' already exists in the object' ];
      end
      fields = Labels.ensure_cell( fields );
      for i = 1:numel(fields)
        assert( ~any(strcmp(obj.fields, fields{i})), opts.msg, fields{i} );
      end
    end
    
    function assert__contains_fields(obj, fields, opts)
      if ( nargin < 3 )
        opts.msg = 'The field ''%s'' is not in the object';
      end
      fields = Labels.ensure_cell( fields );
      for i = 1:numel(fields)
        assert( any(strcmp(obj.fields, fields{i})), opts.msg, fields{i} );
      end
    end
  end
  
  methods (Static = true)
    function validate__initial_input(S)
      %   make sure input is a struct with the appropriate format
      Assertions.assert__isa( S, 'struct' );
      f = fieldnames( S );
      cellfun( @(x) Assertions.assert__is_cellstr(S.(x)), f );
      cellfun( @(x) assert(iscolumn(S.(x)), ...
        'Each field of the input structure must be a cell column vector'), f );
      if ( numel(f) == 1 ), return; end;
      nels = numel( S.(f{1}) );
      for i = 2:numel(f)
        %   make sure arrays are of consistent dimensions
        assert( numel(S.(f{i})) == nels, ...
          'All fields of the input structure must have the same number of elements' );
      end      
      %   ensure all labels are unique
      uniqs = structfun( @(x) unique(x), S, 'UniformOutput', false );
      for i = 1:numel(f)
        current = uniqs.(f{i});
        others = f( ~strcmp(f, f{i}) );
        for j = 1:numel(others)
          other = uniqs.(others{j});
          assert( ~any(cellfun(@(x) sum(strcmp(other, x)), current)), ...
            'It is an error to have fields with duplicate labels' );
        end
      end
    end
    
    function arr = ensure_cell(arr)
      if ( ~iscell(arr) ), arr = { arr }; end;
    end
  end
  
  
end

%         msg = ['The index must be a logical column vector with the same number' ...
%           , ' of elements as shape(obj, 1)'];
%         assert( iscolumn(ind), msg );
%         assert( numel(ind) == shape(obj, 1), msg );
%         assert( islogical(ind), msg );