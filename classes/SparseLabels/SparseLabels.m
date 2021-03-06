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
      
      %   SPARSELABELS -- Instantiate a SparseLabels object.
      %
      %     //  OVERVIEW
      %
      %     A SparseLabels object is used to identify observations of data.
      %
      %     A SparseLabels object has public properties 'labels', 
      %     'categories', and 'indices'.
      %
      %     'labels' is an Mx1 cell array of strings whose values are
      %     unique, and which form a set of identifiers that can be
      %     searched for.
      %
      %     'categories' is an Mx1 cell array of strings whose values 
      %     place each element (i) of 'labels' into a category.
      %
      %     'indices' is an NxM sparse logical array. Each column of
      %     'indices' is an index corresponding to the i-th element of
      %     'labels'. In other words, each column of 'indices' identifies
      %     rows described by the corresponding element of 'labels'.
      %
      %     SparseLabels objects aren't meant to be constructed directly
      %     (although they can be). A SparseLabels object is mainly used as
      %     a utility for a Container object.
      %
      %     //  INSTATIATION
      %
      %     obj = SparseLabels( labs ); where `labs` is a 1x1 struct whose
      %     fields are Mx1 cell arrays of strings, constructs a
      %     SparseLabels object `obj`. The fieldnames of `labs` become
      %     'categories' in `obj`. The unique strings in each field of
      %     `labs` become 'labels' in `obj`, and the logical index of each
      %     label in 'labels' with respect to the original field of `labs`
      %     becomes a column of 'indices' in `obj`.
      %
      %     obj = SparseLabels( arr ); constructs an object from a cell
      %     array `arr` of 1x1 struct with 'label', 'category', and 'index'
      %     fields.
      %
      %     obj = SparseLabels( labs ); constructs an object from the
      %     Labels object `labs`.
      %
      %     See also Container/Container, Labels/Labels
      %
      %     Ex. //
      %
      %     labs = struct( ...
      %         'county', {{'May_24'; 'Jun_30'}} ...
      %       , 'city', {{'NY'; 'LA'}} ...
      %     );
      %     obj = SparseLabels( labs );
      %     find( where(obj, 'NY') )
      %     find( where(obj, {'NY', 'May_24'}) )
      %     find( where(obj, {'NY', 'Jun_30'}) )
      %     contains( obj, 'NY' )
      %     contains( obj, {'NY', 'CA'} )
      
      if ( nargin < 1 ), return; end
      if ( isstruct(labs) )
        labs = SparseLabels.convert_struct_input_to_labels( labs );
      elseif ( iscell(labs) )
        SparseLabels.validate__cell_input( labs );
        obj.labels = cellfun( @(x) x.label, labs, 'un', false );
        obj.categories = cellfun( @(x) x.category, labs, 'un', false );
        indices = cellfun( @(x) x.index, labs, 'un', false );
        obj.indices = [ indices{:} ];
        obj.labels = obj.labels(:);
        obj.categories = obj.categories(:);
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
      obj.labels = labels(:);
      obj.categories = categories(:);
      obj.indices = sparse( indices );
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
      %       - `dim` (double) |OPTIONAL| -- dimension of the array of 
      %         labels to query. E.g., size(obj, 1).
      %     OUT:
      %       - `s` (double) -- Dimensions
      
%       if ( isempty(obj) ), s = [0 0]; else s = size( obj.indices ); end;
      s = size( obj.indices );
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
    
    function n = ncategories(obj)
      
      %   NCATEGORIES -- Obtain the number of unique categories in the
      %     object.
      %
      %     OUT:
      %       - `n` (double) |SCALAR|
      
      n = numel( unique(obj.categories) );
    end
    
    function n = nfields(obj)
      
      %   NFIELDS -- Alias for `ncategories()`.
      
      n = ncategories( obj );
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
    
    function un = get_uniform_fields(obj)
      
      %   GET_UNIFORM_FIELDS -- Alias for `get_uniform_categories()`.
      
      un = get_uniform_categories( obj );
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
    
    function non_un = get_non_uniform_fields(obj)
      
      %   GET_NON_UNIFORM_FIELDS -- Alias for
      %     `get_non_uniform_categories()`.
      
      non_un = get_non_uniform_categories( obj );
    end
    
    function obj = set_field(obj, cat, set_as, varargin)
      
      %   SET_FIELD -- Alias for `set_category` to match the syntax of a
      %     Labels object.
      %
      %     See `help SparseLabels/set_category` for more info.
      
      obj = set_category( obj, cat, set_as, varargin{:} );
    end
    
    function obj = set_category_cell(obj, cat, set_as, index)
      
      %   SET_CATEGORY_CELL -- Assign all or part of a given category to a
      %     given set of labels.
      %
      %     obj = set_category_cell( obj, 'rewards', {'high'; 'low'} )
      %     changes the contents of the category 'rewards' such that the
      %     first label in 'rewards' is 'high', and the second is
      %     'low'. In this case, the object's `indices` matrix must have
      %     2 rows.
      %
      %     obj = set_category_cell( ..., {'high; 'low'}, index ); places
      %     elements 'high' and 'low' in the locations specified by
      %     `index`. In this case, `index` must be a column-vector with the
      %     same number of rows as the object, and the sum of `index` must
      %     equal the number of to-be-assigned labels (in this example, 2).
      %
      %     See also SparseLabels/set_category
      %
      %     IN:
      %       - `cat` (char) -- Category to set.
      %       - `set_as` (cell array of strings) -- Labels to assign to the
      %         category.
      %       - `index` (logical) |OPTIONAL| -- Optionally specify the
      %         rows at which to place the elements of `set_as`.
      
      if ( nargin < 4 )
        index = rep_logic( obj, true );
      end
      Assertions.assert__is_cellstr( set_as );
      Assertions.assert__isa( cat, 'char' );
      assert__is_properly_dimensioned_logical( obj, index );
      nset = numel( set_as );
      if ( nset > 1 )
        assert( sum(index) == nset, ['If assigning more than one label,' ...
          , ' the number of true elements in the index must match the' ...
          , ' number of assigned-labels.'] );
      end
      unqs = unique( set_as );
      for i = 1:numel(unqs)
        val = unqs{i};
        index_ = index;
        ind = strcmp( set_as, val );
        index_( index_ ) = ind;
        obj = set_category( obj, cat, val, index_ );
      end
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
      else
        assert__is_properly_dimensioned_logical( obj, index );
      end
      %   return early if there are no true elements in the index.
      if ( ~any(index) ), return; end
      char_msg = 'Expected %s to be a char; was a ''%s''';
      assert( isa(cat, 'char'), char_msg, 'category name', class(cat) );
      if ( iscell(set_as) )
        obj = set_category_cell( obj, cat, set_as, index );
        return;
      else
        assert( isa(set_as, 'char'), char_msg, 'the labels-to-be-set' ... 
          , class(set_as) );
      end
      assert( contains_categories(obj, cat), ['The specified category ''%s''' ...
        , ' does not exist.'], cat );
      %   make sure we're not attempting to assign the collapsed expression
      %   for a given category to the wrong category.
      unq_cats = unique( obj.categories );
      clpsed_cat_names = cellfun( @(x) [obj.COLLAPSED_EXPRESSION, x] ...
        , unq_cats, 'un', false );
      matches_clpsed_cat = strcmp( clpsed_cat_names, set_as );
      if ( any(matches_clpsed_cat) )
        assert( strcmp(unq_cats(matches_clpsed_cat), cat), ['Cannot assign' ...
          , ' the collapsed expression for category ''%s'' to category' ...
          , ' ''%s''.'], unq_cats{matches_clpsed_cat}, cat );
      end
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
        current_cat = obj.categories{ current_ind };
        %   ensure we don't assign to a different category.
        assert( strcmp(current_cat, cat), ['Cannot assign the label' ...
          , ' ''%s'' to the category ''%s'' because it already exists' ...
          , ' in the category ''%s''.'], set_as, cat, current_cat );
        current = obj.indices(:, current_ind);
        obj.indices(:, current_ind) = current | index;
%         obj.indices(:, current_ind) = index;
      else
        obj.labels{end+1, 1} = set_as;
        obj.categories{end+1, 1} = cat;
        obj.indices(:, end+1) = index;
      end
      empties = ~any( obj.indices, 1 );
      if ( ~any(empties) ), return; end
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
      %     See also SparseLabels/contains_categories
      
      tf = contains_categories( obj, fs );
    end
    
    function obj = replace(obj, search_for, with)
      
      %   REPLACE -- Replace a given number of labels with a single label.
      %
      %     obj = replace( obj, {'NY', 'CT', 'NJ'}, 'east-coast' ) replaces
      %     'NY', 'CT', and 'NJ' with 'east-coast'.
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
      unq_cats = unique( cats );
      %   make sure the categories of the search terms are all the same.
      if ( numel(unq_cats) ~= 1 )
        error( ['Replacing the search term(s) with ''%s'' would place ''%s''' ...
          , ' in multiple categories.'], with, with );
      end
      %   make sure the replacement term is not a collapsed-expression for
      %   the wrong category.
      all_cats = unique( obj.categories );
      clpsed_expressions = cellfun( @(x) [obj.COLLAPSED_EXPRESSION, x] ...
        , all_cats, 'un', false );
      matches_clpsed = strcmp( clpsed_expressions, with );
      if ( any(matches_clpsed) )
        assert( strcmp(all_cats(matches_clpsed), unq_cats), ['Cannot assign' ...
          , ' the collapsed expression for category ''%s'' to category' ...
          , ' ''%s''.'], all_cats{matches_clpsed}, unq_cats{1} );
      end
      tf = contains( obj, with );
      %   if the object already contains the replace-with term, make sure
      %   its category is consistent with those of `search_for`, and add
      %   its index to the `lab_inds` array.
      if ( tf )
        current_ind = strcmp( obj.labels, with );
        categ = obj.categories( current_ind );
        assert( all(strcmp(unq_cats, categ)), ['The search term ''%s'' already' ...
          , ' exists in the category ''%s''; attempted to place ''%s'' in' ...
          , ' the category ''%s''.'], with, categ{1}, with, cats{1} );
        lab_inds = [ lab_inds, find(current_ind) ];
      end
      new_inds = any( obj.indices(:, lab_inds), 2 );
      obj.labels( lab_inds(1) ) = { with };
      obj.indices(:, lab_inds(1)) = new_inds;
      if ( numel(lab_inds) == 1 ), return; end
      %   remove category, labels, and indices associated with the
      %   duplicates
      obj.labels( lab_inds(2:end) ) = [];
      obj.categories( lab_inds(2:end) ) = [];
      obj.indices(:, lab_inds(2:end)) = [];
    end
    
    function obj = collapse(obj, cats)
      
      %   COLLAPSE -- Reduce a category to a single label.
      %
      %     obj = collapse( obj, 'cities' ) replaces all labels in the
      %     category 'cities' with the label 'all__cities'.
      %
      %     obj = collapse( obj, {'cities', 'states'} ) works as above,
      %     separately for 'cities' and 'states'.
      %
      %     IN:
      %       - `cats` (cell array of strings, char)
      
      obj = fast_collapse_( obj, cats );
%       cats = unique( SparseLabels.ensure_cell(cats) );
%       labs = cellfun( @(x) labels_in_category(obj, x)', cats, 'un', false );
%       for i = 1:numel(labs)
%         obj = replace( obj, labs{i}, [obj.COLLAPSED_EXPRESSION cats{i}] );
%       end
    end
    
    function obj = fast_collapse_(obj, cats)
      
      %   FAST_COLLAPSE_ -- Reduce a category to single label.
      %
      %     IN:
      %       - `cats` (cell array of strings, char)
      
      cats = SparseLabels.ensure_cell( cats );
      for i = 1:numel(cats)
        assert( ischar(cats{i}), 'Category name must be a char; was a %s.' ...
          , class(cats{i}) );
        ind = strcmp( obj.categories, cats{i} );
        assert( any(ind), 'The category ''%s'' does not exist.', cats{i} );
%         if ( sum(ind) == 1 ), continue; end
        obj.labels(ind) = [];
        obj.categories(ind) = [];
        obj.indices(:, ind) = [];
        lab = [ obj.COLLAPSED_EXPRESSION, cats{i} ];
        obj.labels{end+1} = lab;
        obj.categories{end+1} = cats{i};
        obj.indices(:, end+1) = true;
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
    
    function obj = add_field(obj, varargin)
      
      %   ADD_FIELD -- Alias for `add_category`.
      %
      %     See `help SparseLabels/add_category` for more info.
      
      obj = add_category( obj, varargin{:} );
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
      %       - `labs` (cell array of strings) |OPTIONAL| -- New labels to
      %         add. Must have the same number of elements as there are
      %         rows in the object. Cannot have any elements that are
      %         current `obj.labels`. If unset, all labels in the field
      %         will be 'collapsed'.
      %     OUT:
      %       - `obj` (SparseLabels) -- Object with the category added.
      
      assert( isa(name, 'char'), 'Category name must be a char; was a ''%s''' ...
        , class(name) );
      assert( ~contains_categories(obj, name), ['The category ''%s'' already' ...
        , ' exists in the object'], name );
      %   if no labels are given ...
      if ( nargin < 3 )
        labs = sprintf( '%s%s', obj.COLLAPSED_EXPRESSION, name );
      end
      labs = SparseLabels.ensure_cell( labs );
      assert( iscellstr(labs), 'Labels must be a cell array of strings' );
      if ( numel(labs) ~= 1 )
        assert( numel(labs) == shape(obj, 1), ['The number of inputted labels' ...
          , ' must match the current number of rows in the object'] );
      else labs = repmat( labs, shape(obj, 1), 1 );
      end
      exists = cellfun( @(x) any(strcmp(obj.labels, x)), unique(labs) );
      assert( ~any(exists), ['It is an error to insert duplicate labels ' ...
        , 'into the object.'] );
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
    
    function obj = rm_uniform_categories(obj)
      
      %   RM_UNIFORM_CATEGORIES -- Remove categories for which there is
      %     only one unique label present.
      
      cats = get_uniform_categories( obj );
      obj = rm_categories( obj, cats );
    end
    
    function obj = rm_uniform_fields(obj)
      
      %   RM_UNIFORM_FIELDS -- Alias for `rm_uniform_categories()`.
      %
      %     See also SparseLabels/rm_uniform_categories
      
      obj = rm_uniform_categories( obj );
    end
    
    function obj = rename_field(obj, varargin)
      
      %   RENAME_FIELD -- Alias for `rename_category`.
      %
      %     See also SparseLabels/rename_category
      
      obj = rename_category( obj, varargin{:} );
    end
    
    function obj = rename_category(obj, cat, to)
      
      %   RENAME_CATEGORY -- Replace category name with new name.
      %
      %     obj = rename_category( 'cities', 'city' ) replaces occurrences
      %     of 'cities' in obj.categories with 'city'.
      %
      %     An error is thrown if the old category name doesn't exist, or
      %     if the new category name already exists (and is not the same as
      %     the old category name).
      %
      %     IN:
      %       - `cat` (char) -- Category to replace.
      %       - `to` (char) -- New name.
      
      Assertions.assert__isa( cat, 'char' );
      Assertions.assert__isa( to, 'char' );
      if ( strcmp(cat, to) ), return; end
      ind = strcmp( obj.categories, cat );
      assert( any(ind), 'The category ''%s'' does not exist.', cat );
      ind2 = strcmp( obj.categories, to );
      assert( ~any(ind2), 'The category ''%s'' already exists.', to );
      obj.categories( ind ) = { to };
    end
    
    %{
        INDEXING
    %}
    
    function [obj, ind] = only(obj, selectors)
      
      %   ONLY -- Retain rows that match labels.
      %
      %     newobj = only( obj, 'NY' ) returns a SparseLabels object with
      %     rows that match 'NY'. If 'NY' is not present in `obj`, `newobj`
      %     is empty.
      %
      %     [newobj, ind] = ... also returns the index used to select rows
      %     of `obj`.
      %
      %     See also SparseLabels/where
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
    
    function [obj, ind] = only_substr(obj, substrs)
      
      %   ONLY_SUBSTR -- retain the labels that match the substrs in
      %     `substrs`.
      %
      %     IN:
      %       - `substrs` (cell array of strings, char)
      %     OUT:
      %       - `obj` (SparseLabels) -- object with only the labels
      %         containing `substrs`.
      %       - `ind` (logial) |SPARSE| -- the index used to select labels
      %         in the outputted object.
      
      ind = where_substr( obj, substrs );
      obj = keep( obj, ind );
    end
    
    function obj = keep(obj, ind)
      
      %   KEEP -- Retain rows at which an index is true.
      %
      %     newobj = keep( obj, [true; false] ), where `obj` is a 2xN
      %     SparseLabels object, returns a new object containing the first
      %     row of `obj`.
      %
      %     See also SparseLabels/only
      %
      %     IN:
      %       - `ind` (logical) |COLUMN VECTOR| -- index of elements to 
      %         retain. numel( `ind` ) must equal shape(obj, 1).
      
      if ( ~obj.IGNORE_CHECKS )
        assert__is_properly_dimensioned_logical( obj, ind );
        if ( ~issparse(ind) ), ind = sparse( ind ); end
      end
      obj.indices = obj.indices(ind, :);
      empties = ~any( obj.indices, 1 )';
      obj.labels(empties) = [];
      obj.categories(empties) = [];
      obj.indices(:, empties) = [];
    end
    
    function obj = one(obj)
      
      %   ONE -- Obtain a single row.
      %
      %     newobj = one( obj ); returns a 1xN SparseLabels whose 
      %     labels are like those of `obj`, except that the non-uniform 
      %     fields of `obj` are collapsed.
      %
      %     See also SparseLabels/keep
      
      obj = collapse_non_uniform( obj );
      obj = numeric_index( obj, 1 );
    end
    
    function obj = numeric_index(obj, ind)
      
      %   NUMERIC_INDEX -- Apply a numeric index to the object.
      %
      %     obj = numeric_index( obj, [2; 3; 4] ) returns an object whose
      %     indices contain the 2nd, 3rd, and 4th rows of the inputted
      %     object.
      %
      %     IN:
      %       - `ind` (double) |VECTOR|
      
      assert__is_valid_numeric_index( obj, ind );
      obj.indices = obj.indices( ind, : );
      obj = remove_empty_indices( obj );
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
    
    function obj = remove_empty_indices(obj)
      
      %   REMOVE_EMPTY_INDICES -- Remove indices, labels, and categories
      %   	for which there are no true elements of indices.
      
      empties = ~any( obj.indices, 1 );
      if ( ~any(empties) ), return; end
      obj.labels(empties) = [];
      obj.categories(empties) = [];
      obj.indices(:, empties) = [];
    end
    
    function [full_index, cats] = where(obj, selectors)
      
      %   WHERE -- Return an index of labels.
      %
      %     I = where( obj, 'NY' ) returns an Mx1 logical index that is 
      %     true for rows that match 'NY'.
      %
      %     I = where( obj, {'NY', 'LA'} ), where 'NY' and 'LA' are labels
      %     in the same category, returns an index that is true for rows
      %     that match 'NY' OR 'LA'.
      %
      %     I = where( obj, {'NY', 'LA', 'low-income'} ), where 'NY' and
      %     'LA' are labels in the same category, but 'low-income' is a
      %     label in a different category, returns an index that is true
      %     for rows that match 'low-income' AND ('NY' OR 'LA').
      %
      %     [I, C] ... also returns the categories in which each
      %     `selectors` resides. If a selector is not found, its category
      %     will be -1.
      %
      %     See also SparseLabels/only, SparseLabels/get_indices
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
      if ( isempty(selectors) ), return; end
      inds = false( shape(obj,1), numel(selectors) );
      for i = 1:numel(selectors)
        label_ind = strcmp( obj.labels, selectors{i} );
        if ( ~any(label_ind) ), all_false = true; cats{i} = -1; continue; end
        inds(:,i) = obj.indices( :, label_ind );
        cats(i) = obj.categories( label_ind  );
      end
      if ( all_false ), return; end
      unqs = unique( cats );
      n_unqs = numel( unqs );
      if ( n_unqs == numel(cats) )
        full_index = sparse( all(inds, 2) ); return; 
      end
      full_index(:) = true;
      for i = 1:n_unqs
        current = inds( :, strcmp(cats, unqs{i}) );
        full_index = full_index & any(current, 2);
        if ( ~any(full_index) ), full_index = sparse(full_index); return; end
      end
      full_index = sparse( full_index );
    end
    
    function [ind, cats] = where_substr(obj, substrs)
      
      %   WHERE_SUBSTR -- obtain a row index associated with labels that
      %     contain the substr or substr(s)
      %
      %     IN:
      %       - `substrs` (cell array of strings, char) -- Desired
      %         substrings.
      %     OUT:
      %       - `full_index` (logical) |COLUMN| -- Index of which rows
      %         correspond to the `substrs`.
      %       - `cats` (cell array) -- The category associated with
      %         the found `substrs`(i)
      
      substrs = SparseLabels.ensure_cell( substrs );
      assert( iscellstr(substrs), ['Substrs must be a cell array of strings,' ...
        , ' or a char'] );
      labs = obj.labels;
      to_keep = cellfun( @(x) all(cellfun(@(y) ~isempty(strfind(x, y)), substrs)) ...
        , labs );
      [ind, cats] = where( obj, labs(to_keep) );
    end
    
    function inds = find_labels(obj, labs)
      
      %   FIND_LABELS -- Obtain the index of the given labels in the
      %     obj.labels array.
      %
      %     An error is thrown if any of the labels in `labs` are not
      %     found.
      %
      %     IN:
      %       - `labs` (cell array of strings, char)
      %     OUT:
      %       - `inds` (double) -- Numeric indices.
      
      labs = SparseLabels.ensure_cell( labs );
      cellfun( @(x) assert(contains(obj, x), 'Could not find ''%s''.' ...
        , x), labs, 'un', false );
      inds = cellfun( @(x) find(strcmp(obj.labels, x)), labs );
    end
    
    %{
        ITERATION
    %}
    
    function c = combs(obj, cats)
      
      %   COMBS -- Return all possible combinations of labels.
      %
      %     IN:
      %       - `cats` (cell array of strings, char) |OPTIONAL| --
      %         Categories which to draw unique labels. If unspecified,
      %         uses all unique categories in the object.
      %     OUT:
      %       - `c` (cell array of strings) -- Cell array of strings in
      %         which each column c(:,i) contains labels in category
      %         `cats(i)`, and each row a unique combination of labels.
      
      if ( nargin < 2 ), cats = unique( obj.categories ); end
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
      %     by get_indices(), it is guaranteed that the object will not be 
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
    
    function [I, C] = fget_indices(obj, cats)
      
      cats = SparseLabels.ensure_cell( cats );
      arr = zeros( [size(obj.indices, 1), numel(cats)], 'uint32' );
      offset = 0;
      
      map = multimap();
      
      for i = 1:numel(cats)
        cat = cats{i};
        cat_ind = strcmp( obj.categories, cat );
        
        if ( ~any(cat_ind) )
          error( 'The category "%s" does not exist.', cat );
        end
        
        labs = obj.labels( cat_ind );
        for j = 1:numel(labs)
          ind = strcmp( obj.labels, labs{j} );
          lab_id = uint32( j + offset );
          arr( obj.indices(:, ind), i ) = lab_id;
          set( map, labs{j}, lab_id );
        end
        offset = offset + j;
      end
      
      [num_c, ~, ib] = unique( arr, 'rows' );
      I = accumarray( ib, uint64((1:numel(ib))'), [], @(rows) {sort(rows)} );
      
      N = shape( obj, 1 );
      
      I = fast_assign_true( I, N );
      
      if ( nargout == 1 )
        destroy( map );
        return;
      end
      
      C = get( map, num_c );
      
      destroy( map );
    end
    
    function [I, C] = rget_indices(obj, cats)
      
      %   RGET_INDICES -- Get indices of label combinations, recursively.
      %
      %     I = rget_indices( obj, 'cities' ); returns the index of each
      %     label in 'cities'.
      %
      %     I = rget_indices( obj, {'cities', 'states'} ); returns the
      %     index of each combination of labels in 'cities' and 'states'.
      %
      %     [I, C] = ... also returns the combinations of labels in the
      %     given categories associated with each index. `C` is an MxN cell
      %     array of M label combinations by N categories. Each row of C
      %     corresponds to each row of I.
      %
      %     See also SparseLabels/where, SparseLabels/only,
      %     SparseLabels/keep
      %
      %     IN:
      %       - `cats` (cell array of strings, char)
      %     OUT:
      %       - `I` (cell array of logical)
      %       - `C` (cell array of strings)
      
      cats = SparseLabels.ensure_cell( cats );
      cellfun( @(x) assert(any(strcmp(obj.categories, x)), ...
        'The category ''%s'' does not exist.', x), cats );
      
      if ( numel(cats) == 1 )
        %   we can do a faster version if there's only category
        [I, C] = one_cat( obj, cats );
        return;
      end
      
      ind = true( shape(obj, 1), 1 );
      N = numel( cats );
      %   guess a preallocation amount of 500
      I = cell( 500, 1 );
      C = cell( 500, N );
      istp = 1;
      cstp = 0;
      row = cell( 1, N );
      
      get_indices_( obj, ind, cats );
      
      I = I(1:istp-1);
      C = C(1:istp-1, :);
      
      %   - subroutines
      
      function get_indices_(obj, ind, cats)
        if ( isempty(cats) )
          I{istp, 1} = ind;
          C(istp, :) = row;
          istp = istp + 1;
          return;
        end
        [inds, unqs] = enumerate_( obj, cats(1) );
        cats(1) = [];
        cstp = cstp + 1;
        for i = 1:size(inds, 2)
          ind_ = ind;
          ind_( ind_ ) = inds(:, i);
          row{cstp} = unqs{i};
          get_indices_( fast_keep_(obj, inds(:, i)), ind_, cats );
        end
        cstp = cstp - 1;
      end
      function [I, C] = one_cat(obj, category)
        [inds, C] = enumerate_(obj, category);
        C = C(:);
        I = cell( size(inds, 2), 1 );
        for i = 1:size(inds, 2)
          I{i} = inds(:, i);
        end
      end
      function [inds, unqs] = enumerate_(obj, cat)
        unqs = obj.labels( strcmp(obj.categories, cat) );
        ninds = cellfun( @(x) find(strcmp(obj.labels, x)), unqs );
        inds = obj.indices( :, ninds );
      end
      function obj = fast_keep_(obj, ind)
        obj.indices = obj.indices( ind, : );
        empties = ~any( obj.indices, 1 );
        obj.labels( empties ) = [];
        obj.categories( empties ) = [];
        obj.indices( :, empties ) = [];
      end
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
      if ( ~shapes_match(obj, B) ), return; end
      if ( ~categories_match(obj, B) ), return; end
      if ( ~labels_match(obj, B) ), return; end
      obj = sort_labels( obj );
      B = sort_labels( B );
      tf = isequal( obj.indices, B.indices );
    end
    
    function tf = ne(obj, B)
      tf = ~eq(obj, B);
    end
    
    function tf = eq_non_uniform(obj, B)
      
      %   EQ_NON_UNIFORM -- Determine equality, disregarding
      %     uniform-categories.
      %
      %     Uniform categories are those which have only a single label,
      %     whose index is true for all rows of `obj.indices`.
      %
      %     IN:
      %       - `B` (/any/) -- Values to test.
      
      tf = false;
      if ( ~isa(B, 'SparseLabels') ), return; end
      if ( eq(obj, B) ), tf = true; return; end
      if ( ~categories_match(obj, B) ), return; end
      n1 = shape( obj, 1 );
      n2 = shape( B, 1 );
      if ( n1 ~= n2 ), return; end
      cats_a = get_non_uniform_categories( obj );
      cats_b = get_non_uniform_categories( B );
      if ( ~isequal(sort(cats_a), sort(cats_b)) ), return; end
      if ( isempty(cats_a) ), tf = true; return; end
      others_a = setdiff( unique(obj.categories), cats_a );
      others_b = setdiff( unique(B.categories), cats_b );
      A = rm_categories( obj, others_a );
      B = rm_categories( B, others_b );
      tf = eq( A, B );
    end
    
    function tf = eq_ignoring(obj, B, cats)
      
      %   EQ_IGNORING -- Determine equality, ignoring some categories.
      %
      %     eq_ignoring( obj, B, 'cities' ) returns true if SparseLabels
      %     objects `obj` and `B` are equivalent after removing the
      %     category 'cities'.
      %
      %     IN:
      %       - `obj` (SparseLabels)
      %       - `B` (SparseLabels)
      %       - `cats` (cell array of strings, char) -- Categories to
      %         ignore.
      %     OUT:
      %       - `tf` (logical)
      
      tf = false;
      if ( ~isa(obj, 'SparseLabels') || ~isa(B, 'SparseLabels') ), return; end
      obj = rm_categories( obj, cats );
      B = rm_categories( B, cats );
      tf = eq( obj, B );
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
      if ( ~isa(B, 'SparseLabels') ), return; end
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
      if ( ~isa(B, 'SparseLabels') ), return; end
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
      if ( ~isa(B, 'SparseLabels') ), return; end
      tf = isequal( shape(obj), shape(B) );
    end
    
    function tf = labels_match(obj, B)
      
      %   LABELS_MATCH -- Check if the labels in two `SparseLabels` objects
      %     are equivalent.
      %
      %     Note that the ordering of labels is intentionally not tested.
      
      tf = false;
      if ( ~isa(B, 'SparseLabels') ), return; end
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
      
      if ( isempty(obj) ), new = B; return; end
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
        other_category_inds = cellfun( @(x) find(strcmp(B.labels, x)) ...
          , shared_labs );
        other_shared_inds = B.indices( :, other_category_inds );
        own_category_inds = ...
          cellfun( @(x) find(strcmp(obj.labels, x)), shared_labs );
        %
        %   new: shared labels must reside in the same category
        %
        assert( all(strcmp(obj.categories(own_category_inds) ...
          , B.categories(other_category_inds))), ['Shared labels must' ...
          , ' reside in the same category.'] );
        %
        %   end new
        % 
        new.indices( own_rows+1:end, own_category_inds ) = other_shared_inds;
      end
      if ( ~isempty(other_labs) )
        other_label_inds = cellfun(@(x) find(strcmp(B.labels, x)), other_labs);
        other_inds = B.indices( :, other_label_inds );
        new.indices( own_rows+1:end, own_cols+1:end ) = other_inds;
        new.labels(end+1:end+n_other, 1) = other_labs;
        new.categories(end+1:end+n_other, 1) = B.categories( other_label_inds );
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
      if ( ~issparse(index) ), index = sparse( index ); end
      assert( categories_match(obj, B), 'Categories do not match between objects' );
      shared = intersect( obj.labels, B.labels );
      others = setdiff( B.labels, obj.labels );
      if ( ~isempty(shared) )
        own_inds = cellfun( @(x) find(strcmp(obj.labels, x)), shared );
        other_inds = cellfun( @(x) find(strcmp(B.labels, x)), shared );
        obj.indices(index, own_inds) = B.indices( :, other_inds );
      end
      if ( ~isempty(others) )
        new_inds = repmat( rep_logic(obj, false), 1, numel(others) );
        other_inds = cellfun( @(x) find(strcmp(B.labels, x)), others );
        new_inds(index,:) = B.indices(:, other_inds);
        obj.indices = [obj.indices new_inds];
        obj.labels = [obj.labels; B.labels(other_inds)];
        obj.categories = [obj.categories; B.categories(other_inds)];
      end
      obj = remove_empty_indices( obj );
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
    
    function disp(obj, display_size)
      
      %   DISP -- print the categories and labels in the object, and 
      %     indicate the frequency of each label.
      
      if ( nargin < 2 ), display_size = true; end
      if ( obj.VERBOSE )
        disp1( obj );
      else
        disp2( obj, display_size );
      end
    end
    
    function disp1(obj)
      
      %   DISP1 -- Display categories, labels, and label-frequencies as a
      %     single column.
      
      [unqs, cats] = uniques( obj );
      desktop_exists = usejava( 'desktop' );
      for i = 1:numel(cats)
        current = unqs{i};
        if ( desktop_exists )
          fprintf( '\n  - <strong>%s</strong>', cats{i} );
        else fprintf( '\n  - %s', cats{i} );
        end
        if ( obj.VERBOSE )
          nprint = numel( current );
        else nprint = min( [obj.MAX_DISPLAY_ITEMS, numel(current)] );
        end
        for j = 1:nprint
          ind = get_index( obj, current{j} );
          N = full( sum(ind) );
          fprintf( '\n     - %s (%d)', current{j}, N );
        end
        remaining = numel(current) - j;
        if ( remaining > 0 )
          fprintf( '\n     - ... and %d others', remaining );
        end
      end
      fprintf( '\n\n' );
    end
    
    function disp2(obj, display_size)
      
      %   DISP2 -- Display categories, labels, and label-frequencies in
      %     multiple columns.
      
      if ( nargin < 2 ), display_size = true; end
      all_labs = obj.labels;
      cats = obj.categories;
      inds = obj.indices;
      unq_cats = unique( cats );
      maxn = obj.MAX_DISPLAY_ITEMS;
      maxchars = 15;
      maxcols = 2;
      spc = ' ';
      nspaces = 1;
      all_joined = cell( numel(unq_cats), 1 );
      all_longest = cell( size(all_joined) );
      desktop_exists = usejava( 'desktop' );
      for i = 1:numel(unq_cats)
        curr_cat = unq_cats{i};
        labs = all_labs( strcmp(cats, curr_cat) );
        N = min( numel(labs), maxn );
        remaining = numel( labs ) - N;
        did_truncate = remaining > 0;
        labs = labs(1:N);
        for j = 1:N
          curr = labs{j};
          ct = sum( inds(:, strcmp(all_labs, curr)) );
          if ( numel(curr) > maxchars )
            curr = sprintf( '%s..', curr(1:maxchars) );
          end
          labs{j} = sprintf( '  - %s (%d)', curr, full(ct) );
        end
        if ( did_truncate )
          labs{end} = sprintf( '  - ... and %d others', remaining+1 );
        end
        rows = ceil( N/maxcols );
        items = cell( rows, maxcols );
        items( cellfun(@isempty, items) ) = {''};
        items(1:N) = labs;
        store_longest = zeros( 1, size(items, 2)-1 );
        for j = 2:size(items, 2)
          longest = max( cellfun(@numel, items(:, j-1)) );
          store_longest(j-1) = longest;
          for k = 1:size(items, 1)
            item = items{k, j-1};
            items{k, j-1} = [item, repmat(spc, 1, longest-numel(item))];
          end
        end
        all_joined{i} = items;
        all_longest{i} = store_longest;
      end
      longest = max( cell2mat(all_longest), [], 1 );
      for i = 1:numel(longest)
        for j = 1:numel(all_longest)
          col = all_joined{j}(:, i);
          ns = cellfun( @numel, col );
          for k = 1:numel(col)
            addtl = longest(i) - ns(k);
            col{k} = [ col{k}, repmat(spc, 1, addtl) ];
          end
          all_joined{j}(:, i) = col;
        end
      end
      if ( display_size )
        if ( desktop_exists )
          sz_str = sprintf( '%d�%d', size(obj.indices, 1), size(obj.indices, 2) );
          link_str = sprintf( '<a href="matlab:helpPopup %s">%s</a>' ...
            , class(obj), class(obj) );
        else
          sz_str = sprintf( '%d-by-%d', size(obj.indices, 1) ...
            , size(obj.indices, 2) );
          link_str = class( obj );
        end
        fprintf( '\n  %s %s with items:\n', sz_str, link_str );
      end
      if ( desktop_exists )
        base_str = '\n  <strong>%s</strong>';
      else
        base_str = '\n  %s';
      end
      for i = 1:numel(unq_cats)
        str = sprintf( base_str, unq_cats{i} );
        fprintf( '%s', str );
        for j = 1:size(all_joined{i}, 1)
          joined = strjoin( all_joined{i}(j, :), repmat(spc, 1, nspaces) );
          fprintf( '\n  %s', joined );
        end
      end
      fprintf( '\n\n' );
    end
    
    function obj = columnize(obj)
      
      %   COLUMNIZE -- Ensure the labels and categories in the object are
      %     stored row-wise.
      
      obj.labels = obj.labels(:);
      obj.categories = obj.categories(:);
    end
    
    function obj = full(obj)
      
      %   FULL -- Convert the SparseLabels object to a full Labels object.
      %
      %     IN:
      %       - `obj` (SparseLabels) -- Object to convert.
      %     OUT:
      %       - `obj` (Labels) -- Converted Labels object.
      
      if ( isempty(obj) ), obj = Labels(); return; end
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
      
      if ( isempty(obj) ), log = tf; return; end
      if ( tf )
        log = sparse( true(shape(obj, 1), 1) );
      else
        log = sparse( false(shape(obj, 1), 1) );
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
        CONVERSION
    %}
    
    function [arr, arranged_labs, cats] = numeric_array(obj, kind)
      
      %   NUMERIC_ARRAY -- Convert the object to a numeric array.
      %
      %     This function is the generalized form of conversion functions
      %     like double().
      %
      %     See also SparseLabels/double
      %
      %     IN:
      %       - `kind` (char) -- Class of numeric data.
      %     OUT:
      %       - `arr` (/kind/) -- Numeric array.
      %       - `arranged_labs` (cell array of strings)
      %       - `cats` (cell array of strings)
      
      cats = unique( obj.categories );
      arranged_labs = cell( numel(obj.labels), 1 );
      arr = zeros( [size(obj.indices, 1), numel(cats)], kind );
      offset = 0;
      for i = 1:numel(cats)
        cat = cats{i};
        labs = obj.labels( strcmp(obj.categories, cat) );
        for j = 1:numel(labs)
          ind = strcmp( obj.labels, labs{j} );
          arr( obj.indices(:, ind), i ) = j+offset;
          arranged_labs{j+offset} = labs{j};
        end
        offset = offset + j;
      end
    end
    
    function [arr, labs, cats] = double(obj)
      
      %   DOUBLE -- Convert the object to a double array.
      %
      %     A = double( obj ); returns a double array A whose columns are
      %     categories and rows the integer representations of the labels
      %     in those categories.
      %
      %     [A, labs] = double( obj ); also returns the cell array of
      %     labels whose ordering corresponds to their identity in A.
      %
      %     [A, labs, cats] = ... also returns the category names in the
      %     the same order as the columns of A.
      %
      %     See also SparseLabels/categorical
      %
      %     OUT:
      %       - `arr` (double) -- Numeric array.
      %       - `labs` (cell array of strings)
      %       - `cats` (cell array of strings)
      
      [arr, labs, cats] = numeric_array( obj, 'double' );
    end
    
    function [arr, labs, cats] = categorical(obj)
      
      %   CATEGORICAL -- Convert the object to a categorical array.
      %
      %     See also SparseLabels/double
      %
      %     OUT:
      %       - `arr` (/kind/) -- Numeric array.
      %       - `labs` (cell array of strings)
      %       - `cats` (cell array of strings)
      
      [arr, labs, cats] = double( obj );
      arr = categorical( arr );
    end
    
    function s = label_struct(obj)
      
      %   LABEL_STRUCT -- Convert the object to a struct.
      %
      %     OUT:
      %       - `s` (struct)
      
      s = struct();
      s.indices = obj.indices;
      s.categories = obj.categories;
      s.labels = obj.labels;
    end
    
    function [m, f] = label_mat(obj)
      
      %   LABEL_MAT -- Convert the object to cellstr matrix.
      %
      %     OUT:
      %       - `m` (cellstr)
      %       - `f` (cellstr) -- Field names.
      
      labs = full( obj );
      m = labs.labels;
      f = labs.fields;
    end
    
    %{
        GET/SET
    %}
    
    function val = get_collapsed_expression(obj)
      
      %   GET_COLLAPSED_EXPRESSION -- Return the COLLAPSED_EXPRESSION prop.
      %
      %     OUT:
      %       - `val` (char)
      
      val = obj.COLLAPSED_EXPRESSION;
    end
    
    function obj = set_collapsed_expression(obj, val)
      
      %   SET_COLLAPSED_EXPRESSION -- Set the COLLAPSED_EXPRESSION prop.
      %
      %     IN:
      %       - `val` (char)
      %     OUT:
      %       - `obj` (Container) -- Mutated object.
      
      assert( ischar(val) && ~isempty(val), ['Collapsed expression must' ...
        , ' be a non-empty char; was a ''%s''.'], class(val) );
      obj.COLLAPSED_EXPRESSION = val;
    end
    
    %{
        OBJECT SPECIFIC ASSERTIONS
    %}
    
    function assert__is_valid_numeric_index(obj, ind)
      
      %   ASSERT__IS_VALID_NUMERIC_INDEX
      
      Assertions.assert__isa( ind, 'double' );
      max_n = shape( obj, 1 );
      msg = sprintf( ['Expected the numeric' ...
        , ' index to be a double vector whose elements are greater than 0' ...
        , ' and less than %d.'], max_n );
      assert( isvector(ind), msg );
      assert( all(ind > 0) && all(ind <= max_n), msg );
    end
    
    function assert__is_properly_dimensioned_logical(obj, B, opts)
      if ( nargin < 3 )
        opts.msg = sprintf( ['The index must be a column vector with the same number' ...
          , ' of rows as the object (%d). The inputted index had (%d) elements.'] ...
          , shape(obj, 1), numel(B) );
      end
      assert( islogical(B), opts.msg );
      assert( iscolumn(B), opts.msg );
      assert( size(B, 1) == shape(obj, 1), opts.msg );
    end
    
    function assert__categories_exist(obj, B, opts)
      if ( nargin < 3 )
        opts.msg = 'The requested category ''%s'' is not in the object.';
      end
      cats = unique( obj.categories );
      B = SparseLabels.ensure_cell( B );
      cellfun( @(x) assert(any(strcmp(cats, x)), opts.msg, x), B );
    end
    
    function assert__contains_fields(obj, varargin)
      assert__categories_exist( obj, varargin{:} );
    end
    
    function assert__contains_labels(obj, B)      
      B = SparseLabels.ensure_cell( B );
      Assertions.assert__is_cellstr( B );
      cellfun( @(x) assert(contains(obj, x), ['There is no ''%s''' ...
        , ' label in the object.'], x), B );
    end
    
    function assert__categories_match(obj, B, opts)
      if ( nargin < 3 )
        opts.msg = 'The categories do not match between objects';
      end
      assert( isa(B, 'SparseLabels'), ['This operation requires a SparseLabels' ...
        , ' as input; input was a ''%s''.'], class(B) );
      assert( categories_match(obj, B), opts.msg );
    end
  end
  
  methods (Static = true)
    
    function obj = create(varargin)
      
      %   CREATE -- Create a SparseLabels object from field, label pairs.
      %
      %     sp = SparseLabels.create( 'cities', {'NY', 'Chicago'} )
      %     constructs a SparseLabels object `sp` with the category
      %     'cities', containing the labels 'NY' and 'Chicago'. 'NY'
      %     is associated with the first row of `sp`, and 'Chicago' the
      %     second.
      %
      %     sp = SparseLabels.create( ...
      %         'cities', {'ny', 'la'} ...
      %       , 'countries', 'usa' ...
      %     )
      %
      %     Works as above, but also creates the category 'countries',
      %     whose single label 'usa' identifies both rows of `sp`.   
      %
      %     See also Container/create, SparseLabels/SparseLabels
      %
      %     IN:
      %       - `varargin` ('field', {'label1'})
      %     OUT:
      %       - `obj` (SparseLabels)
      
      narginchk( 2, Inf );
      labs = varargin;
      assert( mod(numel(labs)/2, 1) == 0 ...
        , '(field, {labels}) pairs are incomplete.' );
      fs = labs(1:2:end);
      cellfun( @(x) Assertions.assert__isa(x, 'char'), fs );
      labels = labs(2:2:end);
      labels = cellfun( @(x) Labels.ensure_cell(x), labels, 'un', false );
      cellfun( @(x) Assertions.assert__is_cellstr(x), labels );
      szs = cellfun( @(x) numel(x), labels );
      unq_sizes = unique( szs );
      if ( numel(unq_sizes) > 1 )
        is_one = unq_sizes == 1;
        assert( numel(unq_sizes) == 2 && any(is_one), ['The number' ...
          , ' of labels in each category must match across categories,' ...
          , ' unless there is only one label in the category.'] );
        sz = unq_sizes( ~is_one );
      else
        sz = unq_sizes;
      end
      for i = 1:numel(labels)
        lab = labels{i};
        if ( numel(lab) ~= sz )
          labels{i} = repmat( lab, sz, 1 );
        end
      end
      labels = cellfun( @(x) x(:), labels, 'un', false );
      obj = SparseLabels( cell2struct(labels, fs, 2) );
    end
    
    function s = from_fcat(f)
      
      %   FROM_FCAT -- Convert to SparseLabels from fcat.
      %
      %     IN:
      %       - `f` (fcat)
      %     OUT:
      %       - `s` (SparseLabels)
      
      assert( isa(f, 'fcat'), 'Input must be an fcat; was "%s".', class(f) );
      
      f = prune( copy(f) );
      c = getcats( f );
      l = getlabs( f );
      
      inds = false( size(f, 1), numel(l) );
      cats = cell( numel(l), 1 );
      labs = l(:);
      
      for i = 1:numel(c)
        c_labs = incat( f, c{i} );
        
        for j = 1:numel(c_labs)
          lab = c_labs{j};
          lab_ind = strcmp( labs, lab );
          inds(find(f, lab), lab_ind) = true;
          cats{lab_ind} = c{i};
        end
      end
      
      s = SparseLabels();
      s.indices = sparse( inds );
      s.labels = labs;
      s.categories = cats;
    end
    
    function obj = from_label_struct(s)
      
      %   FROM_LABEL_STRUCT -- Instantiate a SparseLabels object from a
      %     struct with labels, categories, and indices fields.
      %
      %     IN:
      %       - `s` (struct)
      %     OUT:
      %       - `obj` (SparseLabels)
      
      assert( isa(s, 'struct'), 'Input must be struct; was "%s".', class(s) );
      required_fields = { 'labels', 'indices', 'categories' };
      for i = 1:numel(required_fields)
        if ( ~isfield(s, required_fields{i}) )
          error( 'Invalid struct input: missing field "%s".', required_fields{i} );
        end
      end
      assert( iscellstr(s.labels), '"labels" field must be a cell array of strings.' );
      assert( iscellstr(s.categories), '"categories" field must be a cell array of strings.' );
      assert( isa(s.indices, 'logical'), '"indices" field must be a logical array.' );
      assert( numel(s.labels) == numel(s.categories), ['Number of "categories"' ...
        , ' must match number of "labels".'] );
      assert( size(s.indices, 2) == numel(s.categories), ['Number of "categories"' ...
        , ' must match the number of columns in "indices".'] );
      %   we're ok!
      obj = SparseLabels();
      obj.labels = s.labels(:);
      obj.categories = s.categories(:);
      obj.indices = sparse( s.indices );
    end
    
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