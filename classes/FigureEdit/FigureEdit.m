classdef FigureEdit < handle
  
  properties
    figure = NaN;
    axes = [];
  end
  
  methods
    function obj = FigureEdit( f )
      if ( nargin == 0 ), return; end
      obj.figure = f;
      obj.axes = FigureEdit.get_axes_in_figure( f );
      linkaxes( obj.axes, 'off' );
    end
    
    function xlim(obj, val, varargin)
      
      %   XLIM -- Set the xlim property of the current figure.
      %
      %     IN:
      %       - `val` (double)
      %       - `varargin` (cell array) |OPTIONAL| -- Axes index.
      
      axs = obj.get_axes( varargin{:} );
      set( axs, 'xlim', val );
    end
    
    function ylim(obj, val, varargin)
      
      %   YLIM -- Set the ylim property of the current figure.
      %
      %     IN:
      %       - `val` (double)
      %       - `varargin` (cell array) |OPTIONAL| -- Axes index.
      
      axs = obj.get_axes( varargin{:} );
      set( axs, 'ylim', val );
    end
    
    function clim(obj, val, varargin)
      
      %   CLIM -- Set the clim property of the current figure.
      %
      %     IN:
      %       - `val` (double)
      %       - `varargin` (cell array) |OPTIONAL| -- Axes index.
      
      axs = obj.get_axes( varargin{:} );
      set( axs, 'clim', val );
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
    
    function assert__figure_defined( obj )
      
      %   ASSERT__FIGURE_DEFINED -- Ensure a figure has been defined.
      
      assert( ~isnan(obj.figure), 'No figure has been defined.' );
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
  end
  
end