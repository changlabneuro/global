function structure__test()
%% CONSTRUCTOR -- The input struct must contain values of the same class

FAIL_MSG = ['UNCAUGHT: Structure/Structure -- A struct whose fields contained' ...
  , ' values of different classes was used as valid input to a new Structure'];

try
  s = struct( 'one', '1', 'two', 2 );
  structure = Structure( s );
  error( FAIL_MSG );
catch err
  assert( isequal(err.message, ...
    ['Instantiating a Structure requires a struct whose fields' ...
        , ' are values of the same class']), FAIL_MSG );

end

fprintf( ['\n - OK: Structure() did not allow a struct whose values were of' ...
  , '\n\tdifferent classes to be used as input to a new Structure'] );

%% COMPLETE

fprintf( '\n\n ALL TESTS PASSED\n\n' );

end