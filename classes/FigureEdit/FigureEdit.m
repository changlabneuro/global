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
      if ( nargin == 0 ), return; end
      obj.figure = f;
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
      
      FigureEdit.assert__file_exists( filename );
      obj.figure = openfig( filename );
      obj.filename = filename;
    end
    
    function close(obj)
      
      %   CLOSE -- Close the current figure.
      
      obj.assert__figure_defined();
      close( obj.figure );
    end
    
    function show(obj)
      
      %   SHOW -- Show the current figure.
      
      obj.assert__figure_defined();
      figure( obj.figure.Number ); %#ok<*CPROP>
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
      else
        FigureEdit.assert__file_does_not_exist( filename );
      end
      saveas( obj.figure, filename, 'fig' );
    end
    
    function varargout = undo(obj)
      
      %   UNDO -- Undo the previous action.
      
      if ( isempty(obj.history) ), return; end
      last = obj.history{end};
      func = last{1};
      args = last{2};
      [varargout{1:nargout()}] = func( args{:} );
      obj.future{end+1} = last;
      obj.history(end) = [];
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
    
    function assert__filename_defined( obj )
      
      %   ASSERT__FILENAME_DEFINED -- Ensure a filename has been defined.
      
      assert( ~isnan(obj.filename), 'No filename has been defined.' );
    end
    
    function assert__figure_defined( obj )
      
      %   ASSERT__FIGURE_DEFINED -- Ensure a figure has been defined.
      
      isfig = isa( obj.figure, 'matlab.ui.Figure' );
      assert( isfig, 'No figure has been defined.' );
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
  end
  
end