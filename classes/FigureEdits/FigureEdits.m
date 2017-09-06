classdef FigureEdits < handle
  
  properties
    editors = {};
    active = {};
    filenames = {};
  end
  
  methods
    function obj = FigureEdits(fig_or_fname)
      
      %   FIGUREEDITS -- Instantiate a FigureEdits object.
      %
      %     obj = FigureEdits( f ), where `f` is the handle to a Matlab
      %     figure, creates a new editor associated with `f`.
      %
      %     obj = FigureEdits( {f1, f2} ), where `f1` and `f2` are Matlab
      %     figure handles, creates a new editor associated with `f1` and
      %     `f2`. Subsequent calls to property-setting functions (e.g.,
      %     `xlim`) will update both `f1` and `f2`.
      %
      %     obj = FigureEdits( {file1, file2} ), where `file1` and `file2`
      %     are valid paths to Matlab .fig files, works as above, but first
      %     opens the figures associated with `file1` and `file2`.
      %
      %     See also FigureEdits/open FigureEdits/xlim
      %
      %     IN:
      %       - `fig_or_fname` (char, cell array of strings,
      %         matlab.ui.Figure, cell array of matlab.ui.Figure)
      
      if ( nargin == 0 ), return; end
      fig_or_fname = FigureEdits.ensure_cell( fig_or_fname );
      if ( ~iscellstr(fig_or_fname) )
        try
          cellfun( @(x) FigureEdits.assert__is_fig(x), fig_or_fname );
        catch err
          msg = ['Expected figure(s) to be either figure handles or' ...
            , ' filenames.'];
          err = MException( '', msg );
          throwAsCaller( err );
        end
        figs = fig_or_fname;
        obj.editors = cellfun( @(x) FigureEdit(x), figs, 'un', false );
        obj.filenames = cellfun( @(x) x.Name, figs, 'un', false );
      else
        fnames = fig_or_fname;
        obj.open( fnames );
      end
      obj.activate();
    end
    
    function out1 = apply(obj, editors, n_out, func, varargin)
      
      %   APPLY -- Apply a function to each editor.
      %
      %     IN:
      %       - `editors` (cell array of FigureEdit)
      %       - `n_out` (0 or 1) -- Number of outputs to request from
      %         `func`.
      %       - `func` (function_handle)
      %       - `varargin` (/any/) -- Any additional arguments to pass to
      %         `func`.
      
      if ( n_out == 0 )
        cellfun( @(x) func(x, varargin{:}), editors );
        return;
      else
        assert( n_out == 1, 'Cannot currently request more than one output.' );
      end
      out1 = cellfun( @(x) func(x, varargin{:}), editors, 'un', false );
    end
    
    function activate(obj, ind)
      
      %   ACTIVATE -- Make editors active or inactive.
      %
      %     obj.activate(), without additional arguments, activates all
      %     editors. Any subsequent operations, such as updating
      %     limits, axes formatting, etc. will be applied to all editors.
      %
      %     obj.activate(0) inactivates all editors.
      %
      %     obj.activate(1) activates the first FigureEdit object in
      %     `obj.editors`.
      %
      %     obj.activate( [1, 3] ) activates the first and third editor.
      %
      %     obj.activate( 'rwd' ) activates the editor(s) whose filenames
      %     contain the string 'rwd'. An error is thrown if no matching
      %     filenames are found.
      %
      %     obj.activate( {'rwd', 'choice'} ) activate the editor(s) whose
      %     filenames contain the strings 'rwd' AND 'choice'. An error is
      %     thrown if no matching filenames are found.
      %
      %     IN:
      %       - `ind` (number, char) |OPTIONAL|
      
      try
        obj.assert__some_editors();
        if ( nargin == 2 )
          if ( ischar(ind) )
            fnames = obj.filenames;
            contents = cellfun( @(x) ~isempty(strfind(x, ind)), fnames );
            assert( any(contents), ['No filenames matched the selector' ...
              , ' ''%s''.'], ind );
            ind = find( contents );
          elseif ( iscell(ind) )
            assertions.assert__iscellstr( ind, 'the filename selectors' );
            fnames = obj.filenames;
            contents = true( size(fnames) );
            for i = 1:numel(ind)
              contents = contents & ...
                cellfun( @(x) ~isempty(strfind(x, ind{i})), fnames );
            end
            assert( any(contents), ['No filenames matched the given' ...
              , ' selectors.'] );
            ind = find( contents );
          else
            assertions.assert__isa( ind, 'double', 'the editor index' );
            if ( isscalar(ind) && ind == 0 )
              obj.active = {};
              return;
            else
              FigureEdit.assert__index_in_bounds( ind, numel(obj.editors) );
            end
          end
        else
          ind = 1:numel( obj.editors );
        end
        obj.active = obj.editors( ind );
      catch err
        throwAsCaller( err );
      end
    end
    
    function close(obj)
      
      %   CLOSE -- Close the figures associated with the active editors.
      
      try
        obj.assert__some_active();
        obj.apply( obj.active, 0, @close );
      catch err
        throwAsCaller( err );
      end
    end
    
    function reopen(obj)
      
      %   REOPEN -- Reopen closed figures.
      
      try
        obj.assert__some_active();
        fnames = obj.filenames;
        obj.reset();
        obj.open( fnames );
      catch err
        throwAsCaller( err );
      end
    end
    
    function lims = xlim(obj, varargin)
      
      %   XLIM -- Change the x limits of each active editor.
      %
      %     See also FigureEdit/xlim FigureEdits/activate
      
      try
        obj.assert__some_active();
        lims = obj.apply( obj.active, 1, @xlim, varargin{:} );
      catch err
        throwAsCaller( err );
      end
    end
    
    function lims = ylim(obj, varargin)
      
      %   YLIM -- Change the y limits of each active editor.
      %
      %     See also FigureEdit/ylim FigureEdits/activate
      
      try
        obj.assert__some_active();
        lims = obj.apply( obj.active, 1, @ylim, varargin{:} );
      catch err
        throwAsCaller( err );
      end
    end
    
    function lims = clim(obj, varargin)
      
      %   CLIM -- Change the c limits of each active editor.
      %
      %     See also FigureEdit/clim FigureEdits/activate
      
      try
        obj.assert__some_active();
        lims = obj.apply( obj.active, 1, @clim, varargin{:} );
      catch err
        throwAsCaller( err );
      end
    end
    
    function was = title(obj, varargin)
      
      %   TITLE -- Change the title of each active editor.
      %
      %     See also FigureEdit/title FigureEdits/activate
      
      try
        obj.assert__some_active();
        was = obj.apply( obj.active, 1, @title, varargin{:} );
      catch err
        throwAsCaller( err );
      end
    end
    
    function was = ylabel(obj, varargin)
      
      %   YLABEL -- Change the ylabel of each active editor.
      %
      %     See also FigureEdit/ylabel FigureEdits/activate
      
      try
        obj.assert__some_active();
        was = obj.apply( obj.active, 1, @ylabel, varargin{:} );
      catch err
        throwAsCaller( err );
      end
    end
    
    function was = xlabel(obj, varargin)
      
      %   XLABEL -- Change the xlabel of each active editor.
      %
      %     See also FigureEdit/xlabel FigureEdits/activate
      
      try
        obj.assert__some_active();
        was = obj.apply( obj.active, 1, @xlabel, varargin{:} );
      catch err
        throwAsCaller( err );
      end
    end
    
    function remove_legend(obj, varargin)
      
      %   REMOVE_LEGEND -- Remove a legend from the active figure(s).
      %
      %     obj.remove_legend() removes all legends from all active
      %     figures.
      %
      %     obj.remove_legend(1) removes the first legend in all active
      %     figures.
      %
      %     IN:
      %       - `varargin` (cell array) |OPTIONAL|
      
      narginchk( 1, 2 );
      try
        cellfun( @(x) x.remove_legend(varargin{:}), obj.active );
      catch err
        throwAsCaller( err );
      end
    end
    
    function one_legend(obj)
      
      %   ONE_LEGEND -- Remove all but one legend.
      
      try
        cellfun( @(x) x.one_legend(), obj.active );
      catch err
        throwAsCaller( err );
      end
    end
    
    function legend_replace(obj, varargin)
      
      %   LEGEND_REPLACE -- Replace text in legends with alternate text.
      %
      %     obj.legend_replace( 'ny', 'New York' ); replaces occurrences of
      %     'ny' in legends in the current figure(s) with 'New York'.
      %
      %     obj.legend_replace( ..., [1, 3] ) only performs the replacement
      %     in the first and third legend in the figure(s).
      %
      %     See also FigureEdit/legend_replace
      %
      %     IN:
      %       - `varargin` (cell array)
      
      try
        cellfun( @(x) x.legend_replace(varargin{:}), obj.active );
      catch err
        throwAsCaller( err );
      end
    end
    
    function title_replace(obj, varargin)
      
      %   TITLE_REPLACE -- Replace text in titles with alternate text.
      %
      %     obj.title_replace( 'ny', 'New York' ); replaces occurrences of
      %     'ny' in titles of the current figure(s) with 'New York'.
      %
      %     obj.title_replace( ..., [1, 3] ) only performs the replacement
      %     in the first and third title of the figure(s).
      %
      %     See also FigureEdit/legend_replace
      %
      %     IN:
      %       - `varargin` (cell array)
      
      try
        cellfun( @(x) x.title_replace(varargin{:}), obj.active );
      catch err
        throwAsCaller( err );
      end
    end
    
    function undo(obj)
      
      %   UNDO -- Undo the previous action.
      
      cellfun( @(x) x.undo(), obj.active );
    end
    
    function revert(obj)
      
      %   REVERT -- Revert each active figure to its original state.
      
      cellfun( @(x) x.revert(), obj.active );
    end
    
    function distribute(obj, scale)
      
      %   DISTRIBUTE -- Distribute the active figures on screen.
      %
      %     obj.distribute() arranges the figures in `obj.active` so that
      %     they are maximally evenly distributed on the full screen.
      %
      %     obj.distribute( .5 ) uses half of the diagonal screen space.
      %
      %     obj.distribute( [.5, 1] ) uses half of the horizontal, and all
      %     of the vertical screen space.
      %
      %     IN:
      %       - `scale` (number) |OPTIONAL|
      
      if ( nargin == 1 )
        scale = [1, 1]; 
      else
        obj.assert__n_elements_in_range( numel(scale), 1, 2, 'the scale' );
      end
      if ( numel(scale) == 1 ), scale = [ scale, scale ]; end
      obj.assert__some_active();
      cellfun( @(x) x.assert__figure_open(), obj.active );
      N = numel( obj.active );
      if ( N <= 3 )
        rows = 1;
        cols = N;
      else
        rows = round( sqrt(N) );
        cols = ceil( N/rows );
      end
      stp = 1;
      width = 1/cols * scale(1);
      height = 1/rows * scale(2);
      for i = 1:rows
        for j = 1:cols
          if ( stp > N ), return; end
          curr = obj.active{stp};
          fig = curr.figure;
          fig.Units = 'normalized';
          x0 = (j-1) * width;
          y0 = (i-1) * height;
          fig.OuterPosition = [x0, y0, width, height];
          stp = stp + 1;
        end
      end
    end
    
    function shift(obj, amt)
      
      %   SHIFT -- Move the active figure(s) by a given amount.
      %
      %     obj.shift( .1 ) moves each active figure .1 units left and up,
      %     relative to the bottom-left corner of the screen. Units are
      %     normalized such that 1 is the full width and height of the
      %     screen.
      %
      %     obj.shift( [.1, 0] ) moves each active figure .1 units left,
      %     and 0 units up.
      
      try
        obj.assert__n_elements_in_range( numel(amt), 1, 2, 'the shift amount' );
        if ( numel(amt) == 1 ), amt = [ amt, amt ]; end
        for i = 1:numel(obj.active)
          curr = obj.active{i}.figure;
          curr.Units = 'normalized';
          pos = curr.Position;
          pos(1:2) = pos(1:2) + amt;
          curr.Position = pos;
        end
      catch err
        throwAsCaller( err );
      end
    end
    
    function shift_x(obj, amt)
      
      %   SHIFT_X -- Move the active figure(s) left or right.
      %
      %     IN:
      %       - `amt` (double) -- Single number specifying the
      %         x-displacement
      
      try
        obj.assert__n_elements_in_range( numel(amt), 1, 1 );
        obj.shift( [amt, 0] );      
      catch err
        throwAsCaller( err );
      end
    end
    
    function shift_y(obj, amt)
      
      %   SHIFT_Y -- Move the active figure(s) up or down.
      %
      %     IN:
      %       - `amt` (double) -- Single number specifying the
      %         y-displacement
      
      try
        obj.assert__n_elements_in_range( numel(amt), 1, 1 );
        obj.shift( [0, amt] );
      catch err
        throwAsCaller( err );
      end
    end
    
    function show(obj)
      
      %   SHOW -- Bring the active figure(s) to the foreground.
      
      try
        obj.assert__some_active();
        cellfun( @(x) x.show(), obj.active );
      catch err
        throwAsCaller( err );
      end
    end
    
    function hide(obj)
      
      %   HIDE -- Make the active figure(s) invisible.
      
      try
        obj.assert__some_active();
        cellfun( @(x) x.hide(), obj.active );
      catch err
        throwAsCaller( err );
      end
    end
    
    function hide_inactive(obj)
      
      %   HIDE_INACTIVE -- Make the inactive figure(s) invisible.
      
      inactive = obj.get_inactive_editors();
      cellfun( @(x) x.hide(), inactive );
    end
    
    function reset(obj)
      
      %   RESET -- Remove all current FigureEdit objects.
      
      open_editors = obj.editors( obj.is_open() );
      cellfun( @(x) x.close(), open_editors );
      obj.filenames = {};
      obj.active = {};
      obj.editors = {};
    end
    
    function open(obj, fnames)
      
      %   OPEN -- Open figure(s).
      %
      %     obj.open( 'test.fig' ); opens the figure 'test.fig', and 
      %     activates it.
      %
      %     obj.open( {'test.fig', 'test2.fig'} ); opens those two figures,
      %     and activates them.
      %
      %     Any figures currently associated with the object are closed.
      %     Use `open_plus` to open figures without closing any current
      %     figures.
      %
      %     IN:
      %       - `fnames` (cell array of strings, char) -- Filenames.
      %
      %     See also FigureEdit/open FigureEdits/open_plus FigureEdits/activate
      
      assert( ~isempty(fnames), 'No filenames were specified.' );
      if ( ~isempty(obj.editors) )
        obj.close();
      end
      obj.reset();
      obj.open_plus( fnames );
    end
    
    function open_plus(obj, fnames)
      
      %   OPEN_PLUS -- Open figure(s) without closing current figures.
      %
      %     See also FigureEdits/open
      %
      %     IN:
      %       - `fnames` (cell array of strings, char) -- Filenames.
      
      try
        fnames = obj.ensure_cell( fnames );
        assertions.assert__iscellstr( fnames, 'the filenames' );
        for i = 1:numel(fnames)
          editor = FigureEdit();
          editor.open( fnames{i} );
          obj.editors{end+1} = editor;
        end
        obj.filenames = [obj.filenames, fnames];
        obj.activate();
      catch err
        throwAsCaller( err );
      end
    end
    
    function save(obj, pattern)
      
      %   SAVE -- Save all active figures.
      %
      %     obj.save() saves all active figures, overwriting the original
      %     files.
      %
      %     obj.save( 'new_%s' ) saves all active figures, appending 'new_'
      %     to each filename, such that each original file is not
      %     overwritten. The format string '%s' must be present in the
      %     filename pattern.
      
      if ( nargin == 1 )
        cellfun( @(x) x.save(), obj.active );
        return;
      end
      assertions.assert__isa( pattern, 'char', 'the filename pattern' );
      assert( ~isempty(strfind(pattern, '%s')), ['The filename pattern' ...
        , ' must include the string format specifier ''%s''.'] );
      fnames = obj.get_active_filenames();
      fnames = cellfun( @(x) sprintf(pattern, x), fnames, 'un', false );
      for i = 1:numel(fnames)
        obj.active{i}.save( fnames{i} );
      end
    end
    
    %{
        UTIL
    %}
    
    function disp(obj)
      
      %   DISP -- Pretty-print the object.
      
      active_files = get_raw_filenames( obj.get_active_filenames() );
      all_files = get_raw_filenames( obj.filenames );
      link_str = '<a href="matlab:helpPopup FigureEdits">FigureEdits</a>';
      n_active = numel( active_files );
      n_all = numel( all_files );
      if ( n_active > 0 )
        if ( n_active ~= n_all )
          fprintf( '%s\n\nActive .fig files: \n\n', link_str );
          display_files( active_files(:) );
        else
          fprintf( '%s\n\nActive (and all) .fig files: \n\n', link_str );
          display_files( active_files(:) );
          fprintf( '\n' );
          return;
        end
        fprintf( '\n' );
      elseif ( n_all > 0 )
        fprintf( '%s\n\nNo active .fig files. \n\n', link_str );
      else
        fprintf( '%s\n\nNo .fig files. Use `open` to add a figure.\n\n' ...
          , link_str );
        return;
      end
      fprintf( 'All .fig files: \n\n' );
      display_files( all_files(:) );
      function fnames_ = get_raw_filenames(fnames_)
        if ( ispc() )
          slash = '\';
        else
          slash = '/';
        end
        fnames_ = cellfun( @(x) strsplit(x, slash), fnames_, 'un', false );
        fnames_ = cellfun( @(x) x{end}, fnames_, 'un', false );
      end
      function display_files(files)        
        for i = 1:numel(files)
          ind = strcmp(all_files, files{i});
          editor = obj.editors{ind};
          is_open = editor.is_open();
          extra_str = '';
          if ( ~is_open ), extra_str = ' (closed)'; end
          fprintf( '    %s%s\n', files{i}, extra_str );
        end
      end
    end
    
    function inactive = get_inactive_editors(obj)
      
      %   GET_INACTIVE_EDITORS -- Return non-active editors.
      %
      %     If all editors are active, an empty cell is returned.
      %
      %     OUT:
      %       - `inactive` (cell array of FigureEdit, {})
      
      fnames = obj.filenames;
      active_fnames = obj.get_active_filenames();
      inactive_fnames = setdiff( fnames, active_fnames );
      inactive = {};
      for i = 1:numel(inactive_fnames)
        ind = strcmp( fnames, inactive_fnames{i} );
        inactive{end+1} = obj.editors{ind};
      end
    end
    
    function fnames = get_active_filenames(obj)
      
      %   GET_ACTIVE_FILENAMES -- Return filenames associated with the
      %     active figures.
      %
      %     OUT:
      %       - `fnames` (cell array of strings)
      
      fnames = cellfun( @(x) x.filename, obj.active, 'un', false );
    end
    
    function tf = is_open(obj)
      
      %   IS_OPEN -- Return whether a given editor has an open figure.
      
      if ( isempty(obj.editors) ), tf = false; return; end
      tf = cellfun( @(x) x.is_open(), obj.editors );
    end
    
    function assert__some_editors(obj)
      
      %   ASSERT__SOME_EDITORS -- Ensure at least one editor is present.
      
      assert( numel(obj.editors) > 0, ['No editors exist. Add an editor' ...
        , ' with the `open` or `open_plus` functions.'] );
    end
    
    function assert__some_active(obj)
      
      %   ASSERT__SOME_ACTIVE -- Ensure at least one active editor is 
      %     present.
      
      obj.assert__some_editors();
      assert( numel(obj.active) > 0, ['No active editors exist. Activate' ...
        , ' one or more editors with the `activate` function.'] );
    end
    
    function assert__valid_editor_index(obj, ind)
      
      %   ASSERT__VALID_EDITOR_INDEX -- Ensure a given index is within
      %     bounds of the `editors` property.
      
      assert( isscalar(ind) && ind > 0 && ind <= numel(obj.editors) ...
        , ['The given FigureEdit index is out of bounds. Expected the index' ...
        , ' to be a number between 1 and %d.'], numel(obj.editors) );
    end
  end
  
  methods (Static = true)
    
    function arr = ensure_cell(arr)
      
      %   ENSURE_CELL -- Ensure an input is a cell array.
      
      if ( ~iscell(arr) ), arr = { arr }; end
    end
    
    function assert__is_fig(f, kind)
      
      %   ASSERT__IS_FIG -- Ensure a variable is a figure.
      %
      %     IN:
      %       - `f` (/any/)
      %       - `kind` (char) |OPTIONAL| -- Variable description. Defaults
      %         to empty string.
      
      if ( nargin < 2 ), kind = 'input'; end      
      assertions.assert__isa( f, 'matlab.ui.Figure', kind );
    end
    
    function assert__n_elements(N, n, var_name)
      
      %   ASSERT__N_ELEMENTS -- Ensure a variable has exactly n elements.
      %
      %     IN:
      %       - `N` (double) -- Actual number of elements.
      %       - `n` (double) -- Expected number.
      %       - `var_name` (char) |OPTIONAL| -- Optionally provide a more
      %         verbose variable description, in case the assertion fails.
      %         Defaults to 'input'.
      
      if ( nargin < 4 ), var_name = 'input'; end
      assert( N == n, ['Expected %s to have %d elements; instead %d were' ...
        , ' present.'], var_name, n, N );
    end
    
    function assert__n_elements_in_range(N, low, high, var_name)
      
      %   ASSERT__N_ELEMENTS_IN_RANGE -- Ensure an array has at least x and
      %     at most y elements.
      %
      %     IN:
      %       - `N` (double) -- Actual number of elements.
      %       - `low` (double)
      %       - `high` (double)
      %       - `var_name` (char) |OPTIONAL| -- Optionally provide a more
      %         verbose variable description, in case the assertion fails.
      %         Defaults to 'input'.
      
      if ( nargin < 4 ), var_name = 'input'; end
      assert( N >= low && N <= high, ['Expected %s to have' ...
        , ' at least %d elements and at most %d elements; %d were' ...
        , ' present.'], var_name, low, high, N );
    end
  end
end