classdef rowops
  properties
    % //
  end
  
  methods
    
    function obj = rowops()
      % //
    end
    
    function disp(obj)
      
      fprintf([' This class contains functions that collapse\n data' ...
        , ' across the first dimension.\n\n These are the functions' ...
        , ' currently available:\n']);
      deets = ?rowops;
      names = arrayfun( @(x) x.Name, deets.MethodList, 'un', false );
      is_static = arrayfun( @(x) x.Static, deets.MethodList );
      names = names( is_static );
      for i = 1:numel(names)
        fprintf( '\n - rowops.%s', names{i} );
      end
      fprintf( '\n\n' );
    end
  end
  
  methods (Static = true)
    function y = sem(data)
      
      %   SEM_1D -- Standard error across the first dimension of data.
      %
      %     IN:
      %       - `data` (double)
      %     OUT:
      %       - `y` (double) -- Vector of size 1xM, where M is the number
      %       of columns in `data`.
      
      N = size( data, 1 );
      y = std( data, [], 1 ) / sqrt( N );
    end
    
    function data = mean(data)
      
      %   MEAN_1D -- Mean across first dimension.
      
      data = mean( data, 1 );
    end
    
    function data = nanmean(data)
      
      %   NANMEAN_1D -- Mean across first dimension, after removing NaNs.
      
      data = nanmean( data, 1 );
    end
    
    function data = nanmedian(data)
      
      %   NANMEDIAN_1D -- Median across first dimension, after removing 
      %     NaNs.
      
      data = nanmedian( data, 1 );
    end
    
    function data = median(data)
      
      %   MEDIAN_1D -- Median across first dimension.
      
      data = median( data, 1 );
    end
    
    function data = std(data)
      
      %   STD_1D -- Standard deviation across first dimension. 
      
      data = std( data, [], 1 );
    end
    
    function data = nanstd(data)
      
      %   NANSTD_1D -- Standard deviation across first dimension, after
      %     removing NaNs.
      
      data = nanstd( data, [], 1 );
    end
    
    function data = min(data)
      
      %   MIN_1D -- Minimum across the first dimension.
      
      data = min( data, [], 1 );
    end
    
    function data = max(data)
      
      %   MAX_1D -- Maximum across the first dimension.
      
      data = max( data, [], 1 );
    end
  end
end