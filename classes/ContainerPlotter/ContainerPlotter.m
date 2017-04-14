classdef ContainerPlotter < handle
  
  properties
    
    defaults = struct ( ...
        'x', [] ...
      , 'x_lim', [] ...
      , 'y_lim', [] ...
      , 'match_y_lim', true ...
      , 'x_label', [] ...
      , 'y_label', [] ...
      , 'x_tick_rotation', 60 ...
      , 'error_function', @ContainerPlotter.sem_1d ...
      , 'summary_function', @mean ...
      , 'x_tick_label', [] ...
      , 'y_tick_label', [] ...
      , 'add_legend', true ...
      , 'title', [] ...
      , 'shape', [] ...
      , 'bins', [] ...
      , 'order_by', [] ...
      , 'order_groups_by', [] ...
      , 'order_panels_by', [] ...
      , 'stacked_bar', false ...
      , 'save_outer_folder', [] ...
      , 'save_folder_hierarcy', [] ...
      , 'save_formats', {{ 'epsc', 'png'}} ...
      , 'add_ribbon', false ...
      , 'add_fit_line', true ...
      , 'add_points', false ...
      , 'new_figure_per_iteration', true ...
      , 'vertical_lines_at', [] ...
      , 'point_label_categories', {{}} ...
      , 'current_points', {{}} ...
      , 'compare_series', false ...
      , 'match_fit_line_color', true ...
      , 'plot_function_type', 'plot' ...
      , 'main_line_width', 3 ...
      , 'ribbon_line_width', .5 ...
      , 'marker_size', 20 ...
      , 'full_screen', false ...
      , 'color_map', 'hsv' ...
      , 'color_defs', struct( ...
            'red',    [220 20 60] ...
          , 'orange', [255 165 0] ...
          , 'yellow', [255 255 0] ...
          , 'green',  [34 139 34] ...
          , 'blue',   [30 144 255] ... 
          , 'purple', [186 85 211] ...
          , 'black',  [1 1 1] ...
        ) ...
      , 'colors', [] ...
      , 'set_colors', 'auto' ...
    );
    params;
    parameter_names = {};
  end
  
  methods
    function obj = ContainerPlotter()
      obj.defaults.colors = fieldnames( obj.defaults.color_defs );
      obj.defaults.color_defs = obj.rgb_to_proportion( obj.defaults.color_defs );
      obj.params = obj.defaults;
      obj.parameter_names = fieldnames( obj.defaults );
    end
    
    %{
        REF + ASSIGN
    %}
    
    function varargout = subsref(obj, s)
      
      subs = s(1).subs;
      type = s(1).type;      
      s(1) = [];
      proceed = true;
      
      switch ( type )
        case '.'
          %   if the ref is the name of a ContainerPlotter property, 
          %   return the property
          if ( proceed && any(strcmp(properties(obj), subs)) )
            out = obj.(subs); proceed = false;
          end
          if ( proceed && any(strcmp(methods(obj), subs)) )
            func = eval( sprintf('@%s', subs) );
            if ( numel(s) == 0 )
              error( ['''%s'' is the name of a %s method, but was' ...
                , ' referenced as if it were a property.'], subs, class(obj) );
            end
            inputs = [ {obj} {s(:).subs{:}} ];
            %   assign `out` to the output of func() and return
            if ( nargout() == 0 )
              func( inputs{:} );
            else [varargout{1:nargout()}] = func( inputs{:} );
            end
            return; %   note -- in this case, we do not proceed
          end
          %   if subs is a parameter name, return the parameter.
          if ( proceed && any(strcmp(obj.parameter_names, subs)) )
            out = obj.params.(subs); proceed = false;
          end
          if ( proceed )
            error( ['No properties, methods or parameters matched' ...
              , ' the name ''%s''.'], subs );
          end
        otherwise
          error( 'Referencing with ''%s'' is unsupported.', type );
      end      
      if isempty(s)
        varargout{1} = out;
        return;
      end
      %   continue referencing if this is a nested reference.
      [varargout{1:nargout()}] = subsref( out, s );
    end
    
    function obj = subsasgn(obj, s, values)
      
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
        otherwise
          error( 'Assignment with ''%s'' is unsupported.', s(1).type );
      end
    end
    
    function obj = set_property(obj, prop, values)
      
      %   SET_PROPERTY -- Ensure property validity.
      %
      %     IN:
      %       - `prop` ('params', fieldname of `params`) -- `params` or
      %         value of `params` to set.
      %       - `values` (/any/) -- If assigning `params`, `values` must be
      %         a struct with the same fieldnames as `defaults`.
      
      if ( isequal(prop, 'params') )
        msg = ['When overwriting the `params` struct, the incoming params' ...
          , ' must be a struct with the same fields as the object''s' ...
          , ' default parameters.'];
        assert( isstruct(values), msg );
        assert( isequal(sort(fieldnames(values)), sort(obj.parameter_names)) ...
          , msg );
        obj.params = values;
      end
      %   ensure `color_defs` is a struct whose fields are rgb triplets.
      if ( isequal(prop, 'color_defs') )
        assert( isstruct(values), ['Expected ''color_defs'' to be a struct; was a' ...
          , ' ''%s''.'], class(values) );
        assert( ~isempty(fieldnames(values)), 'The ''color_defs'' cannot be empty.' );
        structfun( @(x) assert(numel(x) == 3, ['Each color in ''color_defs''' ...
          , ' must be an rgb triplet.']), values );
        structfun( @(x) assert(all(x >= 0 & x <= 255), 'Invalid rgb triplet.') ...
          , values );
        %   remove `colors` for which there is no defined color_defs
        new_colors = fieldnames( values );
        obj.params.colors = intersect( obj.params.colors, new_colors );
      end
      if ( isequal(prop, 'set_colors') )
        assert( isequal(values, 'auto') || isequal(values, 'manual') ...
          , 'Parameter ''color_set'' must be either ''auto'' or ''manual.''' );
      end
      if ( isequal(prop, 'colors') )
        current = fieldnames( obj.params.color_defs );
        values = Labels.ensure_cell( values );
        ContainerPlotter.assert__iscellstr( values, 'colors' );
        assert( all(cellfun(@(x) any(strcmp(current, x)), values)) ...
          , 'At least one of the specified colors lacks a colormap value.' );
      end
      if ( isequal(prop, 'plot_function_type') )
        ContainerPlotter.assert__isa( values, 'char', prop );
        assert( any(strcmp({'plot', 'error_bar'}, values)) ...
          , 'Plot functions can be ''plot'' or ''error_bar''.' );
      end
      if ( any(strcmp(obj.parameter_names, prop)) )
        obj.params.(prop) = values;
      end
    end
    
    %{
        PLOTS
    %}
    
    function subp = group_plot(obj, cont, category, group_by, within, func, include_errors, plot_opts, varargin)
      
      %   GROUP_PLOT -- Plot 1-d data along an x-axis specified by a given
      %     category.
      %
      %     This is an internal function called by several plotting
      %     functions, and is not meant to be called directly.
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
      %       - `func` (function_handle) -- low-level plotting function to
      %         be called.
      %       - `include_errors` (logical) |SCALAR| -- Specify whether to
      %         include error-bars.
      %       - `plot_opts` (cell array) -- Additional inputs to be passed
      %         to the plotting function `func`.
      %       - `varargin` (cell array) -- Additional inputs to allow
      %         overwriting of plotting parameters in `obj.params`.
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
      obj.assert__isa( func, 'function_handle', 'plotting function' );
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
      subp = gobjects( 1, numel(inds) );
      maxs = [];
      mins = [];
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
          store_values = repmat( {NaN}, size(means) );
          store_objs = cell( size(means) );
          for k = 1:numel(group_inds)
            one_grouping = keep( one_panel, group_inds{k} );
            for j = 1:numel(labs)
              per_lab = only( one_grouping, labs{j} );
              if ( isempty(per_lab) ), continue; end;
              means(j, k) = obj.params.summary_function( per_lab.data );
              errors(j, k) = obj.params.error_function( per_lab.data );
              store_values{j, k} = per_lab.data;
              store_objs{j, k} = per_lab;
            end
            legend_items{k} = strjoin( group_combs(k, :), ' | ' );
          end
        else
          means = nan( 1, numel(labs) );
          errors = nan( size(means) );
          store_values = repmat( {NaN}, size(means) );
          store_objs = cell( size(means) );
          xs = 1:numel( labs );
          add_legend = false;
          for k = 1:numel(labs)
            per_lab = only( one_panel, labs{k} );
            if ( isempty(per_lab) ), continue; end;
            means(k) = obj.params.summary_function( per_lab.data );
            errors(k) = obj.params.error_function( per_lab.data );
            store_values{k} = per_lab.data;
            store_objs{k} = per_lab;
          end
        end
        subp(i) = subplot( obj.params.shape(1), obj.params.shape(2), i );
        if ( include_errors )
          func_type = func2str( func );
          switch ( func_type )
            case 'errorbar'
              h{i} = func( means, errors, plot_opts{:} );
            case 'barwitherr'
              h{i} = func( errors, means, plot_opts{:} );
            otherwise
              error( 'Unrecognized plotting function ''%s''', func_type );
          end
        else
          h{i} = func( means, plot_opts{:} );
        end
        %   store newest maxs + mins
        summed = means + errors;
        subbed = means - errors;
        maxs = max( [maxs, max(summed(:))] );
        mins = min( [mins, min(subbed(:))] );
        if ( obj.params.add_points )
          dcm = datacursormode( gcf );
          datacursormode( 'on' );
          set( dcm, 'updatefcn', @event_response );
          hold on;
          if ( size(store_values, 1) == 1 )
            xs = 1:size( store_values, 2 );
            xs = repmat( xs, size(store_values, 1), 1 );
          else
            xs = 1:size( store_values, 1 );
            xs = repmat( xs(:), 1, size(store_values, 2) );
          end
          for k = 1:numel(xs)
            current = store_values(k);
            current = current{1};
            current_obj = store_objs(k);
            current_obj = current_obj{1};
            for j = 1:numel(current)
              plot( xs(k), current(j), '*', 'markersize', obj.params.marker_size );
              s = struct();
              s.object = current_obj(j);
              s.data = [xs(k), current(j)];
              obj.params.current_points{end+1} = s;
            end
          end
          hold off;
        end
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
      %   update limits automatically, if unspecified
      if ( obj.params.match_y_lim && isempty(obj.params.y_lim) )
        linkaxes( subp, 'y' );
        ylim( subp(1), [floor(mins), ceil(maxs)] );
      end
      %   data cursor handling
      function txt = event_response(response_obj, event_obj)
        txt = '';
        try
          matching_obj = obj.get_matching_obj( event_obj.Position );
          cats = obj.params.point_label_categories;
          if ( isempty(cats) ), return; end
          for jj = 1:numel(cats)
            txt = sprintf( '%s\n%s:\n', txt, cats{jj} );
            labels = unique( matching_obj(cats{jj}) );
            for kk = 1:numel(labels)
              txt = sprintf( '%s\n - %s', txt, labels{kk} );
            end
          end
        catch err
          fprintf( ['\n The following error occurred when attempting to' ...
            , ' display the selected datapoint:\n'] );
          fprintf( err.message );
        end
      end
    end
    
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
      
      if ( ~obj.params.stacked_bar )
        plot_func = @barwitherr;
        plot_opts = {};
        include_errors = true;
      else
        plot_func = @bar;
        plot_opts = { 'stacked' };
        include_errors = false;
      end
      
      h = group_plot( obj, cont, category, group_by, within, plot_func ...
        , include_errors, plot_opts, varargin{:} );      
    end
    
    function h = plot_by(obj, cont, category, group_by, within, varargin)
      
      %   PLOT_BY -- Create an error-barred plot of the data in a Container
      %     object in which the x-axis is a particular category.
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
      %     plotter.plot_by( looking_behavior, 'images', 'doses', 'monkeys' );
      %
      %     Ex 2. //
      %
      %     %   Create a plot where, for each image category, the effects
      %     %   of each dose of each drug are plotted on separate subplots
      %     %   for each monkey.
      %
      %     plotter = ContainerPlotter();
      %     plotter.plot_by( looking_behavior, 'images', {'doses','drugs'}, ...
      %     'monkeys' )
      
      plot_func = @errorbar;
      include_errors = true;
      plot_opts = {};
      
      try
        h = group_plot( obj, cont, category, group_by, within, plot_func ...
        , include_errors, plot_opts, varargin{:} );     
      catch err
        throw( err );
      end
    end
    
    function h = plot(obj, cont, lines_are, panels_are, varargin)
      
      %   PLOT -- Plot two-dimensional data in a Container object.
      %
      %     If data in the object are a column vector, mean values will be
      %     plotted as single points (*). Otherwise, mean series will be
      %     plotted against an x-series. If unspecified, the x-series will
      %     be 1:N, where N is the number of columns in the data matrix.
      %
      %     IN:
      %       - `cont` (Container) -- Object whose data are to be plotted.
      %         Data in the object must be an MxN matrix, where N > 1.
      %       - `lines_are` (cell array of strings, char, []) -- Specify
      %         the categories of labels that will form separate lines on
      %         each subplot. If [], each subplot will have only one line.
      %       - `panels_are` (cell array of strings, char, []) -- Each
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
      if ( isempty(panels_are) )
        inds = { true(shape(cont, 1), 1) };
      else
        [inds, panel_combs] = get_indices( cont, panels_are );
        if ( ~isempty(obj.params.order_panels_by) )
          panel_ind = ...
            obj.preferred_order_index( panel_combs, obj.params.order_panels_by );
          inds = inds( panel_ind, : );
        end
      end
      obj.assign_shape( numel(inds) );
      if ( ~isempty(lines_are) )
        [~, label_combs] = get_indices( cont, lines_are );
        if ( ~isempty(obj.params.order_by) )
          main_order_ind = ...
            obj.preferred_order_index( label_combs, obj.params.order_by );
          label_combs = label_combs( main_order_ind, : );
        end
        add_legend = obj.params.add_legend;
      else
        to_collapse = setdiff( field_names(cont), panels_are );
        cont = collapse( cont, to_collapse );
        label_combs = unique( get_fields(cont.labels, to_collapse{1}) );
        add_legend = false;
      end
      h = gobjects( 1, numel(inds) );
      maxs = [];
      mins = [];
      sig_series = cell( 1, numel(inds) );
      for i = 1:numel(inds)
        one_panel = keep( cont, inds{i} );
        if ( ~isempty(panels_are) )
          title_labels = ...
            strjoin( flat_uniques(one_panel.labels, panels_are), ' | ' );
        else title_labels = obj.params.title;
        end
        h(i) = subplot( obj.params.shape(1), obj.params.shape(2), i );
        colormap( obj.params.color_map );
        hold off;
        legend_items = {};
        line_stp = 1;
        one_line = [];
        store_lines = cell( 1, size(label_combs, 1) );
        for k = 1:size(label_combs, 1)
          per_lab = only( one_panel, label_combs(k, :) );
          store_lines{k} = per_lab;
          if ( isempty(per_lab) ), continue; end
          if ( add_legend )
            legend_items = [ legend_items; strjoin(label_combs(k, :), ' | ') ];
          end
          means = obj.params.summary_function( per_lab.data, 1 );
          if ( k == 1 )
            store_max = max( means ); 
          else store_max = max( [store_max, max(means)] );
          end
          if ( shape(per_lab, 1) == 1 )
            errors = 0;
          else errors = obj.params.error_function( per_lab.data );
          end
          main_line_width = obj.params.main_line_width;
          switch ( obj.params.plot_function_type )
            case 'plot'
              %   determine whether to plot lines or single points (*)
              if ( numel(means) > 1 )
                one_line(line_stp) = plot( x, means, 'linewidth', main_line_width );
                can_add_ribbon = true;
                adjust_y_lim_for_error = obj.params.add_ribbon;
              else
                one_line(line_stp) = plot( x, means, '*' );
                can_add_ribbon = false;
                adjust_y_lim_for_error = false;
              end
            case 'error_bar'
              one_line(line_stp) = errorbar( x, means, errors );
              set( one_line(line_stp), 'linewidth', main_line_width );
              can_add_ribbon = false;
              adjust_y_lim_for_error = true;
          end
          if ( adjust_y_lim_for_error )
            summed = means + errors;
            subbed = means - errors;
          else
            summed = means;
            subbed = means;
          end
          maxs = max( [maxs; summed(:)] );
          mins = min( [mins; subbed(:)] );
          hold on;
          if ( isequal(obj.params.set_colors, 'manual') )
            if ( k <= numel(obj.params.colors) )
              current_color = obj.params.color_defs.( obj.params.colors{k} );
              set( one_line(line_stp), 'color', current_color );
            end
          end
          if ( obj.params.add_ribbon && can_add_ribbon )
            color = get( one_line(line_stp), 'color' );
            r_line_width = obj.params.ribbon_line_width;
            r(1) = plot( x, means + errors, 'linewidth', r_line_width );
            r(2) = plot( x, means - errors, 'linewidth', r_line_width );
            set(r(1), 'color', color );
            set(r(2), 'color', color );
          end
          line_stp = line_stp + 1;
        end
        %   the data in two lines can be tested for significance with a
        %   two-sample ttest; significant points will be marked with '*'
        if ( size(label_combs, 1) == 2 && obj.params.compare_series )
          try 
            sig_vec = zeros( 1, size(store_lines{1}.data, 2) );
            for k = 1:size( store_lines{1}.data, 2 )
              extr1 = store_lines{1}.data(:, k);
              extr2 = store_lines{2}.data(:, k);
              [~, sig_vec(k)] = ttest2( extr1(:), extr2(:) );
            end
            sig_vec = sig_vec <= .05;
            if ( any(sig_vec) )
              sig_series{i} = x( sig_vec );
            end
          catch series_error
            fprintf( ['\n WARNING: The following error occurred when' ...
              , ' attempting to compare series:\n'] );
            fprintf( series_error.message );
          end
        end
        current_axis = gca;
        title( title_labels );
        if ( add_legend )
          legend( one_line, legend_items );
        end
        obj.apply_if_not_empty( current_axis );
      end
      %   match y lims
      if ( obj.params.match_y_lim && isempty(obj.params.y_lim) )
        arrayfun( @(x) ylim(x, [floor(mins), ceil(maxs)]), h );
      end
      %   add significant stars if comparing series
      if ( ~all(cellfun(@isempty, sig_series)) )
        for i = 1:numel(sig_series)
          sig_xs = sig_series{i};
          if ( isempty(sig_xs) ), continue; end;
          current_y_lim = get( h(i), 'yLim' );
          set_y = current_y_lim(2);
          sig_ys = repmat( set_y, size(sig_xs) );
          hold on;
          plot( h(i), sig_xs, sig_ys, '*', 'markersize', obj.params.marker_size );
        end
        hold off;
      end
      %   optionally add dashed vertical lines at the specified
      %   x-coordinates.
      if ( ~isempty(obj.params.vertical_lines_at) )
        v_lines_x = obj.params.vertical_lines_at(:)';
        for i = 1:numel(h)
          ys = get( h(i), 'ylim' );
          hold on;
          for k = 1:numel(v_lines_x)
            v_line_x = v_lines_x(k);
            plot( h(i), [v_line_x, v_line_x], ys, 'k' );
          end
        end
        hold off;
      end
      if ( obj.params.full_screen )
        set( gcf, 'units', 'normalized', 'outerposition', [0 0 1 1] );
      end
    end
    
    function scatter(obj, cont1, cont2, categories, within, varargin)
      
      %   SCATTER -- Scatter the data in one Container against the data in
      %     another.
      %
      %     IN:
      %       - `cont1` (Container) -- Container whose data will form the
      %         x-axis. Data in the object must be an Mx1 column vector.
      %       - `cont2` (Container) -- Container whose data will form the
      %         y-axis. The labels and dimensions must match those of
      %         `cont1`.
      %       - `categories` (cell array of strings, char, []) --
      %         Categories by which to group points. Specify [] for no
      %         grouping.
      %       - `within` (cell array of strings, char, []) -- Categories
      %         from which to generate separate panels / subplots. Specify
      %         [] to have a single subplot.
      %       - `varargin` ('name', value pairs) -- Values used to
      %         overwrite parameters of the `obj.params` struct.
      
      obj.params = obj.parse_params_struct( obj.params, varargin{:} );
      obj.assert__is_container( cont1 );
      obj.assert__is_container( cont2 );
      assert( all(cont1.shape() == cont2.shape()), ['The shapes of the' ...
        , ' two Container objects must match'] );
      assert( cont1.labels == cont2.labels, ['The label objects of the two' ...
        , ' Containers must match.'] );
      assert( ~isempty(cont1), 'The Containers cannot be empty.' );
      obj.assert__n_dimensional_data( cont1, 2 );
      obj.assert__data_are_of_size( cont1, [], 1 );
      if ( isempty(within) )
        %   the only 'segments' are the full vectors of data in the object.
        inds = { true(shape(cont1, 1), 1) };
      else
        %   get segments corresponding to combinations of unique labels 
        %   in the categories specified by `within`.
        [inds, panel_combs] = get_indices( cont1, within );
        if ( ~isempty(obj.params.order_panels_by) )
          panel_ind = ...
            obj.preferred_order_index( panel_combs, obj.params.order_panels_by );
          inds = inds( panel_ind, : );
        end
      end
      obj.assign_shape( numel(inds) );
      %   Structure lets us apply Container methods to both the x and y
      %   Containers simultaneously.
      conts = Structure( 'one', cont1, 'two', cont2 );
      h = cell( 1, numel(inds) );
      for i = 1:numel(inds)
        %   conts_panel contains values in cont1 and cont2 for the current
        %   subplot.
        conts_panel = conts.keep( inds{i} );
        if ( ~isempty(within) )
          title_labels = ...
            strjoin( flat_uniques(conts_panel{1}.labels, within), ' | ' );
        else title_labels = obj.params.title;
        end
        if ( ~isempty(categories) )
          [cat_inds, cat_combs] = get_indices( conts_panel{1}, categories );
          if ( ~isempty(obj.params.order_by) )
            cat_ind = obj.preferred_order_index( cat_combs, obj.params.order_by );
            cat_inds = cat_inds( cat_ind, : );
          end
          add_legend = obj.params.add_legend;
        else
          cat_inds = { true(shape(conts_panel{1}, 1), 1) };
          add_legend = false;
        end
        subplot( obj.params.shape(1), obj.params.shape(2), i );
        hold off;
        %   reorder the data according to the panel combs, category combs,
        %   and desired orderings.
        if ( ~isempty(obj.params.order_by) )
          reordered = Structure.create( {'one', 'two'}, Container() );
          for k = 1:numel(cat_inds)
            extr_cat = conts_panel.keep( cat_inds{k} );
            reordered = reordered.fwise( extr_cat, @append );
          end
        else reordered = conts_panel;
        end
        %   if the labels in the Containers are SparseLabels, convert them
        %   to Labels.
        reordered = reordered.full();
        if ( ~isempty(categories) )
          fields = get_fields( reordered{1}.labels, categories );
          grouping_labs = cell( size(fields, 1), 1 );
          for k = 1:size(grouping_labs, 1)
            grouping_labs{k} = strjoin( fields(k, :), ' | ' );
          end
        else grouping_labs = ones( reordered{1}.shape(1), 1 );
        end
        h{i} = gscatter( reordered.one.data, reordered.two.data, grouping_labs ...
          , [], [], obj.params.marker_size);
        if ( isequal(obj.params.set_colors, 'manual') )
          k = 1;
          while ( k <= numel(cat_inds) && k <= numel(obj.params.colors) )
            current_desired_color = obj.params.color_defs.(obj.params.colors{k});
            set( h{i}(k), 'color', current_desired_color );
            k = k + 1;
          end
        end
        if ( ~add_legend ), legend( 'off' ); end;
        if ( obj.params.add_fit_line )
          if ( isempty(categories) )
            fitted = { polyfit( reordered.one.data, reordered.two.data, 1 ) };
            actual_x = { reordered.one.data };
            actual_y = { reordered.two.data };
          else
            fitted = cell( 1, size(cat_combs, 1) );
            actual_x = cell( size(fitted) );
            for k = 1:size( cat_combs, 1 )
              extr = reordered.only( cat_combs(k, :) );
              fitted{k} = polyfit( extr.one.data, extr.two.data, 1 );
              actual_x{k} = extr.one.data;
              actual_y{k} = extr.two.data;
            end
          end
          leg = legend();
          for k = 1:numel( fitted )
            hold on;
            fit_line = plot( actual_x{k}, polyval(fitted{k}, actual_x{k}) ...
              , 'linewidth', obj.params.main_line_width );
            if ( obj.params.match_fit_line_color )
              current_color = get( h{i}(k), 'color' );
              set( fit_line, 'color', current_color );
            else set( fit_line, 'color', 'k' );
            end
            [~, p] = corr( actual_x{k}, actual_y{k} );
            if ( p < .05 && add_legend )
              leg_items = get( leg, 'String' );
              leg_items{k} = sprintf( '%s (*)', leg_items{k} );
              set( leg, 'String', leg_items );
            end
            hold off;
          end
        end
        current_axis = gca;
        title( title_labels );
        obj.apply_if_not_empty( current_axis );
      end
    end
    
    function plot_and_save(obj, cont, within, func, varargin)
      
      %   PLOT_AND_SAVE -- Iteratively call a ContainerPlotter plotting 
      %     function, and save each iteration.
      %
      %     IN:
      %       - `cont` (Container) -- Plotted object.
      %       - `within` (cell array of strings, char) -- Each saved plot
      %         will feature one set of unique labels drawn from these
      %         categories.
      %       - `func` (function_handle) -- Handle to a ContainerPlotter
      %         plot function.
      %       - `varargin` (/any/) -- Any additional inputs to pass with
      %         each call to `func`.
      
      obj.assert__is_container( cont );
      obj.assert__isa( func, 'function_handle', 'plotting function' );
      assert( ~isempty(obj.params.save_outer_folder), ['You must specify' ...
        , ' a save_outer_folder'] );
      assert( ~isempty(obj.params.save_formats), ['You must specify at least' ...
        , ' one valid save format'] );
      [inds, combs] = get_indices( cont, within );
      save_outer_folder = obj.params.save_outer_folder;
      formats = Labels.ensure_cell( obj.params.save_formats );
      obj.assert__iscellstr( formats, 'formats' );
      for i = 1:numel(inds)
        extr = keep( cont, inds{i} );
        if ( obj.params.new_figure_per_iteration )
          if ( i > 1 ), close gcf; end;
          figure;
        end
        try
          func( obj, extr, varargin{:} );
        catch err
          fprintf( ['\n The following error occurred when attempting to' ...
            , ' call function ''%s'':'], func2str(func) );
          error( err.message );
        end
        if ( size(combs, 2) > 1 )
          current = combs(i, end-1);
          full_save_folder = fullfile( save_outer_folder, current{:} );
        else full_save_folder = save_outer_folder;
        end
        if ( exist(full_save_folder, 'dir') ~= 7 ), mkdir(full_save_folder); end;
        file_name = fullfile( full_save_folder, combs{i, end} );
        for k = 1:numel( formats )
          try
            saveas( gcf, file_name, formats{k} );
          catch err
            fprintf( ['\n The following error occurred when attempting to' ...
              , ' save file ''%s.%s'''], file_name, formats{k} );
            error( err.message );
          end
        end
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
    
    function color_defs = rgb_to_proportion(obj, color_defs)
      
      %   RGB_TO_PROPORTION -- Convert rgb() triplets to a proportion
      %     between [0, 1]
      
      color_defs = structfun( @(x) x/255, color_defs, 'un', false );
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
      if ( ~isempty(params.x_tick_label) )
        set( ax, 'xticklabel', params.x_tick_label );
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
      %     If obj.params.shape is empty, an appropriate shape will be
      %     assigned. Otherwise, the current shape is checked for validity;
      %     if invalid, it will be updated to a valid shape.
      %
      %     IN:
      %       - `n_required` (double) |SCALAR| -- Number specifying the
      %         minimum number of subplots required.
      
      if ( isempty(obj.params.shape) )
        if ( n_required <= 3 )
          obj.params.shape = [ 1, n_required ];
        else
          n_rows = round( sqrt(n_required) );
          n_cols = ceil( n_required/n_rows );
          obj.params.shape = [ n_rows, n_cols ];
        end
      else
        try
          obj.assert__adequate_shape( obj.params.shape, n_required );
        catch
          obj.params.shape = [];
          obj.assign_shape( n_required );
        end
      end
    end
    
    function matching_obj = get_matching_obj(obj, coordinates)
      
      %   GET_MATCHING_OBJ -- Get the Container object associated with the
      %     point specified by `coordinates`.
      %
      %     An error is thrown if there are no `current_points` in the
      %     obj.params struct. An error is thrown if no points match the
      %     specified coordinates.
      %
      %     IN:
      %       - `coordinates` (double) -- Two-element vector specifying an
      %         (x, y) coordinate.
      %     OUT:
      %       - `matching_obj` (Container) -- Container object associated
      %         with the inputted coordinates.
      
      assert( ~isempty(obj.params.current_points) ...
        , 'There are no current points in the object.' );
      points = obj.params.current_points;
      matches_x = cellfun( @(x) x.data(1) == coordinates(1), points );
      matches_y = cellfun( @(x) x.data(2) == coordinates(2), points );
      assert( sum(matches_x & matches_y) == 1 ...
        , 'Too many or too few matching points were found.' );
      matching_point = points( matches_x & matches_y );
      matching_obj = matching_point{1}.object;
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
    
    function y = sem_1d(x)
      
      %   SEM_1D -- Standard error across the first dimension.
      %
      %     IN:
      %       - `x` (double) -- Data.
      %     OUT:
      %       - `y` (double) -- Vector of the same size as `x`.
      
      N = size( x, 1 );
      y = ContainerPlotter.std_1d( x ) / sqrt( N );
    end
    
    function y = std_1d(x)
      
      %   STD_1D -- Standard deviation across the first dimension.
      %
      %     IN:
      %       - `x` (double) -- Data.
      %     OUT:
      %       - `y` (double) -- Vector of the same size as `x`.
      
      y = std( x, [], 1 );
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
          n = size( x, 1 );
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