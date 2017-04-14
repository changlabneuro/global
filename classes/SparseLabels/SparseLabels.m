classdef SparseLabels
  
  properties
    labels = {};
    categories = {};
    indices = sparse([]);
  end
  
  properties (Access = protected)
    IGNORE_CHECKS = false;
    VERBOSE = false;
    MAX_DISPLAY_ITEMS = 10;
    COLLAPSED_EXPRESSION = 'all__';
  end
  
  methods
    function obj = SparseLabels(labs)
      if ( nargin < 1 ), return; end;
      if ( isstruct(labs) )
        labs = SparseLabels.convert_struct_input_to_labels( labs );
      elseif ( iscell(labs) )
        SparseLabels.validate__cell_input( labs );
        obj.labels = cellfun( @(x) x.label, labs, 'un', false );
        obj.categories = cellfun( @(x) x.category, labs, 'un', false );
        indices = cellfun( @(x) x.index, labs, 'un', false );
        obj.indices = [ indices{:} ];
        return;
      elseif ( ~isa(labs, 'Labels') )
        error( ['Cannot create a SparseLabels object from input of class' ...
            , ' ''%s'''], class(labs) );
      end
      all_labs = cellfun( @(x) x', uniques(labs), 'UniformOutput', false );
      all_labs = [ all_labs{:} ];
      labels = cell( numel(all_labs), 1 );
      categories = cell( size(labels) );
      indices = false( shape(labs,1), numel(all_labs) );
      for i = 1:numel(all_labs)
        [ind, category] = where( labs, all_labs{i} );
        indices(:, i) = ind;
        categories{i} = category{1};
        labels{i} = all_labs{i};
      end
      obj.labels = labels;
      obj.categories = categories;
      obj.indices = sparse( indices );
    end
    
    %{
        SIZE / SHAPE
    %}
    
    function s = shape(obj, dim)
      
      %   SHAPE -- get the size of the labels cell array.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- dimension of the array of 
      %         labels to query. E.g., size(obj, 1).
      %     OUT:
      %       - `s` (double) -- Dimensions
      
      if ( isempty(obj) ), s = [0 0]; else s = size( obj.indices ); end;
      if ( nargin < 2 ), return; end;
      s = s( dim );
    end
    
    function n = nels(obj)
      
      %   NELS -- Number of labels, indices, and categories in the object.
      %
      %     OUT:
      %       - `n` (double) |SCALAR|
      
      n = numel( obj.labels );
    end
    
    function tf = isempty(obj)
      
      %   ISEMPTY -- True if `obj.labels` is an empty cell array.
      
      tf = isempty( obj.labels );
    end
    
    %{
        INDEX HANDLING
    %}
    
    function ind = get_index(obj, label)
      
      %   GET_INDEX -- Get the index associated with a label.
      %
      %     An error is thrown if the label is not in the object.
      %     
      %     IN:
      %       - `label` (char) -- Label to obtain the index of.
      %     OUT:
      %       - `ind` (logical) |COLUMN| -- Index corresponding to the
      %         given label.
      
      assert( isa(label, 'char'), ...
        'Label must be a char; was a ''%s''', class(label) );
      assert( contains(obj, label) );
      ind = obj.indices( :, strcmp(obj.labels, label) );
    end
    
    %{
        LABEL HANDLING
    %}
    
    function uniform = get_uniform_categories(obj)
      
      %   GET_UNIFORM_CATEGORIES -- Return an array of category names for
      %     which there is only one label present in the category.
      %
      %     OUT:
      %       - `uniform` (cell array of strings) -- Category names.
      
      cats = obj.categories;
      unique_cats = unique( cats );
      uniform_ind = cellfun( @(x) sum(strcmp(cats, x)) == 1, unique_cats );
      uniform = unique_cats( uniform_ind );
    end
    
    function non_uniform = get_non_uniform_categories(obj)
      
      %   GET_NON_UNIFORM_CATEGORIES -- Return an array of category names
      %     for which there is more than one label present in the category.
      %
      %     OUT:
      %       - `non_uniform` (cell array of strings) -- Category names.
      
      uniform = get_uniform_categories( obj );
      non_uniform = setdiff( unique(obj.categories), uniform );
    end
    
    function obj = set_field(obj, cat, set_as, varargin)
      
      %   SET_FIELD -- Alias for `set_category` to match the syntax of a
      %     Labels object.
      %
      %     See `help SparseLabels/set_category` for more info.
      
      obj = set_category( obj, cat, set_as, varargin{:} );
    end
    
    function obj = set_category(obj, cat, set_as, index)
      
      %   SET_CATEGORY -- Assign all labels in a given category to a
      %     specified string.
      %
      %     Note the restrictions of set_category in comparison to
      %     set_field for a Labels object: It is currently only possible to
      %     set the entire contents of a given category to a single string,
      %     or the contents of a given category at a given index.
      %
      %     IN:
      %       - `cat` (char) -- Name of the category to set. An error is
      %         thrown if it is not found in the object.
      %       - `set_as` (char) -- Label to assign to the values in `cat`.
      %       - `index` (logical) |OPTIONAL| -- Which labels to overwrite.
      %         If unspecified, all labels will be 
      
      if ( nargin < 4 )
        index = rep_logic( obj, true ); 
      else assert__is_properly_dimensioned_logical( obj, index );
      end
      char_msg = 'Expected %s to be a char; was a ''%s''';
      assert( isa(cat, 'char'), char_msg, 'category name', class(cat) );
      assert( isa(set_as, 'char'), char_msg, 'the labels-to-be-set' ... 
        , class(set_as) );
      assert( contains_categories(obj, cat), ['The specified category ''%s''' ...
        , ' does not exist'], cat );
      labels_to_replace = labels_in_category( obj, cat );
      %   if no index is specified, or the index is entirely true, we can
      %   just replace() all labels
      if ( all(index) )
        obj = replace( obj, labels_to_replace, set_as );
        return;
      end
      inds = cellfun( @(x) get_index(obj, x), labels_to_replace, 'un', false )';
      inds = [ inds{:} ];
      lab_inds = cellfun( @(x) find(strcmp(obj.labels, x)), labels_to_replace );
      for i = 1:size( inds, 2 )
        inds(:, i) = inds(:, i) & ~index;
      end
      obj.indices(:, lab_inds) = inds;
      if ( contains(obj, set_as) )
        current_ind = strcmp( obj.labels, set_as );
        obj.indices(:, current_ind) = index;
      else
        obj.labels{end+1} = set_as;
        obj.categories{end+1} = cat;
        obj.indices(:, end+1) = index;
      end
      empties = ~any( obj.indices, 1 );
      if ( ~any(empties) ), return; end;
      obj.labels( empties ) = [];
      obj.categories( empties ) = [];
      obj.indices( :, empties ) = [];
    end
    
    function labs = get_fields(obj, cat)
      
      %   GET_FIELDS -- Alias for `labels_in_category` to allow proper
      %     compatibility with a Container object.
      %
      %     See `help SparseLabels/labels_in_category` for more info.
      
      labs = labels_in_category( obj, cat );
    end
    
    function labs = labels_in_category(obj, cat)
      
      %   LABELS_IN_CATEGORY -- Get the labels in a given category.
      %
      %     An error is thrown if the specified category does not exist.
      %
      %     IN:
      %       - `cat` (char) -- Category to obtain.
      %     OUT:
      %       - `labs` (cell array of strings) -- Labels in the specified
      %         category.
      
      if ( ~obj.IGNORE_CHECKS )
        assert( isa(cat, 'char'), 'Category must be a char; was a ''%s.''' ...
          , class(cat) );
        assert__categories_exist( obj, cat ); 
      end
      labs = obj.labels( strcmp(obj.categories, cat) );
    end
    
    function [unqs, cats] = uniques(obj, cats)
      
      %   UNIQUES -- Get the unique labels in the given categories,
      %     separated by category.
      %
      %     An error is thrown if a given category does not exist in the
      %     object.
      %
      %     IN:
      %       - `cats` (cell array of strings, char) |OPTIONAL| --
      %         Categories to query. If unspecified, the outputted unique
      %         values will be parceled into each category in the object.
      %     OUT:
      %       - `unqs` (cell array of cell arrays of strings) -- Unique
      %         labels in each category `cats(i)`.
      %       - `cats` (cell array of strings) -- Categories associated
      %         with each `unqs`(i). This is only useful if you do not
      %         specify `cats` as an input.
      
      if ( nargin < 2 ), cats = unique(obj.categories); end;
      if ( ~obj.IGNORE_CHECKS )
        cats = SparseLabels.ensure_cell( cats );
        SparseLabels.assert__is_cellstr_or_char( cats );
      end
      unqs = cell( 1, numel(cats) );
      for i = 1:numel(cats)
        unqs{i} = labels_in_category( obj, cats{i} );
      end
    end
    
    function unqs = flat_uniques(obj, cats)
      
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
      
      if ( nargin < 2 ), cats = unique( obj.categories ); end;
      unqs = uniques( obj, cats );
      unqs = cellfun( @(x) x(:)', unqs, 'un', false );
      assert( all(cellfun(@(x) isrow(x), unqs)), ['Not all unique values' ...
        , ' were a row vector. This is possibly due to manually overwriting' ...
        , ' the labels property of the object'] );
      unqs = [ unqs{:} ];
    end
    
    function tf = contains(obj, labels)
      
      %   CONTAINS -- Obtain an index of whether the given label(s) are
      %     present in the `obj.labels` cell array.
      %
      %     IN:
      %       - `labels` (cell array of strings, char) -- Label(s) to test.
      %     OUT:
      %       - `tf` (logical) -- Vector of true/false values where each
      %         `tf`(i) corresponds to each `labels`(i).
      
      labels = SparseLabels.ensure_cell( labels );
      SparseLabels.assert__is_cellstr_or_char( labels );
      tf = cellfun( @(x) any(strcmp(obj.labels, x)), labels );
    end
    
    function tf = contains_categories(obj, fs)
      
      %   CONTAINS_CATEGORIES -- Obtain an index of whether the given 
      %     categories(s) are present in the `obj.categories` cell array.
      %
      %     IN:
      %       - `categories` (cell array of strings, char) -- Categories(s)
      %         to test.
      %     OUT:
      %       - `tf` (logical) -- Vector of true/false values where each
      %         `tf`(i) corresponds to each `categories`(i).
      
      fs = SparseLabels.ensure_cell( fs );
      SparseLabels.assert__is_cellstr_or_char( fs );
      tf = cellfun( @(x) any(strcmp(obj.categories, x)), fs );
    end
    
    function tf = contains_fields(obj, fs)
      
      %   CONTAINS_FIELDS -- Alias for `contains_categories()`.
      %
      %     See `help SparseLabels/contains_categories()` for more
      %     information.
      
      tf = contains_categories( obj, fs );
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
      %         to reflect the replacements.
      
      search_for = SparseLabels.ensure_cell( search_for );
      SparseLabels.assert__is_cellstr_or_char( search_for );
      search_for = search_for(:)';
      Assertions.assert__isa( with, 'char' );
      tf = contains( obj, search_for );
      search_for( ~tf ) = [];
      if ( isempty(search_for) )
        fprintf( ['\n ! SparseLabels/replace: Could not find any of the' ...
          , ' search terms\n'] );
        return;
      end
      search_for( strcmp(search_for, with) ) = [];
      if ( isempty(search_for) ), return; end
      %   where are the current search terms in the obj.labels cell array?
      lab_inds = cellfun( @(x) find(strcmp(obj.labels, x)), search_for );
      cats = obj.categories( lab_inds );
      %   make sure the categories of the search terms are all the same.
      if ( numel(unique(cats)) ~= 1 )
        error( ['Replacing the search term(s) with ''%s'' would place ''%s''' ...
          , ' in multiple categories.'], with, with );
      end
      tf = contains( obj, with );
      %   if the object already contains the replace-with term, make sure
      %   its category is consistent with those of `search_for`, and add
      %   its index to the `lab_inds` array.
      if ( tf )
        current_ind = strcmp( obj.labels, with );
        categ = obj.categories( current_ind );
        assert( all(strcmp(unique(cats), categ)), ['The search term ''%s'' already' ...
          , ' exists in the category ''%s''; attempted to place ''%s'' in' ...
          , ' the category ''%s''.'], with, categ{1}, with, cats{1} );
        lab_inds = [ lab_inds, find(current_ind) ];
      end
      new_inds = any( obj.indices(:, lab_inds), 2 );
      obj.labels( lab_inds(1) ) = { with };
      obj.indices(:, lab_inds(1)) = new_inds;
      if ( numel(lab_inds) == 1 ), return; end;
      %   remove category, labels, and indices associated with the
      %   duplicates
      obj.labels( lab_inds(2:end) ) = [];
      obj.categories( lab_inds(2:end) ) = [];
      obj.indices(:, lab_inds(2:end)) = [];
    end
    
    function obj = collapse(obj, cats)
      
      %   COLLAPSE -- Replace labels in a category or categories with a
      %     repeated, category-namespaced expression: 'all__`category`'.
      %
      %     An error is thrown if even one of the specified categories is
      %     not found.
      %
      %     IN:
      %       - `cats` (cell array of strings, char) -- category or
      %         categories to collapse.
      %     OUT:
      %       - `obj` (Labels) -- object with the appropriate categories
      %         collapsed.
      
      cats = unique( SparseLabels.ensure_cell(cats) );
      labs = cellfun( @(x) labels_in_category(obj, x)', cats, ...
        'UniformOutput', false );
      for i = 1:numel(labs)
        obj = replace( obj, labs{i}, [obj.COLLAPSED_EXPRESSION cats{i}] );
      end      
    end
    
    function obj = collapse_except(obj, cats)
      
      %   COLLAPSE_EXCEPT -- Collapse all categories except the given
      %     categories.
      %
      %     IN:
      %       - `cats` (Cell array of strings, char) -- category or
      %       categories to avoid collapsing.
      
      assert__categories_exist( obj, cats );
      cats = SparseLabels.ensure_cell( cats );
      to_collapse = setdiff( obj.categories, cats );
      obj = collapse( obj, to_collapse );
    end
    
    function obj = collapse_non_uniform(obj)
      
      %   COLLAPSE_NON_UNIFORM -- Collapse categories for which there is
      %     more than one label present in the category.
      %
      %     See `help SparseLabels/get_uniform_categories` for more info.
      
      non_uniform = get_non_uniform_categories( obj );
      obj = collapse( obj, non_uniform );
    end
    
    function obj = collapse_uniform(obj)
      
      %   COLLAPSE_UNIFORM -- Collapse categories for which there is
      %     only one label present in the category.
      %
      %     See `help SparseLabels/get_uniform_categories` for more info.
      
      uniform = get_uniform_categories( obj );
      obj = collapse( obj, uniform );
    end
    
    function obj = collapse_if_non_uniform(obj, categories)
      
      %   COLLAPSE_IF_NON_UNIFORM -- Collapse a give number of categories,
      %     but only if they are non-uniform.
      %
      %     See `help SparseLabels/collapse_non_uniform` for more info.
      %
      %     IN:
      %       - `categories` (cell array of strings, char) |OPTIONAL| --
      %         Categories to collapse, if they are non-uniform. If
      %         omitted, the output is equivalent to calling
      %         `collapse_non_uniform()`.
      
      if ( nargin < 2 )
        categories = unique( obj.categories ); 
      else assert__categories_exist( obj, categories );
      end
      non_uniform = get_non_uniform_categories( obj );
      non_uniform = intersect( non_uniform, categories );
      obj = collapse( obj, non_uniform );
    end
    
    function obj = add_field(obj, name, labs)
      
      %   ADD_FIELD -- Alias for `add_category`.
      %
      %     See `help SparseLabels/add_category` for more info.
      
      obj = add_category( obj, name, labs );
    end
    
    function obj = add_category(obj, name, labs)
      
      %   ADD_CATEGORY -- Insert new labels and indices in a given category
      %     into the object.
      %
      %     Input must be valid input to a Labels and SparseLabels object.
      %     It is an error to add a category that already exists in the
      %     object. It is an error to add labels that already exist in the
      %     object.
      %
      %     IN:
      %       - `name` (char) -- Name of the category to add. Cannot be a
      %         current value of `obj.categories`.
      %       - `labs` (cell array of strings) -- New labels to add. Must
      %         have the same number of elements as there are rows in the
      %         object. Cannot have any elements that are current labels in
      %         `obj.labels`.
      %     OUT:
      %       - `obj` (SparseLabels) -- Object with the category added.
      
      assert( isa(name, 'char'), 'Category name must be a char; was a ''%s''' ...
        , class(name) );
      assert( ~contains_categories(obj, name), ['The category ''%s'' already' ...
        , ' exists in the object'], name );
      labs = SparseLabels.ensure_cell( labs );
      assert( iscellstr(labs), 'Labels must be a cell array of strings' );
      if ( numel(labs) ~= 1 )
        assert( numel(labs) == shape(obj, 1), ['The number of inputted labels' ...
          , ' must match the current number of rows in the object'] );
      else labs = repmat( labs, shape(obj, 1), 1 );
      end
      exists = cellfun( @(x) any(strcmp(obj.labels, x)), unique(labs) );
      assert( ~any(exists), ['It is an error to insert duplicate labels' ...
        , 'into the object'] );
      try
        s.(name) = labs;
      catch err
        fprintf( ['\n ! SparseLabels/add_category: The following error' ...
          , ' occurred when attempting to instantiate a struct with fieldname' ...
          , ' ''%s'':'], name );
        error( err.message );
      end
      try
        labs = Labels( s );
      catch err
        fprintf( ['\n ! SparseLabels/add_category: When adding a category,' ...
          , ' the input must be valid input to a Labels object. Instantiating' ...
          , ' a Labels object with the given input failed with the following' ...
          , ' message:'] );
        error( err.message );
      end
      try
        labs = sparse( labs );
      catch err
        fprintf( ['\n ! SparseLabels/add_category: When adding a category,' ...
          , ' the input must be valid input to a SparseLabels object. Instantiating' ...
          , ' a SparseLabels object with the given input failed with the following' ...
          , ' message:'] );
        error( err.message );
      end
      obj.labels = [obj.labels(:); labs.labels];
      obj.categories = [obj.categories(:); labs.categories];
      obj.indices = [obj.indices labs.indices];
    end
    
    function obj = rm_fields( obj, fields )
      
      %   RM_FIELDS -- Alias for `rm_categories` to ensure proper
      %     Container functionality.
      %
      %     See `help SparseLabels/rm_categories` for more info.
      
      obj = rm_categories( obj, fields );
    end
    
    function obj = rm_categories( obj, cats )
      
      %   RM_CATEGORIES -- Remove all labels, indices, and category names
      %     associated with the specified categories.
      %
      %     An error is thrown if any of the specified categories do not
      %     exist.
      %
      %     IN:
      %       - `cats` (cell array of strings, char) -- Categories to
      %         remove.
      
      cats = SparseLabels.ensure_cell( cats );
      SparseLabels.assert__is_cellstr_or_char( cats );
      assert__categories_exist( obj, cats );
      for i = 1:numel(cats)
        ind = strcmp( obj.categories, cats{i} );
        obj.labels( ind ) = [];
        obj.categories( ind ) = [];
        obj.indices( :, ind ) = [];
      end      
    end
    
    %{
        INDEXING
    %}
    
    function [obj, ind] = only(obj, selectors)
      
      %   ONLY -- retain the labels that match the labels in `selectors`.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- labels to
      %       retain.
      %     OUT:
      %       - `obj` (SparseLabels) -- object with only the labels in
      %       `selectors`.
      %       - `ind` (logical) |SPARSE| -- the index used to select the 
      %         labels in the outputted object.
      
      ind = where( obj, selectors );
      obj = keep( obj, ind );
    end
    
    function obj = keep(obj, ind)
      
      %   KEEP -- given a logical column vector, return a `SparseLabels` 
      %     object whose indices, labels, and categories are truncated to
      %     the elements that match the true elements in the index.
      %
      %     IN:
      %       - `ind` (logical) |COLUMN VECTOR| -- index of elements to 
      %         retain. numel( `ind` ) must equal shape(obj, 1).
      
      if ( ~obj.IGNORE_CHECKS )
        assert__is_properly_dimensioned_logical( obj, ind );
        if ( ~issparse(ind) ), ind = sparse( ind ); end;
      end
      obj.indices = obj.indices(ind, :);
      empties = ~any( obj.indices, 1 )';
      obj.labels(empties) = [];
      obj.categories(empties) = [];
      obj.indices(:, empties) = [];
    end
    
    function [obj, ind] = remove(obj, selectors)
      
      %   REMOVE -- remove rows of labels for which any of the labels in
      %     `selectors` are found.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- labels to 
      %         identify rows to remove.
      %     OUT:
      %       - `obj` (SparseLabels) -- object with `selectors` removed.
      %       - `ind` (logical) |COLUMN| -- index of the removed 
      %         elements, with respect to the inputted (non-mutated) 
      %         object.
      
      ind = rep_logic( obj, false );
      selectors = SparseLabels.ensure_cell( selectors );
      for i = 1:numel(selectors)
        ind = ind | where( obj, selectors{i} );
      end
      obj = keep( obj, ~ind );
      if ( obj.VERBOSE )
        fprintf( '\n ! SparseLabels/remove: Removed %d rows', sum(full_ind) );
      end
    end
    
    function [full_index, cats] = where(obj, selectors)
      
      %   WHERE -- obtain a row index associated with desired labels in 
      %     `selectors`. 
      %
      %     ACROSS fields, indices are AND indices; WITHIN a field, indices 
      %     are OR indices. If any of the labels in `selectors` is not 
      %     found, the entire index is false. Also returns the categories 
      %     associated with each label in `selectors`. If a given 
      %     `selectors`{i} is not found, the `cats`{i} will be -1.
      %     `cats` will always be of the same dimensions as `selectors`; 
      %     i.e., the function is guaranteed to list the category
      %     associated with `selectors`(i), even if, say, the very first
      %     element of `selectors` is not found.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- Desired
      %         labels.
      %     OUT:
      %       - `full_index` (logical) |COLUMN| -- Index of which rows
      %         correspond to the `selectors`.
      %       - `cats` (cell array) -- The category associated with
      %         the found `selectors`(i), or else -1 if `selectors`(i) is
      %         not found.
      
      if ( ~obj.IGNORE_CHECKS )
        selectors = SparseLabels.ensure_cell( selectors );
        assert( iscellstr(selectors), ['Selectors must be a cell array of strings,' ...
          , ' or a char'] );
      end
      full_index = rep_logic( obj, false );
      all_false = false;
      cats = cell( size(selectors) );
      inds = false( shape(obj,1), numel(selectors) );
      for i = 1:numel(selectors)
        label_ind = strcmp( obj.labels, selectors{i} );
        if ( ~any(label_ind) ), all_false = true; cats{i} = -1; continue; end;
        inds(:,i) = obj.indices( :, label_ind );
        cats(i) = obj.categories( label_ind  );
      end
      if ( all_false ), return; end;
      unqs = unique( cats );
      n_unqs = numel( unqs );
      if ( n_unqs == numel(cats) )
        full_index = sparse( all(inds, 2) ); return; 
      end;
      full_index(:) = true;
      for i = 1:n_unqs
        current = inds( :, strcmp(cats, unqs{i}) );
        full_index = full_index & any(current, 2);
        if ( ~any(full_index) ), full_index = sparse(full_index); return; end;
      end
      full_index = sparse( full_index );
    end
    
    %{
        ITERATION
    %}
    
    function c = combs(obj, cats)
      
      %   COMBS -- Get all unique combinations of unique labels in the
      %     given categories.
      %
      %     IN:
      %       - `cats` (cell array of strings, char) |OPTIONAL| --
      %         Categories which to draw unique labels. If unspecified,
      %         uses all unique categories in the object.
      %     OUT:
      %       - `c` (cell array of strings) -- Cell array of strings in
      %         which each column c(:,i) contains labels in category
      %         `cats(i)`, and each row a unique combination of labels.
      
      if ( nargin < 2 ), cats = unique( obj.categories ); end;
      if ( ~obj.IGNORE_CHECKS )
        cats = SparseLabels.ensure_cell( cats );
      end
      unqs = uniques( obj, cats );
      c = allcomb( unqs );
    end
    
    function [inds, c] = get_indices(obj, cats)
      
      %   GET_INDICES -- return an array of indices corresponding to all
      %     unique combinations of labels in the specified categories for
      %     which there is a match. 
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
      %       - `cats` (cell array of strings, char) -- Categories from which
      %         to draw unique combinations of labels. Can be thought of as 
      %         the specificity of the indexing.
      %     OUT:
      %       - `indices` (cell array of logical column vectors) -- Indices
      %         of the unique combinations of labels in `c`. Each row (i)
      %         in `indices` corresponds to the unique labels in `c`(i).
      %       - `c` (cell array of strings) -- Unique combinations
      %         identified by each index in `indices`(i).
      
      c = combs( obj, cats );
      inds = cell( size(c,1), 1 );
      remove = false( size(inds) );
      for i = 1:size(c, 1)
        ind = where( obj, c(i,:) );
        remove(i) = ~any(ind);
        inds{i} = ind;
      end
      inds(remove) = [];
      c(remove,:) = [];
    end
    
    %{
        INTER-OBJECT COMPATIBILITY
    %}
    
    function tf = eq(obj, B)
      
      %   EQ -- Test equality of a `SparseLabels` object with other values.
      %
      %     If the tested values are not a `SparseLabels` object, false is
      %     returned. Otherwise, if the dimensions of the indices in each
      %     object are not consistent; or if the dimensions are consistent, 
      %     but the unique categories in each object are different; or if
      %     the dimensions and categories are consistent, but the labels
      %     in each object are different; or if the dimensions, categories,
      %     and labels are consistent, but the indices are inconsistent --
      %     false is returned.
      %
      %     NOTE that objects are considered equivalent even if the *order*
      %     of the elements in their label-arrays are different. For
      %     example:
      %
      %     %   object `A` has labels { 'john', '30yrs' }
      %     B = A;
      %     B == A                  
      %     %   ans -> true
      %     B = sort_labels( B );
      %     %   sort_labels sorts the labels in the object, and then
      %     %   rearranges its categories and indices in accordance with
      %     %   the sorting index.
      %     B.labels 
      %     %   ans -> { '30yrs', 'john' }
      %     B == A
      %     %   ans -> true
      
      tf = false;
      if ( ~shapes_match(obj, B) ), return; end;
      if ( ~categories_match(obj, B) ), return; end;
      if ( ~labels_match(obj, B) ), return; end;
      obj = sort_labels( obj );
      B = sort_labels( B );
      tf = isequal( obj.indices, B.indices );
    end
    
    function tf = ne(obj, B)
      tf = ~eq(obj, B);
    end
    
    function tf = categories_match(obj, B)
      
      %   CATEGORIES_MATCH -- Determine whether the comparitor is a
      %     `SparseLabels` object with equivalent categories.
      %
      %     Note that equivalent in this context means that the unique
      %     categories in each object are the same; objects with different
      %     sized `categories` arrays, but whose unique values match, are
      %     still equivalent.
      %
      %     IN:
      %       - `B` (/any/) -- Values to test.
      %     OUT:
      %       - `tf` (logical) |SCALAR| -- True if `B` is a SparseLabels
      %         object with matching unique categories.
      
      tf = false;
      if ( ~isa(B, 'SparseLabels') ), return; end;
      tf = isequal( unique(obj.categories), unique(B.categories) );
    end
    
    function tf = cols_match(obj, B)
      
      %   COLS_MATCH -- Check if two `SparseLabels` objects are equivalent
      %     in the second dimension.
      %
      %     If the tested input is not a `SparseLabels` object, tf is false.
      %
      %     IN:
      %       - `B` (/any/) -- values to test
      %     OUT:
      %       - `tf` (logical) |SCALAR -- true if `B` is a SparseLabels 
      %         object with the same number of columns as B
      
      tf = false;
      if ( ~isa(B, 'SparseLabels') ), return; end;
      tf = shape( obj, 2 ) == shape( B, 2 );
    end
    
    function tf = shapes_match(obj, B)
      
      %   SHAPES_MATCH -- Check if the shapes of two `SparseLabels` objects
      %     match.
      %   
      %     If the tested input is not a `SparseLabels` object, tf is false.
      %
      %     IN:
      %       - `B` (/any/) -- values to test
      %     OUT:
      %       - `tf` (logical) |SCALAR -- true if `B` is a SparseLabels 
      %         object with a shape that matches the shape of the other 
      %         object.
      
      tf = false;
      if ( ~isa(B, 'SparseLabels') ), return; end;
      tf = isequal( shape(obj), shape(B) );
    end
    
    function tf = labels_match(obj, B)
      
      %   LABELS_MATCH -- Check if the labels in two `SparseLabels` objects
      %     are equivalent.
      %
      %     Note that the ordering of labels is intentionally not tested.
      
      tf = false;
      if ( ~isa(B, 'SparseLabels') ), return; end;
      tf = isequal( sort(obj.labels), sort(B.labels) );
    end
    
    %{
        INTER-OBJECT HANDLING
    %}
    
    function new = append(obj, B)
      
      %   APPEND -- Append one `SparseLabels` object to another.
      %
      %     If the original object is empty, B is returned unchanged.
      %     Otherwise, categories must match between objects; an error is
      %     thrown if B is not a SparseLabels object.
      %
      %     IN:
      %       - `B` (SparseLabels) -- Object to append.
      %     OUT:
      %       - `new` (SparseLabels) -- Object with `B` appended.
      
      if ( isempty(obj) ), new = B; return; end;
      assert__categories_match( obj, B );
      own_n_true = sum( sum(obj.indices) );
      other_n_true = sum( sum(B.indices) );
      own_rows = shape( obj, 1 );
      own_cols = shape( obj, 2 );
      other_rows = shape( B, 1 );
      shared_labs = intersect( obj.labels, B.labels );
      other_labs = setdiff( B.labels, shared_labs );
      n_other = numel( other_labs );
      new = obj;
      [current_row_inds, current_col_inds] = find( obj.indices );
      new.indices = sparse( current_row_inds, current_col_inds, true, ...
        own_rows+other_rows, own_cols+n_other, own_n_true+other_n_true );
      if ( ~isempty(shared_labs) )
        other_shared_inds = ...
          B.indices( :, cellfun(@(x) find(strcmp(B.labels, x)), shared_labs) );
        own_category_inds = ...
          cellfun( @(x) find(strcmp(obj.labels, x)), shared_labs );
        new.indices( own_rows+1:end, own_category_inds ) = other_shared_inds;
      end
      if ( ~isempty(other_labs) )
        other_label_inds = cellfun(@(x) find(strcmp(B.labels, x)), other_labs);
        other_inds = B.indices( :, other_label_inds );
        new.indices( own_rows+1:end, own_cols+1:end ) = other_inds;
        new.labels(end+1:end+n_other) = other_labs;
        new.categories(end+1:end+n_other) = B.categories( other_label_inds );
      end
    end
    
    function obj = overwrite(obj, B, index)
      
      %   OVERWRITE -- Assign the contents of another SparseLabels object
      %     to the current object at a given `index`.
      %
      %     IN:
      %       - `B` (SparseLabels) -- Object whose contents are to be
      %         assigned. Unique categories must match between objects.
      %       - `index` (logical) -- Index of where in the assigned-to
      %         object the new labels should be placed. Need have the same
      %         number of true elements as the incoming object, but the
      %         same number of *rows* as the assigned-to object.
      %     OUT:
      %       - `obj` (SparseLabels) -- Object with newly assigned values.
      
      if ( ~obj.IGNORE_CHECKS )
        assert( isa(B, 'SparseLabels'), ['Cannot overwrite a SparseLabels' ...
          , ' object with values of class ''%s'''], class(B) );
        assert__is_properly_dimensioned_logical( obj, index );
        assert( shape(B, 1) == sum(index), ['Improperly dimensioned index;' ...
          , ' attempted to assign %d rows, but the index has %d true values'], ...
          shape(B, 1), sum(index) );
      end
      if ( ~issparse(index) ), index = sparse( index ); end;
      assert( categories_match(obj, B), 'Categories do not match between objects' );
      shared = intersect( obj.labels, B.labels );
      others = setdiff( B.labels, obj.labels );
      if ( ~isempty(shared) )
        own_inds = cellfun( @(x) find(strcmp(obj.labels, x)), shared );
        other_inds = cellfun( @(x) find(strcmp(B.labels, x)), shared );
        obj.indices(index, own_inds) = B.indices( :, other_inds );
      end
      if ( isempty(others) ), return; end;
      new_inds = repmat( rep_logic(obj, false), 1, numel(others) );
      other_inds = cellfun( @(x) find(strcmp(B.labels, x)), others );
      new_inds(index,:) = B.indices(:, other_inds);
      obj.indices = [obj.indices new_inds];
      obj.labels = [obj.labels; B.labels(other_inds)];
      obj.categories = [obj.categories; B.categories(other_inds)];
    end
    
    %{
        SORTING
    %}
    
    function obj = sort_labels(obj)
      
      %   SORT_LABELS -- Sort the labels in `obj.labels`, and then reorder 
      %     the categories and indices to match the new sorted order.
      %
      %     OUT:
      %       - `obj` (SparseLabels) -- Object with its labels sorted.
      
      [obj.labels, ind] = sort( obj.labels );
      obj.categories = obj.categories( ind );
      obj.indices = obj.indices( :, ind );
    end
    
    function obj = sort_categories(obj)
      
      %   SORT_CATEGORIES -- Sort the categories in `obj.labels`, and then
      %     reorder the labels and indices to match the new sorted order.
      %
      %     OUT:
      %       - `obj` (SparseLabels) -- Object with its categories sorted.
      
      [obj.categories, ind] = sort( obj.categories );
      obj.labels = obj.labels( ind );
      obj.indices = obj.indices( :, ind );
    end
    
    %{
        UTIL
    %}
    
    function str = repr(obj)
      
      %   REPR -- obtain a string representation of  the categories and 
      %     labels in the object, and the frequency of each label.
      
      [unqs, cats] = uniques( obj );
      str = '';
      for i = 1:numel(cats)
        current = unqs{i};
        str = sprintf( '%s\n * %s', str, cats{i} );
        if ( obj.VERBOSE )
          nprint = numel( current );
        else nprint = min( [obj.MAX_DISPLAY_ITEMS, numel(current)] );
        end
        for j = 1:nprint
          ind = get_index( obj, current{j} );
          N = full( sum(ind) );
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
      
      %   DISP -- print the categories and labels in the object, and 
      %     indicate the frequency of each label.
      
      [unqs, cats] = uniques( obj );
      for i = 1:numel(cats)
        current = unqs{i};
%         fprintf( '\n * %s', cats{i} );
        fprintf( '\n * <strong>%s</strong>', cats{i} );
        if ( obj.VERBOSE )
          nprint = numel( current );
        else nprint = min( [obj.MAX_DISPLAY_ITEMS, numel(current)] );
        end
        for j = 1:nprint
          ind = get_index( obj, current{j} );
          N = full( sum(ind) );
          fprintf( '\n\t - %s (%d)', current{j}, N );
        end
        remaining = numel(current) - j;
        if ( remaining > 0 )
          fprintf( '\n\t - ... and %d others', remaining );
        end
      end
      fprintf( '\n\n' );
    end
    
    function obj = full(obj)
      
      %   FULL -- Convert the SparseLabels object to a full Labels object.
      %
      %     IN:
      %       - `obj` (SparseLabels) -- Object to convert.
      %     OUT:
      %       - `obj` (Labels) -- Converted Labels object.
      
      cats = unique( obj.categories );
      for i = 1:numel(cats)
        s.(cats{i}) = cell( shape(obj,1), 1 );
      end
      labs = obj.labels;
      for i = 1:numel(labs)
        label_ind = strcmp( obj.labels, labs{i} );
        index = obj.indices( :, label_ind );
        cat = obj.categories{ label_ind };
        s.(cat)(index) = labs(i);
      end
      obj = Labels( s );
    end
    
    function [celled, cats] = full_categories(obj, cats)
      
      %   FULL_CATEGORIES -- Obtain a cell array of strings whose rows are
      %     labels and columns are categories.
      %
      %     For a given `label` in a given category, 
      %     `strcmp( celled, label )` will be equivalent to the index
      %     associated with that label as stored in `obj.indices`.
      %
      %     IN:
      %       - `cats` (cell array of strings, char) |OPTIONAL| --
      %         Categories from which to draw labels. If unspecified, all
      %         categories in the object are used.
      %     OUT:
      %       - `celled` (cell array of strings) -- MxN cell array of M
      %         rows of labels in N categories.
      %       - `cats` (cell array of strings) -- Category names
      %         identifying the columns in `celled`.
      
      if ( nargin < 2 )
        cats = unique( obj.categories );
      else
        cats = SparseLabels.ensure_cell( cats );
        assert__categories_exist( obj, cats );
      end
      inds = cellfun( @(x) find(strcmp(obj.categories, x)), cats, 'un', false );
      celled = cell( shape(obj, 1), numel(cats) );
      for i = 1:numel(inds)
        current = inds{i};
        for j = 1:numel(current)
          label_ind = obj.indices( :, current(j) );
          celled( label_ind, i ) = obj.labels( current(j) );
        end
      end
    end
    
    function [celled, cats] = full_fields(obj, varargin)
      
      %   FULL_FIELDS -- Alias for `full_categories`.
      %
      %     See `help SparseLabels/full_categories` for more info.
      
      [celled, cats] = full_categories( obj, varargin{:} );
    end
    
    function log = rep_logic(obj, tf)
      
      %   REP_LOGIC -- Obtain a sparse logical column vector with the same 
      %     number of rows as `shape(obj, 1)`.
      %
      %     IN:
      %       - `tf` (logical) |SCALAR| -- Indicate whether to repeat true
      %         or false values
      %     OUT:
      %       - `log` (logical) |COLUMN| -- Sparse logical column vector;
      %         either all true or all false.
      
      if ( isempty(obj) ), log = tf; return; end;
      if ( tf )
        log = sparse( true(shape(obj, 1), 1) );
      else log = sparse( false(shape(obj, 1), 1) );
      end
    end
    
    function obj = repeat(obj, N)
      
      %   REPEAT -- Duplicate the indices in the object N times.
      %
      %     IN:
      %       - `N` (number) -- Number of repetitions.
      
      assert( isscalar(N), 'Specify number of repeats as a single value.' );
      obj.indices = repmat( obj.indices, N, 1 );
    end
    
    function s = summarize(obj)
      
      %   SUMMARIZE -- Obtain a struct with the labels in the object
      %     segmented into their categories.
      %
      %     OUT:
      %       - `s` (struct) -- Struct whose fieldnames are categories;
      %         each field contains the unique labels in that category.
      
      cats = unique( obj.categories );
      s = struct();
      for i = 1:numel(cats)
        s.(cats{i}) = labels_in_category( obj, cats{i} );
      end
    end
    
    %{
        OBJECT SPECIFIC ASSERTIONS
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
    
    function assert__categories_exist(obj, B, opts)
      if ( nargin < 3 )
        opts.msg = 'The requested category ''%s'' is not in the object';
      end
      cats = unique( obj.categories );
      B = SparseLabels.ensure_cell( B );
      cellfun( @(x) assert(any(strcmp(cats, x)), opts.msg, x), B );
    end
    
    function assert__categories_match(obj, B, opts)
      if ( nargin < 3 )
        opts.msg = 'The categories do not match between objects';
      end
      assert( isa(B, 'SparseLabels'), ['This operation requires a SparseLabels' ...
        , ' as input; input was a ''%s'''], class(B) );
      assert( categories_match(obj, B), opts.msg );
    end
  end
  
  methods (Static = true)
    
    function obj = convert_struct_input_to_labels(s)
      
      %   CONVERT_STRUCT_INPUT_TO_LABELS -- Attempt to instantiate a Labels
      %     object from a struct.
      %
      %     Throws an error if the Labels object cannot be instantiated.
      %
      %     IN:
      %       - `s` (struct) -- Valid input to a Labels object.
      %     OUT:
      %       - `obj` (Labels) -- Instantiated Labels object.
      
      try
        obj = Labels( s );
      catch err
        fprintf( ['\n\nIf instantiating a SparseLabels object with a struct' ...
          , ' as input, the input must be a valid input to a Labels object.' ...
          , '\nInstantiating a Labels object with this input failed with the' ...
          , ' following message:\n'] );
        error( err.message );
      end
    end
    
    function validate__cell_input( c )
      
      msg = [ 'If instantiating a SparseLabels object with a cell array' ...
        , ' as input, the array must be an array of structs with ''label'',' ...
        , ' ''index'', and ''category'' fields, in which a) all labels and' ...
        , ' categories are strings, b) no labels are repeated,' ...
        , ' c) all indices are logical column vectors with the same' ...
        , ' number of rows, and d) the indices of labels in a given category have no' ...
        , ' overlapping true elements.' ];
      assert( all(cellfun(@isstruct, c)), msg );
      required_fields = { 'label', 'category', 'index' };
      for i = 1:numel(required_fields)
        assert( all(cellfun(@(x) isfield(x, required_fields{i}), c)), msg );
      end
      assert( all(cellfun(@(x) isa(x.label, 'char'), c)), msg );
      assert( all(cellfun(@(x) isa(x.category, 'char'), c)), msg );
      assert( all(cellfun(@(x) isa(x.index, 'logical'), c)), msg );
      assert( all(cellfun(@(x) size(x.index, 2) == 1, c)), msg );
      if ( numel(c) == 1 ), return; end;
      assert( all(diff(cellfun(@(x) size(x.index, 1), c)) == 0), msg );
      labs = cellfun( @(x) x.label, c, 'un', false );
      assert( numel(unique(labs)) == numel(labs), msg );
      %   make sure labels in overlapping categories do not share true
      %   elements
      cats = unique( cellfun(@(x) x.category, c, 'un', false) );
      for i = 1:numel(cats)
        matches_cat = any( cellfun(@(x) strcmp(x.category, cats{i}), c), 1 );
        current_cats = c( matches_cat );
        current_cat_inds = cellfun( @(x) x.index, current_cats, 'un', false );
        current_cat_inds = [ current_cat_inds{:} ];        
        if ( size(current_cat_inds, 2) == 1 ), continue; end;
        assert( ~any(all(current_cat_inds, 2)), msg );
      end
    end
    
    function arr = ensure_cell(arr)
      if ( ~iscell(arr) ), arr = { arr }; end;
    end
    
    function assert__is_cellstr_or_char( in )
      if ( ~ischar(in) )
        assert( iscellstr(in), ['Input must be a cell array of' ...
          , ' strings, or a char'] );
      end
    end
  end
end