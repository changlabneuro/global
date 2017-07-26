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
      
      %   ACTIVATE -- Make some or all editors active.
      %
      %     obj.activate(1) activates the first FigureEdit object in
      %     `obj.editors`. Any subsequent operations, such as updating
      %     limits, axes formatting, etc. will be applied to the that
      %     FigureEdit object, alone.
      %
      %     obj.activate(), without additional arguments, activates all
      %     editors.
      %
      %     IN:
      %       - `ind` (number) |OPTIONAL|
      
      try
        obj.assert__some_editors();
        if ( nargin == 2 )
          FigureEdit.assert__index_in_bounds( ind, numel(obj.editors) );
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
    
    function undo(obj)
      
      %   UNDO -- Undo the previous action.
      
      cellfun( @(x) x.undo(), obj.active );
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
    
    function show(obj)
      
      %   SHOW -- Bring figures to foreground.
      
      obj.assert__some_active();
      cellfun( @(x) x.show(), obj.active );
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
      if ( numel(active_files) > 0 )
        fprintf( '%s\n\nActive .fig files: \n\n', link_str );
        disp( active_files(:) );
      elseif ( numel(all_files) > 0 )
        fprintf( '%s\n\nNo active .fig files \n\n', link_str );
      else
        fprintf( '%s\n\nNo .fig files. \n\n', link_str );
        return;
      end
      fprintf( 'All .fig files: \n\n' );
      disp( all_files(:) );
      function fnames_ = get_raw_filenames(fnames_)
        if ( ispc() )
          slash = '\';
        else
          slash = '/';
        end
        fnames_ = cellfun( @(x) strsplit(x, slash), fnames_, 'un', false );
        fnames_ = cellfun( @(x) x{end}, fnames_, 'un', false );
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