classdef FigureEdits < handle
  
  properties
    editors = {};
    active = {};
    filenames = {};
  end
  
  methods
    function obj = FigureEdits(fig_or_fname)
      
      %   FIGUREEDITS -- Instantiate a FigureEdits object.
      
      if ( nargin == 0 ), return; end
      fig_or_fname = FigureEdits.ensure_cell( fig_or_fname );
      if ( ~iscellstr(fig_or_fname) )
        try
          cellfun( @(x) FigureEdits.assert__is_fig(x), fig_or_fname );
        catch
          msg = ['Expected figure(s) to be either figure handles or' ...
            , ' filenames.'];
          error( msg );
        end
        figs = fig_or_fname;
        obj.editors = cellfun( @(x) FigureEdit(x), figs, 'un', false );
      else
        fnames = fig_or_fname;
        for i = 1:numel(fnames)
          editor = FigureEdit();
          editor.open( fnames{i} );
          obj.editors{end+1} = editor;
        end
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
      
      obj.assert__some_editors();
      if ( nargin == 2 )
        obj.assert__valid_editor_index( ind );
      else
        ind = 1:numel( obj.editors );
      end
      obj.active = obj.editors( ind );
    end
    
    function close(obj)
      
      %   CLOSE -- Close the figures associated with the active editors.

      obj.assert__some_active();
      obj.apply( obj.active, 0, @close );
    end
    
    function reopen(obj)
      
      %   REOPEN -- Reopen closed figures.
      
      obj.assert__some_active();
      obj.close();
      cellfun( @(x) x.reset(), obj.active );
      cellfun( @(x) x.open(x.filename), obj.active );
    end
    
    function lims = xlim(obj, varargin)
      
      %   XLIM -- Change the x limits of each active editor.
      %
      %     See also FigureEdit/xlim FigureEdits/activate
      
      obj.assert__some_active();
      lims = obj.apply( obj.active, 1, @xlim, varargin{:} );
    end
    
    function lims = ylim(obj, varargin)
      
      %   YLIM -- Change the y limits of each active editor.
      %
      %     See also FigureEdit/ylim FigureEdits/activate
      
      obj.assert__some_active();
      lims = obj.apply( obj.active, 1, @ylim, varargin{:} );
    end
    
    function lims = clim(obj, varargin)
      
      %   CLIM -- Change the c limits of each active editor.
      %
      %     See also FigureEdit/clim FigureEdits/activate
      
      obj.assert__some_active();
      lims = obj.apply( obj.active, 1, @clim, varargin{:} );
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
      %     obj.distribute(.5) arranges the active figures so that they
      %     take up half of the diagonal screen space.
      %
      %     IN:
      %       - `scale` (number) -- Scale the amount of space taken up by
      %         the distributed set of figures.
      
      if ( nargin == 1 ), scale = 1; end
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
      width = 1/cols * scale;
      height = 1/rows * scale;
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
      
      fnames = obj.ensure_cell( fnames );
      assertions.assert__iscellstr( fnames, 'the filenames' );
      for i = 1:numel(fnames)
        editor = FigureEdit();
        editor.open( fnames{i} );
        obj.editors{end+1} = editor;
      end
      obj.filenames = [obj.filenames, fnames];
      obj.activate();
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
  end
end