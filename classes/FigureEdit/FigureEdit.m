classdef FigureEdit < handle
  
  properties
    filename = NaN;
    figure = NaN;
    axes = [];
    history = {};
    future = {};
  end
  
  methods
    function obj = FigureEdit( f )
      
      %   FIGUREEDIT -- Instantiate a FigureEdit object.
      %
      %     obj = FigureEdit( f ), where `f` is a handle to a Matlab
      %     figure, returns a new editor associated with `f`.
      %
      %     obj = FigureEdit( f ), where `f` is a filename, opens the .fig
      %     file `f`, if it exists, and returns a new editor associated
      %     with that figure.
      %
      %     IN:
      %       - `f` (char, matlab.ui.Figure)
      
      if ( nargin == 0 ), return; end
      if ( isa(f, 'char') )
        obj.assert__file_exists(f);
        f = openfig( f );
      end
      obj.figure = f;
      obj.filename = f.Name;
      obj.axes = FigureEdit.get_axes_in_figure( f );
      linkaxes( obj.axes, 'off' );
    end
    
    function was = xlim(obj, val, varargin)
      
      %   XLIM -- Set the xlim property of the current figure.
      %
      %     IN:
      %       - `val` (double)
      %       - `varargin` (cell array) |OPTIONAL| -- Axes index.
      %     OUT:
      %       - `was` (double) -- Previous x limits
      
      axs = obj.get_axes( varargin{:} );
      was = get( axs, 'xlim' );
      prop = 'xlim';
      if ( nargin > 1 && ~isempty(val) )
        obj.set_ax_val( axs, prop, was, val );
      end
    end
    
    function was = ylim(obj, val, varargin)
      
      %   YLIM -- Set the ylim property of the current figure.
      %
      %     IN:
      %       - `val` (double)
      %       - `varargin` (cell array) |OPTIONAL| -- Axes index.
      %     OUT:
      %       - `was` (double) -- Previous y limits
      
      axs = obj.get_axes( varargin{:} );
      was = get( axs, 'ylim' );
      prop = 'ylim';
      if ( nargin > 1 && ~isempty(val) )
        obj.set_ax_val( axs, prop, was, val );
      end
    end
    
    function was = clim(obj, val, varargin)
      
      %   CLIM -- Set the clim property of the current figure.
      %
      %     IN:
      %       - `val` (double)
      %       - `varargin` (cell array) |OPTIONAL| -- Axes index.
      %     OUT:
      %       - `was` (double) -- Previous color limits
      
      axs = obj.get_axes( varargin{:} );
      was = get( axs, 'clim' );
      prop = 'clim';
      if ( nargin > 1 && ~isempty(val) )
        obj.set_ax_val( axs, prop, was, val );
      end
    end
    
    function was = title(obj, val, varargin)
      
      %   TITLE -- Get or set the title property of the current figure.
      %
      %     current = obj.title() returns the current title(s) of each axis
      %     in `obj.axes`.
      %
      %     obj.title( 'test' ) adds the title 'test' to each axis in
      %     `obj.axes.`
      %
      %     obj.title( 'test', 1 ) adds the title 'test' to only the first
      %     axis.
      %
      %     was = obj.title( ... ) returns the previous title(s) before
      %     setting new value(s).
      %
      %     See also FigureEdit/ylabel FigureEdit/xlim
      
      axs = obj.get_axes( varargin{:} );
      if ( nargin > 1 )
        was = obj.text_setter( axs, 'title', val );
      else
        was = get( axs, 'title' );
      end
    end
    
    function was = ylabel(obj, val, varargin)
      
      %   YLABEL -- Get or set the ylabel property of the current figure.
      %
      %     current = obj.ylabel() returns the current ylabels(s) of each
      %     axis in `obj.axes`.
      %
      %     obj.ylabel( 'test' ) adds the ylabel 'test' to each axis in
      %     `obj.axes.`
      %
      %     obj.ylabel( 'test', 1 ) adds the ylabel 'test' to only the
      %     first axis.
      %
      %     was = obj.ylabel( ... ) returns the previous ylabels(s) before
      %     setting new value(s).
      %
      %     See also FigureEdit/title FigureEdit/ylim
      
      axs = obj.get_axes( varargin{:} );
      if ( nargin > 1 )
        was = obj.text_setter( axs, 'ylabel', val );
      else
        was = get( axs, 'ylabel' );
      end
    end
    
    function was = xlabel(obj, val, varargin)
      
      %   XLABEL -- Get or set the xlabel property of the current figure.
      %
      %     current = obj.xlabel() returns the current xlabels(s) of each
      %     axis in `obj.axes`.
      %
      %     obj.xlabel( 'test' ) adds the xlabel 'test' to each axis in
      %     `obj.axes.`
      %
      %     obj.xlabel( 'test', 1 ) adds the xlabel 'test' to only the
      %     first axis.
      %
      %     was = obj.xlabel( ... ) returns the previous xlabels(s) before
      %     setting new value(s).
      %
      %     See also FigureEdit/ylabel FigureEdit/ylim
      
      axs = obj.get_axes( varargin{:} );
      if ( nargin > 1 )
        was = obj.text_setter( axs, 'xlabel', val );
      else
        was = get( axs, 'xlabel' );
      end
    end
    
    function was = text_setter(obj, axs, prop, val)
      
      %   TEXT_SETTER -- Update a text property of the current figure.
      %
      %     `text_setter` is the generalized form of update to 
      
      was = get( axs, prop );
      msg = sprintf( 'the %s string', prop );
      assertions.assert__isa( val, 'char', msg );
      if ( nargin > 1 && ~isempty(val) )
        labels = cell( numel(axs), 1 );
        for i = 1:numel(axs)
          labels{i} = text( 'String', val );
        end
        obj.set_ax_val( axs, prop, was, labels );
      end
    end
    
    function was = square(obj, varargin)
      
      %   SQUARE -- Make axes square.
      %
      %     IN:
      %       - `varargin` (cell array) -- Optionally pass in an axis
      %         index, or omit to apply to all axes.
      
      axs = obj.get_axes( varargin{:} );
      was = arrayfun( @(x) x.DataAspectRatio, axs, 'un', false );
      curr = cell( size(was) );
      for i = 1:numel(was)
        curr{i} = [was{i}(1), was{i}(1), was{i}(3)];
      end
      obj.set_ax_val( axs, 'DataAspectRatio', was, curr );
    end
    
    function remove_legend(obj, ind)
      
      %   REMOVE_LEGEND -- Remove legend(s) from the associated figure.
      %
      %     obj.remove_legend() removes all legends in the figure.
      %     obj.remove_legend(1) removes the first legend in the figure.
      %     obj.remove_legend([1, 3]) removes the first and third legends
      %     in the figure.
      %
      %     IN:
      %       - `ind` (double) |OPTIONAL| -- Index or indices of the
      %         legends to remove.
      
      h_leg = findobj( obj.figure, 'Tag', 'legend' );
      assert( numel(h_leg) > 0, 'There are no legends to remove.' );
      if ( nargin == 1 )
        ind = 1:numel( h_leg );
      else
        obj.assert__index_in_bounds( ind, numel(h_leg) );
      end
      subset = h_leg( ind );
      set( subset, 'Visible', 'off' );
      history_item = { @(x) set(subset, 'Visible', 'on'), {} };
      obj.history{end+1} = history_item;
    end
    
    function axs = get_axes(obj, inds)
      
      %   GET_AXES -- Get the axes associated with the given indices, or
      %     all axes.
      %
      %     axs = obj.get_axes() returns the 'axes' property of the object.
      %     axs = obj.get_axes(1) returns the first axis in the 'axes'
      %     property of the object.
      %
      %     IN:
      %       - `inds` (double) |OPTIONAL| -- Index of axes to obtain.
      
      obj.assert__figure_defined();
      if ( nargin < 2 )
        axs = obj.axes;
      else
        axs = obj.get_axes_by_indices( inds );
      end
    end
    
    function axs = get_axes_by_indices(obj, inds)
      
      %   GET_AXES_BY_INDICES -- Return the axes associated with the given
      %     numeric indices.
      %
      %     IN:
      %       - `inds` (double)
      %     OUT:
      %       - `axs` (axes)
      
      assertions.assert__isa( inds, 'double', 'the numeric axes indices' );
      assert( max(inds) <= numel(obj.axes) && min(inds) > 0, ['The given' ...
        , ' numeric axes indices are out of bounds.'] );
      axs = obj.axes( inds );
    end
    
    function set.figure(obj, fig)
      
      %   SET.FIGURE -- Update the 'figure' property.
      %
      %     IN:
      %       - `fig` (figure handle)
      
      assertions.assert__isa( fig, 'matlab.ui.Figure', 'the figure handle' );
      obj.figure = fig;
      obj.axes = FigureEdit.get_axes_in_figure( fig );
      linkaxes( obj.axes, 'off' );
    end
    
    function open(obj, filename)
      
      %   OPEN -- Open a figure.
      %
      %     IN:
      %       - `filename` (char)
      
      if ( obj.is_open() ), obj.close(); end
      FigureEdit.assert__file_exists( filename );
      try
        obj.figure = openfig( filename );
      catch err
        throwAsCaller( err );
      end
      obj.filename = filename;
    end
    
    function close(obj)
      
      %   CLOSE -- Close the current figure.
      
      obj.assert__figure_defined();
      if ( ~obj.is_open() ), return; end
      try
        close( obj.figure );
      catch err
        warning( ['Could not close figure. The following error ocurred: \n' ...
          , ' %s'], err.message );
      end
    end
    
    function show(obj)
      
      %   SHOW -- Show the current figure.
      
      obj.assert__figure_defined();
      obj.assert__figure_open();
      figure( obj.figure.Number ); %#ok<*CPROP>
      set( obj.figure, 'Visible', 'on' );
    end
    
    function hide(obj)
      
      %   HIDE -- Hide the current figure.
      
      obj.assert__figure_defined();
      obj.assert__figure_open();
      set( obj.figure, 'Visible', 'off' );
    end
    
    function save(obj, filename)
      
      %   SAVE -- Save the current figure.
      %
      %     save( obj ) saves the current figure with the filename as
      %     specified in obj.filename.
      %
      %     save( obj, filename ) saves as `filename`. In this case,
      %     `filename` cannot already exist.
      %
      %     IN:
      %       - `filename` (char) |OPTIONAL|
      
      obj.assert__figure_defined();
      if ( nargin == 1 )
        obj.assert__filename_defined();
        filename = obj.filename;
      else
        FigureEdit.assert__file_does_not_exist( filename );
      end
      saveas( obj.figure, filename, 'fig' );
    end
    
    function varargout = undo(obj)
      
      %   UNDO -- Undo the previous action.
      
      if ( isempty(obj.history) )
        fprintf( '\n Nothing to undo.\n\n' );
        return;
      end
      last = obj.history{end};
      func = last{1};
      args = last{2};
      [varargout{1:nargout()}] = func( args{:} );
      obj.future{end+1} = last;
      obj.history(end) = [];
    end
    
    function revert(obj)
      
      %   REVERT -- Revert the figure to its original state.
      
      while ( ~isempty(obj.history) ), obj.undo(); end
    end
    
    function varargout = redo(obj)
      
      %   REDO -- Redo the previous action.
      
      if ( isempty(obj.future) ), return; end
      last = obj.future{end};
      func = last{1};
      args = last{2};
      [varargout{1:nargout()}] = func( args{:} );
      obj.history{end+1} = last;
      obj.future(end) = [];
    end
    
    function reset(obj)
      
      %   RESET -- Clear the history and future properties.
      
      obj.history = {};
      obj.future = {};
    end
    
    function set_ax_val(obj, axs, prop, was, val)
      
      %   SET_AX_VAL -- Set an axes value.
      %
      %     IN:
      %       - `axs` (array of axes handles)
      %       - `prop` (char) -- Property name.
      %       - `was` (/any/) -- Previous value, before setting.
      %       - `val` (/any/) -- Value to set.
      
      assertions.assert__isa( prop, 'char', 'the property name' );
      assertions.assert__isa( axs, 'matlab.graphics.axis.Axes' ...
        , ' the axes' );
      if ( ~iscell(val) )
        set( axs, prop, val );
      else
        for i = 1:numel(axs)
          set( axs(i), prop, val{i} );
        end
      end
      if ( numel(axs) == 1 && ~iscell(was) )
        was_ = { was };
      else
        was_ = was;
      end
      obj.history{end+1} = { @FigureEdit.set_ax, {axs, prop, was_} };
    end
    
    function tf = is_open(obj)
      
      %   IS_OPEN -- Return whether the figure is open.
      
      if ( ~obj.is_figure_defined() ), tf = false; return; end
      tf = obj.figure.isvalid;
    end
    
    function tf = is_figure_defined(obj)
      
      %   IS_FIGURE_DEFINED -- Return whether the figure propery contains a
      %     valid Matlab figure.
      
      tf = isa( obj.figure, 'matlab.ui.Figure' );
    end
    
    function assert__filename_defined( obj )
      
      %   ASSERT__FILENAME_DEFINED -- Ensure a filename has been defined.
      
      assert( ischar(obj.filename), 'No filename has been defined.' );
    end
    
    function assert__figure_defined(obj)
      
      %   ASSERT__FIGURE_DEFINED -- Ensure a figure has been defined.
      
      assert( obj.is_figure_defined(), 'No figure has been defined.' );
    end
    
    function assert__figure_closed(obj)
      
      %   ASSERT__FIGURE_CLOSED -- Ensure the figure has been closed.
      
      obj.assert__figure_defined();
      assert( ~obj.figure.isvalid, 'Expected the figure to be closed.' );
    end
    
    function assert__figure_open(obj)
      
      %   ASSERT__FIGURE_CLOSED -- Ensure the figure is open.
      
      obj.assert__figure_defined();
      assert( obj.figure.isvalid, 'Expected the figure to be open.' );
    end
  end
  
  methods (Static = true)    
    function ax = get_axes_in_figure( f )
      
      %   GET_AXES_IN_FIGURE -- Return the axes in figure `f`, if they 
      %     exist.
      %
      %     IN:
      %       - `f` (figure handle)
      %     OUT:
      %       - `ax` (axes, []) 
      
      assertions.assert__isa( f, 'matlab.ui.Figure', 'the figure handle' );
      h_axes = findobj( f, 'type', 'axes' );
      h_leg = findobj( h_axes, 'tag', 'legend' );
      ax = setdiff( h_axes, h_leg );
    end
    
    function set_ax(axs, prop, vals)
      
      %   SET_AX -- Set an axes property.
      %
      %     IN:
      %       - `axs` (array of axes handles)
      %       - `prop` (char) -- Propery name
      %       - `vals` (cell) -- Values, with respect to each `axs`(i)
      
      for i = 1:numel(axs)
        set( axs(i), prop, vals{i} );
      end
    end
    
    function assert__file_exists(fname)
      
      %   ASSERT__FILE_EXISTS -- Ensure a file exists.
      %
      %     IN:
      %       - `fname` (char)
      
      assertions.assert__isa( fname, 'char', 'the filename' );
      assert( exist(fname, 'file') == 2, ['The file ''%s'' does not' ...
        , ' exist.'], fname );
    end
    
    function assert__file_does_not_exist(fname)
      
      %   ASSERT__FILE_DOES_NOT_EXIST -- Ensure a file doesn't exist.
      %
      %     IN:
      %       - `fname` (char)
      
      assertions.assert__isa( fname, 'char', 'the filename' );
      assert( exist(fname, 'file') == 0, ['The file ''%s'' already' ...
        , ' exists.'], fname );
    end
    
    function assert__index_in_bounds(inds, N)
      
      %   ASSERT__VALID_NUMERIC_INDEX -- Ensure a numeric index has
      %     elements that are > 0, and <= the number of elements in the
      %     indexed array.
      %
      %     IN:
      %       - `inds` (double) -- Numeric index.
      %       - `N` (double) |SCALAR| -- Number of elements in the
      %         to-be-indexed array.
      
      assert( max(inds) <= N && min(inds) > 0, ['Expected' ...
        , ' the supplied index to contain elements greater than 0' ...
        , ' and at most %d.'], N );
    end
  end
  
end