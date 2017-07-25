function assert__iscellstr(var, var_name)
      
%   ASSERT__ISA -- Ensure a variable is a cell array of strings.
%
%     IN:
%       - `var` (/any/) -- Variable to check.
%       - `var_name` (char) |OPTIONAL| -- Optionally provide a more
%         descriptive name for the variable in case the assertion
%         fails.

if ( nargin < 2 ), var_name = 'input'; end
assert( iscellstr(var), ['Expected %s to be a cell array of strings;' ...
  , ' was a ''%s''.'], var_name, class(var) );

end