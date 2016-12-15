%{
    pathedit.m -- function to edit the currently referenced paths.m file.
    Opens the <make_paths.m> file that corresponds to the currently active
    paths.mat file.
%}

function pathedit( flag )

if ( nargin < 1 ), flag = 'non global'; end;

if ( strcmp(flag, 'global') )
    pathstr = pathfor( 'global_paths' );
else pathstr = pathfor( 'paths' );
end

try
    cd( pathstr )
catch
    error( 'path ''%s'' is not a valid path', pathstr );
end

edit( 'make_paths.m' );


end