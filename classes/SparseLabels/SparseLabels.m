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
  end
  
  methods
    function obj = SparseLabels(labs)
      if ( nargin < 1 ), return; end;
      if ( isstruct(labs) )
        labs = SparseLabels.convert_struct_input_to_labels( labs );
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
        assert( iscellstr(cats), ['Categories must be a cell array of' ...
          , ' strings, or a char'] );
      end
      unqs = cell( 1, numel(cats) );
      for i = 1:numel(cats)
        unqs{i} = labels_in_category( obj, cats{i} );
      end
    end
    
    function tf = contains(obj, labels)
      
      %   CONTAINS -- Obtain an index of whether the given label(s) are
      %     present in the `obj.labels` cell array.
      %
      %     IN:
      %       - `labels` (cell array of strings, char) -- Label(s) to test.
      %     OUT:
      %       - `tf` (logical) -- Vector of true/false values where each
      %       `tf`(i) corresponds to each `labels`(i).
      
      labels = SparseLabels.ensure_cell( labels );
      assert( iscellstr(labels), ['Inputted label must be a cell array of' ...
        , ' strings, or a char'] );
      tf = cellfun( @(x) any(strcmp(obj.labels, x)), labels );
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
      end
      obj.indices = obj.indices(ind, :);
      obj = rehash( obj );
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
        cats{i} = obj.categories{ label_ind  };
      end
      if ( all_false ), return; end;
      unqs = unique( cats );
      n_unqs = numel( unqs );
      if ( n_unqs == numel(cats) )
        full_index = sparse( all(inds, 2) ); 
        return; 
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
        REHASHING
    %}
    
    function obj = rehash(obj)
      
      %   REHASH -- Remove the labels(i), categories(i) and indices(i) for
      %     which there are no true elements in indices(i).
      %
      %     Note that calls to `rehash` can leave the object empty.
      
      empties = ~any( obj.indices )';
      obj.labels(empties) = [];
      obj.categories(empties) = [];
      obj.indices(:, empties) = [];
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
    
    function tf = categories_match(obj, B)
      
      %   CATEGORIES_MATCH -- Determine whether the comparitor is a
      %     SparseLabels object with equivalent categories.
      %
      %     Note that equivalent in this context means that the unique
      %     categories in each object are the same.
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
    
    %{
        INTER-OBJECT HANDLING
    %}
    
    function new = append(obj, B)
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
        new.categories(end+1:end+n_other) = other_labs;
        new.labels(end+1:end+n_other) = B.categories( other_label_inds );
      end
    end
    
    function new = append2(obj, B)
      
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
      tic;
      if ( isempty(obj) ), new = B; return; end;
      assert__categories_match( obj, B );
      b_labs = B.labels;
      own_labs = obj.labels;
      own_rows = shape( obj, 1 );
      own_cols = shape( obj, 2 );
      b_rows = shape( B, 1 );
      shared = intersect( b_labs, own_labs );
      new = obj;
      new.indices = false( own_rows + b_rows, own_cols );
      if ( ~isempty(shared) )
        own_inds = cellfun( @(x) find(strcmp(obj.labels, x)), shared );
        b_inds = cellfun( @(x) find(strcmp(B.labels, x)), shared );
        new.indices( :, own_inds ) = [obj.indices(:, own_inds); B.indices(:, b_inds)];
        own_labs = setdiff( own_labs, shared );
        b_labs = setdiff( b_labs, shared );
      end
      if ( isempty(own_labs) && isempty(b_labs) )
        new.indices = sparse( new.indices );
        return; 
      end
      if ( ~isempty(own_labs) )
        inds = cellfun( @(x) find(strcmp(obj.labels, x)), own_labs );
        new.indices(1:own_rows, inds) = obj.indices(:, inds);
      end
      if ( isempty(b_labs) ), new.indices = sparse( new.indices ); return; end;
      inds = cellfun( @(x) find(strcmp(B.labels, x)), b_labs );
      cols = numel( new.labels );
      new_cols = numel(inds);
      new.indices(:, cols+1:cols+new_cols) = false;
      new.indices(own_rows+1:end, cols+1:cols+new_cols) = B.indices(:, inds);
      new.labels(end+1:end+new_cols) = B.labels(inds);
      new.categories(end+1:end+new_cols) = B.categories(inds);
      new.indices = sparse( new.indices );
      toc;
    end
    
    %{
        UTIL
    %}
    
    function disp(obj)
      
      %   DISP -- print the categories and labels in the object, and 
      %     indicate the frequency of each label.
      
      [unqs, cats] = uniques( obj );
      for i = 1:numel(cats)
        current = unqs{i};
        fprintf( '\n * %s', cats{i} );
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
    
    function arr = ensure_cell(arr)
      if ( ~iscell(arr) ), arr = { arr }; end;
    end
  end
end