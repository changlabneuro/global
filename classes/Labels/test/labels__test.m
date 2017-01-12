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
	msg = ['The index must be a column vector with the same number' ...
          , ' of rows as the object (3). The inputted index had (2) elements'];
  assert( isequal(err.message, msg), FAIL_MSG );
end

fprintf( '\n - OK: keep() failed when the index was improperly dimensioned' );

%{
    TEST -- when calling replace(), all to-be-replaced values should reside
    in the same field
%}

FAIL_MSG = 'UNCAUGHT: Labels in different fields were allowed to be replaced';

try
  s = struct( ...
    'outcomes', {{ 'self'; 'both'; 'other' }}, ...
    'rewards', {{ 'high'; 'low'; 'high' }} );
  labels = Labels( s );
  labels = replace( labels, {'self', 'low'}, 'medium' );
  error( FAIL_MSG );
catch err
  msg = 'It is an error to replace an element in multiple fields';
  assert( isequal(err.message, msg), FAIL_MSG );
end

fprintf( ['\n - OK: replace() failed when attempting to replace labels in' ...
  , '\n\t multiple fields'] );

%{
    TEST -- rename_field() should fail when the new name already exists in
    the object
%}
  
FAIL_MSG = 'UNCAUGHT: A field was renamed to a field that already exists in the object';
  
try
  s = struct( ...
    'outcomes', {{ 'self'; 'both'; 'other' }}, ...
    'rewards', {{ 'high'; 'low'; 'high' }} );
  labels = Labels( s );
  labels = rename_field( labels, 'outcomes', 'rewards' );
  error( FAIL_MSG );
catch err
  msg = 'The name ''rewards'' is already a field in the object';
  assert( isequal(err.message, msg), FAIL_MSG );
end

fprintf( ['\n - OK: rename_field() failed when the new field name was' ...
  , '\n\t already in the object'] );

%{
    TEST -- set_field() should fail when any of the new labels are in
    another field
%}
  
FAIL_MSG = 'UNCAUGHT: New labels were allowed to be placed in multipled fields';

try
  s = struct( ...
    'outcomes', {{ 'self'; 'both'; 'other' }}, ...
    'rewards', {{ 'high'; 'low'; 'high' }} );
  labels = Labels( s );
  labels = set_field( labels, 'rewards', 'self' );
  error( FAIL_MSG );
catch err
  msg = ['Cannot assign ''self'' to field ''rewards'' because it' ...
    , ' already exists in field ''outcomes''' ];
  assert( isequal(err.message, msg), FAIL_MSG );
end

fprintf( ['\n - OK: set_field() failed when the new labels were already' ...
  , '\n\tin a different field'] );

%{
    TEST -- set_field() should fail when the index is improperly
    dimensioned
%}
  
FAIL_MSG = ['UNCAUGHT: An improperly dimensioned index was used to set' ...
  , ' the locations of new labels'];

try
  s = struct( ...
    'outcomes', {{ 'self'; 'both'; 'other' }}, ...
    'rewards', {{ 'high'; 'low'; 'high' }} );
  labels = Labels( s );
  labels = set_field( labels, 'rewards', 'medium', true(10, 1) );
  error( FAIL_MSG );
catch err
  msg = ['The index must be a column vector with the same number of rows' ...
          , ' as the object (3). The inputted index had (10) elements'];
  assert( isequal(err.message, msg), FAIL_MSG );
end

fprintf( '\n - OK: set_field() failed when the index was improperly dimensioned' );

%{
    TEST -- set_field() should fail when the number of true elements in the
    index does not match the number of elements to assign
%}

FAIL_MSG = ['UNCAUGHT: An index was used to set a field of labels, but it did not' ...
  , ' have the appropriate / corresponding number of true elements'];

try
  s = struct( ...
    'outcomes', {{ 'self'; 'both'; 'other' }}, ...
    'rewards', {{ 'high'; 'low'; 'high' }} );
  labels = Labels( s );
  labels = set_field( labels, 'rewards', {'medium'; 'low'}, true(3, 1) );
  error( FAIL_MSG );
catch err
  msg = 'Attempting to assign too many or too few labels to the field ''rewards''';
  assert( isequal(err.message, msg), FAIL_MSG );
end

fprintf( ['\n - OK: set_field() failed when the number of true elements in the' ...
  , '\n\tindex did not match the number of labels to set'] );

%{
    TEST -- where() should return an all-false index when the desired label
    is not in the object
%}
  
FAIL_MSG = 'UNCAUGHT: where() reported the existence of non-present labels';

s = struct( ...
  'outcomes', {{ 'self'; 'both'; 'other' }}, ...
  'rewards', {{ 'high'; 'low'; 'high' }} );
labels = Labels( s );
ind = where( labels, 'yellow' );

assert( ~any(ind), FAIL_MSG );

fprintf( ['\n - OK: where() returned an all-false index when the requested label' ...
  , ' \n\t was not in the object'] );

%{
    TEST -- when all the searched-for labels are in different fields, the
    index should be empty if there are no rows for which all labels are
    found
%}
  
FAIL_MSG = [ 'UNCAUGHT: where() returned an index with at least one true value,' ...
  , ' but in reality, no rows matched the search-terms' ];

s = struct( ...
  'outcomes', {{ 'self'; 'both'; 'other' }}, ...
  'rewards', {{ 'high'; 'low'; 'high' }}, ...
  'trials', {{ 'choice'; 'choice'; 'cued' }} );
labels = Labels( s );
ind = where( labels, {'both', 'high', 'choice'} );

assert( ~any(ind), FAIL_MSG );

fprintf( ['\n - OK: where() returned an all-false index when the requested labels' ...
  , ' \n\t were in the object, but not ever found in the same row'] );

%{
    TEST -- when some of the searched-for labels are in overlapping fields,
    the index should be true at rows for which *either* of the labels in
    the overlapping fields are found.
%}
  
  
FAIL_MSG = [ 'UNCAUGHT: where() returned an incorrect index when the search labels' ...
  , ' \n\t were drawn from overlapping fields' ];

s = struct( ...
  'outcomes', {{ 'self'; 'both'; 'other' }}, ...
  'rewards', {{ 'high'; 'low'; 'high' }}, ...
  'trials', {{ 'choice'; 'choice'; 'cued' }} );
labels = Labels( s );
ind = where( labels, {'both', 'self', 'high', 'choice'} );

assert( sum(ind) == 1 & find(ind) == 1, FAIL_MSG );

fprintf( ['\n - OK: where() correctly identified rows when search-labels' ...
  , ' \n\t were drawn from overlapping fields'] );

%{
  
    TEST -- overwrite() should fail when the index is improperly
    dimensioned
  
%}
  
FAIL_MSG = ['UNCAUGHT: overwrite() allowed an improperly dimensioned index' ...
  , '\n\tto be used to set labels'];

try
  s = struct( ...
    'outcomes', {{ 'self'; 'both'; 'other' }}, ...
    'rewards', {{ 'high'; 'low'; 'high' }} );
  labels = Labels( s );
  ind = true( shape(labels,1), 1); ind(1) = false;
  labels2 = keep( labels, ind );
  labels = overwrite( labels, labels2, ~ind );
  error( FAIL_MSG );
catch err
  msg = [ 'The number of true elements in the index must match the number' ...
    , '\n of rows in the incoming object' ];
  assert( isequal(err.message, msg), FAIL_MSG );
end

fprintf( ['\n - OK: overwrite() failed when the number of elements in the' ...
  , '\n\tincoming object did not match the number of true elements in the index' ] );

%{
    TEST -- overwrite() should succeed when the index matches the shape of
    the assigned-to object; when the number of true elements match the 
    number of rows of the assigning object; and when the fields of the two
    objects match
%}
  
FAIL_MSG = 'UNCAUGHT: overwrite() did not successfully assign new values';

s = struct( ...
  'outcomes', {{ 'self'; 'both'; 'other' }}, ...
  'rewards', {{ 'high'; 'low'; 'high' }} );
s2 = struct( ...
  'outcomes', {{ 'NONE'; 'NONE'; }}, ...
  'rewards', {{ 'medium'; 'medium'; }} );
labels = Labels( s );
labels2 = Labels( s2 );
ind = create_index( labels, false );
ind(1:shape(labels2, 1)) = true;
labels = overwrite( labels, labels2, ind );
assert( contains(labels, 'NONE') & contains(labels, 'medium'), ...
  FAIL_MSG );

fprintf( ['\n - OK: overwrite() succeeded when the assigned-to and assigning' ...
  , '\n\tobjects had equivalent fields; when the index was properly dimensioned;' ...
  , '\n\tand when the number of true elements in the index matched the number' ...
  , '\n\tof rows in the assigning object'] );


%{
    PASSED
%}

fprintf( '\n\n ALL TESTS PASSED\n\n' );

end