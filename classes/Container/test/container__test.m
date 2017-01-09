function container__test()

%{
    TEST -- unequal number of elements is an error
%}

FAIL_MSG = 'UNCAUGHT: Data and labels had different dimensions';

try
  s = struct();
  s.outcomes = { 'self'; 'both' };
  s.trials = { 'choice'; 'cued'; };
  labels = Labels( s );
  data = zeros( 10, 1 );
  cont = Container( data, labels );
  error( FAIL_MSG );
catch err
  assert( isequal(err.message,...
    'Data must have the same number of rows as labels'), FAIL_MSG );
end

fprintf( '\n - OK: Did not allow data and labels to be improperly dimensioned' );

%{
    TEST -- when labels is a valid input to Labels, they should be
    converted to a Labels object internally
%}

FAIL_MSG = 'Labels were not able to be converted to a `Labels` object';

try
  s = struct();
  s.outcomes = { 'self'; 'both' };
  s.trials = { 'choice'; 'cued'; };
  data = zeros( 2, 1 );
  cont = Container( data, s );
catch
  error( FAIL_MSG );
end

fprintf( '\n - OK: Labels were properly converted into a Labels object' );

%{
    END
%}

fprintf( '\n\n ALL TESTS PASSED\n\n' );


end