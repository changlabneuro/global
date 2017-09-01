function cont = get_example_container()

%   GET_EXAMPLE_CONTAINER -- Return an instantiated Container object.

thisp = which( 'get_example_container.m' );
contp = which( 'Container.m' );
filename = 'example.mat';
assert( ~isempty(thisp), 'Could not locate a get_example_container.m file' );
assert( ~isempty(contp), 'Could not locate a Container.m file' );
outerfolder = fileparts( thisp );
filepath = fullfile( outerfolder, filename );
assert( exist(filepath, 'file') == 2, 'Could not locate an example.mat file.' );
try
  cont = load( filepath );
  cont = cont.(char(fieldnames(cont)));
catch err
  error( 'Could not load an example object; received this error:\n%s\n' ...
    , err.message );
end

end