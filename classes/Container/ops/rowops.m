classdef rowops
  properties (Constant)
    valid_types = { 'double', 'logical' };
  end
  
  methods
    
    function obj = rowops()
      
      %   ROWOPS -- Package containing functions that collapse data across
      %     the first dimension.
      %
      %     Functions herein accept an array or matrix as input and output 
      %     an array or matrix whose size is 1xNx... In other words, the 
      %     output arrays/ matrix will have one row, but the same size in 
      %     the remaining dimensions as the inputted array / matrix.
      %
      %     Ex. //
      %
      %     a = [10, 11, 12];
      %
      %     mean(a)         % -> 11
      %
      %     rowops.mean(a)  % -> [10, 11, 12]
      %
      %     See also Container/for_each_1d
      
    end
    
    function disp(obj)
      
      %   DISP -- List available functions.
      
      fprintf([' This class contains functions that collapse\n data' ...
        , ' across the first dimension.\n\n These are the functions' ...
        , ' currently available:\n']);
      deets = ?rowops;
      names = arrayfun( @(x) x.Name, deets.MethodList, 'un', false );
      is_static = arrayfun( @(x) x.Static, deets.MethodList );
      is_empty = strcmp( names, 'empty' );
      names = names( is_static & ~is_empty );
      cellfun( @(x) fprintf('\n - rowops.%s', x), names );
      fprintf( '\n\n' );
    end
  end
  
  methods (Static = true)
    function y = sem(data)
      
      %   SEM -- Standard error across the first dimension of data.
      %
      %     IN:
      %       - `data` (double)
      %     OUT:
      %       - `y` (double) -- Vector of size 1xM, where M is the number
      %       of columns in `data`.
      
      rowops.assert__valid_type( data );
      N = size( data, 1 );
      y = std( data, [], 1 ) / sqrt( N );
    end
    
    function data = mean(data)
      
      %   MEAN -- Mean across first dimension.
      
      rowops.assert__valid_type( data );
      data = mean( data, 1 );
    end
    
    function data = nanmean(data)
      
      %   NANMEAN -- Mean across first dimension, after removing NaNs.
      
      rowops.assert__valid_type( data );
      data = nanmean( data, 1 );
    end
    
    function data = nanmedian(data)
      
      %   NANMEDIAN -- Median across first dimension, after removing NaNs.
      
      rowops.assert__valid_type( data );
      data = nanmedian( data, 1 );
    end
    
    function data = median(data)
      
      %   MEDIAN -- Median across first dimension.
      
      rowops.assert__valid_type( data );
      data = median( data, 1 );
    end
    
    function data = std(data)
      
      %   STD -- Standard deviation across first dimension. 
      
      rowops.assert__valid_type( data );
      data = std( data, [], 1 );
    end
    
    function data = nanstd(data)
      
      %   NANSTD -- Standard deviation across first dimension, after
      %     removing NaNs.
      
      rowops.assert__valid_type( data );
      data = nanstd( data, [], 1 );
    end
    
    function data = min(data)
      
      %   MIN -- Minimum across the first dimension.
      
      rowops.assert__valid_type( data );
      data = min( data, [], 1 );
    end
    
    function data = max(data)
      
      %   MAX -- Maximum across the first dimension.
      
      rowops.assert__valid_type( data );
      data = max( data, [], 1 );
    end
    
    function assert__valid_type(data)
      
      %   ASSERT__VALID_TYPE -- Ensure data are of a valid class.
      
      vtypes = rowops.valid_types;
      assert( any(strcmp(vtypes, class(data))) ...
        , 'Expected data to be one of these types:\n%s\n\nInstead was ''%s.''' ...
        , strjoin(vtypes, ', '), class(data) );
    end
  end
end