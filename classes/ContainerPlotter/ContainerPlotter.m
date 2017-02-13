classdef ContainerPlotter < handle
  
  properties
    
    defaults = struct ( ...
        'x', [] ...
      , 'x_lim', [] ...
      , 'y_lim', [] ...
      , 'x_label', [] ...
      , 'y_label', [] ...
      , 'x_tick_rotation', 60 ...
      , 'error_function', @ContainerPlotter.sem ...
      , 'x_tick_label', [] ...
      , 'y_tick_label', [] ...
      , 'add_legend', true ...
      , 'title', [] ...
      , 'shape', [] ...
      , 'bins', [] ...
      , 'order_by', [] ...
      , 'order_groups_by', [] ...
      , 'order_panels_by', [] ...
      , 'save_outer_folder', [] ...
      , 'save_folder_hierarcy', [] ...
      , 'add_ribbon', false ...
      , 'main_line_width', 3 ...
      , 'ribbon_line_width', .5 ...
      , 'full_screen', false ...
    );
    params;
  end
  
  methods
    function obj = ContainerPlotter()
      obj.params = obj.defaults;
    end
    
    %{
        PLOTS
    %}
    
    function h = bar(obj, cont, category, group_by, within, varargin)
      
      %   BAR -- Create a bar plot of the data in a Container object.
      %
      %     TODO: Fix issue where single label in `category` produces
      %     issues with legending.
      %
      %     IN:
      %       - `cont` (Container) -- Object whose data are to be plotted.
      %         Data in the object must be an Mx1 column vector.
      %       - `category` (char) -- Specifies the category of labels that
      %         will form the x-axis.
      %       - `group_by` (cell array of strings, char, []) -- Specify
      %         categories by which to group sets of data. If [], no
      %         grouping is applied.
      %       - `within` (cell array of strings, char, []) -- Each
      %       	unique combination of labels in these categories will
      %       	receive its own subplot. If [], the resulting plot will
      %       	have only a single panel.
      %     OUT:
      %       - `h` (cell array of graphics handles)
      %
      %     Ex 1. //
      %
      %     %   Create a plot where, for each image category, the effects
      %     %   of each dose are plotted on separate subplots for each
      %     %   monkey.
      %
      %     plotter = ContainerPlotter();
      %     plotter.bar( looking_behavior, 'images', 'doses', 'monkeys' );
      %
      %     Ex 2. //
      %
      %     %   Create a plot where, for each image category, the effects
      %     %   of each dose of each drug are plotted on separate subplots
      %     %   for each monkey.
      %
      %     plotter = ContainerPlotter();
      %     plotter.bar( looking_behavior, 'images', {'doses','drugs'}, ...
      %     'monkeys' )
      
      obj.params = obj.parse_params_struct( obj.params, varargin{:} );
      obj.assert__is_container( cont );
      assert( ~isempty(cont), 'The Container object is empty.' );
      obj.assert__n_dimensional_data( cont, 2 );
      obj.assert__data_are_of_size( cont, [], 1 );
      obj.assert__isa( category, 'char', 'category name' );
      if ( isempty(within) )
        inds = { true(shape(cont, 1), 1) };
        within = field_names( cont );
      else
        [inds, panel_combs] = get_indices( cont, within );
        if ( ~isempty(obj.params.order_panels_by) )
          panel_ind = ...
            obj.preferred_order_index( panel_combs, obj.params.order_panels_by );
          inds = inds( panel_ind, : );
        end
      end
      obj.assign_shape( numel(inds) );
      labs = unique( get_fields(cont.labels, category) );
      if ( ~isempty(obj.params.order_by) )
        main_order_ind = obj.preferred_order_index( labs, obj.params.order_by );
        labs = labs( main_order_ind, : );
      end
      h = cell( 1, numel(inds) );
      for i = 1:numel(inds)
        one_panel = keep( cont, inds{i} );
        title_labels = strjoin( flat_uniques(one_panel.labels, within), ' | ' );
        if ( ~isempty(group_by) )
          add_legend = obj.params.add_legend;
          [group_inds, group_combs] = get_indices( one_panel, group_by );
          if ( ~isempty(obj.params.order_groups_by) )
            group_label_ind = obj.preferred_order_index( group_combs ...
              , obj.params.order_groups_by );
            group_inds = group_inds( group_label_ind, : );
            group_combs = group_combs( group_label_ind, : );
          end
          means = nan( numel(labs), numel(group_inds) );
          errors = nan( size(means) );
          legend_items = cell( 1, numel(group_inds) );
          for k = 1:numel(group_inds)
            one_grouping = keep( one_panel, group_inds{k} );
            for j = 1:numel(labs)
              per_lab = only( one_grouping, labs{j} );
              if ( isempty(per_lab) ), continue; end;
              means(j, k) = mean( per_lab.data );
              errors(j, k) = obj.params.error_function( per_lab.data );
            end
            legend_items{k} = strjoin( group_combs(k, :), ' | ' );
          end
        else
          means = nan( 1, numel(labs) );
          errors = nan( size(means) );
          add_legend = false;
          for k = 1:numel(labs)
            per_lab = only( one_panel, labs{k} );
            if ( isempty(per_lab) ), continue; end;
            means(k) = mean( per_lab.data );
            errors(k) = obj.params.error_function( per_lab.data );
          end
        end
        subplot( obj.params.shape(1), obj.params.shape(2), i );
        h{i} = barwitherr( errors, means );
        set( gca, 'xtick', 1:numel(labs) );
        set( gca, 'xticklabel', labs );
        current_axis = gca;
        title( title_labels );
        if ( add_legend )
          legend( legend_items );
        end
        obj.apply_if_not_empty( current_axis );
      end  
      if ( obj.params.full_screen )
        set( gcf, 'units', 'normalized', 'outerposition', [0 0 1 1] );
      end
    end
    
    function h = plot(obj, cont, categories, within, varargin)
      
      %   PLOT -- Plot two-dimensional data in a Container object.
      %
      %     IN:
      %       - `cont` (Container) -- Object whose data are to be plotted.
      %         Data in the object must be an MxN matrix, where N > 1.
      %       - `categories` (cell array of strings, char, []) -- Specify
      %         the categories of labels that will form separate lines on
      %         each subplot. If [], each subplot will have only one line.
      %       - `within` (cell array of strings, char, []) -- Each
      %       	unique combination of labels in these categories will
      %       	receive its own subplot. If [], the resulting plot will
      %       	have only a single panel.
      %     OUT:
      %       - `h` (cell array of graphics handles)
      
      obj.params = obj.parse_params_struct( obj.params, varargin{:} );
      obj.assert__is_container( cont );
      obj.assert__n_dimensional_data( cont, 2 );
      assert( ~isempty(cont), 'The Container is empty.' );
      if ( ~isempty(obj.params.x) )
        assert( numel(obj.params.x) == shape(cont, 2) ...
          , ['If specifying x coordinates,' ...
          , ' the number of coordinates must match the number of columns' ...
          , ' in the Container. Current number of columns is %d; %d were' ...
          , ' specified'], shape(cont, 2), numel(obj.params.x) );
        x = obj.params.x;
      else x = 1:shape(cont, 2);
      end
      if ( isempty(within) )
        inds = { true(shape(cont, 1), 1) };
      else
        [inds, panel_combs] = get_indices( cont, within );
        if ( ~isempty(obj.params.order_panels_by) )
          panel_ind = ...
            obj.preferred_order_index( panel_combs, obj.params.order_panels_by );
          inds = inds( panel_ind, : );
        end
      end
      obj.assign_shape( numel(inds) );
      if ( ~isempty(categories) )
        [~, label_combs] = get_indices( cont, categories );
        if ( ~isempty(obj.params.order_by) )
          main_order_ind = ...
            obj.preferred_order_index( label_combs, obj.params.order_by );
          label_combs = label_combs( main_order_ind, : );
        end
        add_legend = obj.params.add_legend;
      else
        to_collapse = setdiff( field_names(cont), within );
        cont = collapse( cont, to_collapse );
        label_combs = unique( get_fields(cont.labels, to_collapse{1}) );
        add_legend = false;
      end
      h = cell( 1, numel(inds) );
      for i = 1:numel(inds)
        one_panel = keep( cont, inds{i} );
        if ( ~isempty(within) )
          title_labels = ...
            strjoin( flat_uniques(one_panel.labels, within), ' | ' );
        else title_labels = obj.params.title;
        end
        h{i} = subplot( obj.params.shape(1), obj.params.shape(2), i );
        hold off;
        legend_items = {};
        line_stp = 1;
        one_line = [];
        for k = 1:size(label_combs, 1)
          per_lab = only( one_panel, label_combs(k, :) );
          if ( isempty(per_lab) ), continue; end
          if ( add_legend )
            legend_items = [ legend_items; strjoin(label_combs(k, :), ' | ') ];
          end
          means = mean( per_lab.data, 1 );
          main_line_width = obj.params.main_line_width;
          one_line(line_stp) = plot( x, means, 'linewidth', main_line_width );
          hold on;
          if ( obj.params.add_ribbon )
            color = get( one_line(line_stp), 'color' );
            if ( shape(per_lab, 1) == 1 )
              errors = 0;
            else errors = obj.params.error_function( per_lab.data );
            end
            r_line_width = obj.params.ribbon_line_width;
            r(1) = plot( x, means + errors, 'linewidth', r_line_width );
            r(2) = plot( x, means - errors, 'linewidth', r_line_width );
            set(r(1), 'color', color );
            set(r(2), 'color', color );
          end
          line_stp = line_stp + 1;
        end
        current_axis = gca;
        title( title_labels );
        if ( add_legend )
          legend( one_line, legend_items );
        end
        obj.apply_if_not_empty( current_axis );
      end
      if ( obj.params.full_screen )
        set( gcf, 'units', 'normalized', 'outerposition', [0 0 1 1] );
      end
    end
    
    %{
        UTIL
    %}
    
    function disp(obj)
      
      %   DISP -- Display the current plotting parameters.
      fprintf( '\n ContainerPlotter with parameters:\n\n' );
      disp( obj.params );
    end
    
    function apply_if_not_empty(obj, ax)
      
      %   APPLY_IF_NOT_EMPTY -- Automatically set certain figure properties
      %     if they are specified in the obj.params struct.
      %
      %     Current assignments are limited to: x_lim, y_lim, x_label,
      %     y_label, title, and x_tick_rotation.
      %
      %     IN:
      %       - `ax` (axes object) |OPTIONAL| -- Handle to the axis on
      %         which to set non-empty properties. If unspecified, uses the
      %         current gca axis.
      
      if ( nargin < 2 ), ax = gca; end;
      params = obj.params; %#ok<*PROPLC,*PROP>
      if ( ~isempty(params.x_lim) ),   xlim( ax, params.x_lim ); end;
      if ( ~isempty(params.y_lim) ),   ylim( ax, params.y_lim ); end;
      if ( ~isempty(params.x_label) ), xlabel( ax, params.x_label ); end;
      if ( ~isempty(params.y_label) ), ylabel( ax, params.y_label ); end;
      if ( ~isempty(params.title) ), 	title( ax, params.title ); end;
      if ( ~isempty(params.x_tick_rotation) )
        ax.XTickLabelRotation = params.x_tick_rotation;
      end
    end
    
    function obj = default(obj)
      
      %   DEFAULT -- Reset the values in the params struct to their default
      %     values.
      
      obj.params = obj.defaults;
    end
    
    function obj = assign_shape(obj, n_required)
      
      %   ASSIGN_SHAPE -- Validate the given `shape` field of the params
      %     struct in the object.
      %
      %     IN:
      %       - `n_required` (double) |SCALAR| -- Number specifying the
      %         minimum number of subplots required.
      
      if ( isempty(obj.params.shape) )
        obj.params.shape = [1, n_required];
      else obj.assert__adequate_shape( obj.params.shape, n_required );
      end
    end    
  end
  
  methods (Static = true)
    
    %{
        CONTAINER-ASSERTIONS
    %}
    
    function assert__is_container(cont)
      
      %   ASSERT__IS_CONTAINER -- Ensure a given input is a Container
      %     object.
      %
      %     IN:
      %       - `cont` (/any/) -- Values to test.
      
      assert( isa(cont, 'Container'), ['Expected input to be a Container;' ...
        , ' was a ''%s''.'], class(cont) );      
    end
    
    function assert__n_dimensional_data(cont, n)
      
      %   ASSERT__N_DIMENSIONAL_DATA -- Ensure the data in a Container
      %     object have a specific number of dimensions.
      %
      %     IN:
      %       - `cont` (Container) -- Object to test.
      %       - `n` (double) |SCALAR| -- Number of dimensions to test for.
      
      ContainerPlotter.assert__is_container( cont );
      assert( ndims(cont.data) == n, ['Expected the data to have %d' ...
        , ' dimensions; %d dimensions are present.'], n, ndims(cont.data) );
    end
    
    function assert__data_are_of_size(cont, varargin)
      
      %   ASSERT__DATA_ARE_OF_SIZE -- Ensure the data in a Container are
      %     appropriately sized.
      %
      %     The number of varargin values must match the number of
      %     dimensions in the data.
      %
      %     IN:
      %       - `cont` (Container) -- Container object whose data are to be
      %         validated.
      %       - `varargin` (cell array) -- 1xN vector of size values, where
      %         the i-th element corresponds to the required size of the
      %         data in the Container in the i-th dimension. HOWEVER,
      %         specify [] to ignore the size requirement in that
      %         dimension.
      
      ContainerPlotter.assert__is_container( cont );
      assert( numel(varargin) == ndims(cont.data), ['Expected there to be' ...
        , ' %d size values, corresponding to each dimension of data in' ...
        , ' the Container, but %d were provided.'], ndims(cont.data) ...
        , numel(varargin) );
      for i = 1:numel(varargin)
        current_sz = varargin{i};
        if ( isequal(current_sz, []) ), continue; end;
        assert( size(cont.data, i) == current_sz, ['Expected dimension number' ...
          , ' %d to have %d elements, but there were %d.'], i, current_sz ...
          , size(cont.data, i) );
      end
    end
    
    %{
        PARAMS ASSERTIONS
    %}
    
    function assert__adequate_shape(shape, N)
      
      %   ASSERT__ADEQUATE_SHAPE -- Ensure the specified shape contains
      %     more elements than N.
      %
      %     IN:
      %       - `shape` (double) -- Two element vector: [n_rows, n_cols]
      %       - `N` (double) |SCALAR| -- Minimum number of subplots.
      
      assert( numel(shape) == 2, ['Expected shape to be a 2-element vector,' ...
        , ' but there were %d elements'], numel(shape) );
      assert( shape(1)*shape(2) >= N, ['When specifying' ...
        , ' dimensions for the subplot, the number of rows * the number of columns' ...
        , ' must be greater than or equal to the number of unique' ...
        , ' combinations. The minimum for this label-set is %d, but only %d' ...
        , ' were specified'], N, shape(1)*shape(2) );
    end
    
    %{
        GENERAL ASSERTIONS
    %}
    
    function assert__iscellstr(A, var_name)
      
      %   ASSERT__ISCELLSTR -- Ensure an input is a cell array of strings.
      %
      %     We must keep this separate from assert__isa because the class
      %     of a cell array of strings is still 'cell'.
      %
      %     IN:
      %       - `A` (/any/) -- Values to test.
      %       - `var_name` (char) |OPTIONAL| -- What to call the expected
      %         input in the error message.
      
      if ( nargin < 2 )
        var_name = 'input';
      else
        assert( isa(var_name, 'char'), ['Variable name must be a char; was a' ...
          , ' ''%s'''], class(var_name) );
      end
      assert( iscellstr(A), ['Expected %s to be a cell array of strings,' ...
        , ' but was a ''%s'''], var_name, class(A) );
    end
    
    function assert__isa(A, kind, var_name)
      
      %   ASSERT__ISA -- Ensure an input is of the specified kind.
      %
      %     This is mainly useful to avoid long error-msg strings
      %     everywhere.
      %
      %     IN:
      %       - `A` (/any/) -- Values to test.
      %       - `kind` (char) -- Name of the class `A` is expected to be.
      %       - `var_name` (char) |OPTIONAL| -- What to call the expected
      %         input in the error message.
      
      if ( nargin < 3 ), 
        var_name = 'input'; 
      else
        assert( isa(var_name, 'char'), ['Variable name must be a char; was a' ...
          , ' ''%s'''], class(var_name) );
      end
      assert( isa(A, kind), 'Expected %s to be a ''%s''; was a ''%s''' ...
        , var_name, kind, class(A) );
    end
    
    %{
        UTIL
    %}
    
    function all_inds = preferred_order_index( actual, preferred )
      
      %   PREFERRED_ORDER_INDEX -- Obtain an ordered index of labels based
      %     on the specified preferred order.
      %
      %     Actual labels must be MxN cell array of labels as obtained from
      %     Container.get_indices() or Container.combs(), with M
      %     combinations of labels in N categories.
      %
      %     IN:
      %       - `actual` (cell array of strings) -- Labels as obtained from
      %         get_indices().
      %       - `preferred` (cell array of strings) -- The preferred order
      %         of those labels. Elements in `preferred` not found in
      %         `actual` will be skipped.
      %     OUT:
      %       - `all_inds` (double) -- Numeric index of the elements in
      %         `actual` as sorted by `preferred`.
      
      if ( ~iscell(preferred) ), preferred = { preferred }; end;
      ContainerPlotter.assert__iscellstr( preferred, 'preferred order' );
      assert( numel(unique(preferred)) == numel(preferred) ...
        , ' Do not specify duplicate order-labels.' );
      all_inds = 1:size( actual, 1 );
      all_inds = all_inds(:);
      inds = cellfun( @(x) find(strcmp(preferred, x)), actual, 'un', false );
      empties = cellfun( @isempty, inds );
      inds( empties ) = { Inf };
      inds = cell2mat( inds );
      for i = 1:size( inds, 2 )
        [~, sort_ind] = sort( inds(:, i) );
        all_inds = all_inds( sort_ind, : );
        inds = inds( sort_ind, : );        
      end
    end
    
    function reformatted = preferred_order( actual, preferred )
      
      %   PREFERRED_ORDER -- Attempt to order labels in the specified
      %     preferred order.
      %
      %     Labels specified in `preferred` but which are not found in
      %     `actual` are ignored.
      %
      %     IN:
      %       - `actual` (cell array of strings) -- Labels as obtained from
      %         get_indices().
      %       - `preferred` (cell array of strings) -- The preferred order
      %         of those labels. Elements in `preferred` not found in
      %         `actual` will be skipped.
      %     OUT:
      %       - `reformatted` (cell array of strings) -- Elements ordered
      %         as desired.
      
      reformatted = {};
      actual = actual(:);
      full_ind = true( size(actual) );
      for i = 1:numel(preferred)
        ind = strcmp( actual, preferred{i} );
        if ( ~any(ind) ), continue; end;
        reformatted = [reformatted; actual(ind)];
        full_ind(ind) = false;
      end
      if ( ~any(full_ind) ), return; end;
      reformatted = [reformatted; actual(full_ind)];
    end
    
    function y = sem(x, dim)
      
      %   SEM -- Standard error of the mean.
      %
      %     IN:
      %       - `x` (double) -- Data.
      %       - `dim` (double) |OPTIONAL| -- Dimension on which to operate.
      %         Defaults to 1.
      %     OUT:
      %       - `y` (double) -- Std error.
    
      if ( nargin < 2 )
          n = numel( x );
          y = std( x ) / sqrt( n );
      else
          n = size( x, dim );
          y = std( x, [], dim ) ./ sqrt( n );
      end
    end
    
    function params = parse_params_struct(params, varargin)
      
      %   PARSE_PARAMS_STRUCT -- Parse (name, value) argument pairs.
      %
      %     Each specified parameter name must be a field of the given
      %     params struct (IGNORING CASE).
      %
      %     IN:
      %       - `params` (struct) -- Struct whose fields are to be
      %         overwritten.
      %       - `varargin` (cell array) -- Variable number of (name, value)
      %         arguments pairs. An error is thrown if the number of
      %         elements in `varargin` is not even.
      %     OUT:
      %       - `params` (struct) -- Struct with the appropriate fields
      %         overwritten with the corresponding values.
      
      if ( isempty(varargin) ), return; end;
      assert( mod(numel(varargin), 1) == 0, ['(name, value) inputs must' ...
        , ' come in pairs.'] );
      args = reshape( varargin(:), 2, numel(varargin(:))/2 );
      for i = 1:size(args, 2)
        field_to_assign = args{1, i};
        assert( isa(field_to_assign, 'char'), ['In (name, value) pairs, `name`' ...
          , ' must be a char; was a ''%s''.'], class(field_to_assign) );
        field_to_assign = lower( field_to_assign );
        values = args{2, i};
        assert( isfield(params, field_to_assign), ['The field ''%s''' ...
          , ' is not a recognized field of the given parameters struct.'] ...
          , field_to_assign );
        params.(field_to_assign) = values;
      end
    end
    
  end
  
end