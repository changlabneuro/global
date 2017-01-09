function labels__test()

%{
    TEST -- unequal number of elements is an error
%}

FAIL_MSG = 'UNCAUGHT: Fields had unequal numbers of elements';

try
  s = struct();
  s.outcomes = { 'self'; 'both' };
  s.trials = { 'choice'; 'cued'; 'none' };
  L = Labels( s );
  error( FAIL_MSG );
catch err
  assert( isequal(err.message,...
    'All fields of the input structure must have the same number of elements'), FAIL_MSG );
end

fprintf( '\n - OK: Did not allow fields to have different numbers of elements' );

%{ 
    TEST -- labels must be unique between fields
%}

FAIL_MSG = 'UNCAUGHT: Fields had overlapping labels';

try
  s = struct();
  s.outcomes = { 'self'; 'both' };
  s.trials = { 'choice'; 'cued' };
  s.rewards = { 'high'; 'both' };
  L = Labels( s );
  error( FAIL_MSG );
catch err
  assert( isequal(err.message,...
    'It is an error to have fields with duplicate labels'), FAIL_MSG );
end

fprintf( '\n - OK: Did not allow fields to have overlapping labels' );

%{
    TEST -- when preallocating, must begin with an empty object
%}

FAIL_MSG = 'UNCAUGHT: A populated object was allowed to be preallocated';

try
  s = struct();
  s.outcomes = { 'self'; 'both' };
  L = Labels( s );
  out = preallocate(L, 100);
  error( FAIL_MSG );
catch err
  assert( isequal(err.message,...
    'When preallocating, the starting object must be empty'), FAIL_MSG );
end

fprintf( '\n - OK: Did not allow a populated object to be preallocated' );


%{
    TEST -- the fields of two objects must match exactly, including in order,
    for the fields to be considered equivalent
%}

FAIL_MSG = ...
  'UNCAUGHT: Two objects with different fields were said to have matching fields';

s = struct( 'outcomes', {{ 'self' }}, 'rewards', {{ 'high' }} );
s1 = s;
l1 = Labels( s );
l2 = Labels( s1 );
l2.fields = { 'outcomes', 'rewards' };
l1.fields = { 'rewards', 'outcomes' };
assert( ~fields_match(l2, l1), FAIL_MSG );

fprintf( '\n - OK: Objects with different fields did not have matching fields' );

%{
    TEST -- The shapes of two objects must match exactly for their shapes
    to be considered equivalent
%}

FAIL_MSG = ...
  'UNCAUGHT: Two objects with different shapes were said to have matching shapes';

s = struct( 'outcomes', {{ 'self'; 'both' }}, 'rewards', {{ 'high'; 'low' }} );
s1 = struct( 'outcomes', {{ 'self' }}, 'rewards', {{ 'high' }} );
l1 = Labels( s );
l2 = Labels( s1 );
assert( ~shapes_match(l2, l1), FAIL_MSG );

fprintf( '\n - OK: Objects with different shapes did not have matching shapes' );

%{
    TEST -- Two objects with equivalent fields, shapes, and labels are
    considered equivalent
%}

FAIL_MSG = [ 'UNCAUGHT: Two objects with equivalent fields, shapes, and' ...
  , ' labels were not considered equivalent' ];

s = struct( 'outcomes', {{ 'self'; 'both' }}, 'rewards', {{ 'high'; 'low' }} );
s1 = s;
l1 = Labels( s );
l2 = Labels( s1 );
assert( eq(l2, l1), FAIL_MSG );

fprintf( ['\n - OK: Objects with equivalent fields, shapes, and labels were' ...
  , '\n\tconsidered equivalent'] );

%{
    TEST -- Two objects with different fields should not be able
    to be appended together
%}
  
FAIL_MSG = 'UNCAUGHT: Objects with incompatible fields were appended';

try
  s = struct( 'outcomes', {{ 'self'; 'both' }} );
  l1 = Labels( s );
  l2 = Labels();
  l1 = append( l1, l2 );
  error( FAIL_MSG );
catch err
  assert( isequal(err.message,...
    'Fields must match between objects'), FAIL_MSG );
end

fprintf( '\n - OK: append() failed when objects were of incompatible shapes and fields' );


%{
    TEST -- When attempting to keep() elements of an object, the index must
    be a column vector with the same number of elements as the number of
    rows in the object
%}

FAIL_MSG = ['UNCAUGHT: An index with incompatible size was used to keep elements' ...
  , ' in the object'];

try
  s = struct( 'outcomes', {{ 'self'; 'both'; 'other' }} );
  l1 = Labels( s );
  ind = false( 2, 1 );  % two rows
  l1 = keep( l1, ind );
  error( FAIL_MSG );
catch err
  msg = ['The index must be a logical column vector with the same number' ...
          , ' of elements as shape(obj, 1)'];
  assert( isequal(err.message, msg), FAIL_MSG );
end

fprintf( '\n - OK: keep() failed when the index was improperly dimensioned' );


%{
    PASSED
%}

fprintf( '\n\n ALL TESTS PASSED\n\n' );

end