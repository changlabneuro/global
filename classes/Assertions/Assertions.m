classdef Assertions
  properties
  end
  
  methods (Static = true)
    function assert__isstruct(S, opts)
      if ( nargin < 2 ), opts.msg = 'Input must be a structure'; end;
      assert( isstruct(S), opts.msg );
    end
    
    function assert__is_cellstr(A, opts)
      if ( nargin < 2 ), opts.msg = 'Input must be a cell array of strings'; end;
      assert( iscellstr(A), opts.msg );
    end
    
    function assert__isa(A, kind, opts)
      if ( nargin < 3 ), opts.msg = sprintf( 'Input must be a `%s`', kind ); end;
      assert( isa(A, kind), opts.msg );
    end
    
    function assert__fields_exist(S, queries, opts)
      if ( nargin < 3 ), opts.msg = [ 'Required fields are: ' strjoin(queries) ]; end;
      fields = fieldnames(S);
      exists = cellfun( @(x) any(strcmp(queries, x)), fields );
      assert( all(exists), opts.msg );
    end
  end
end