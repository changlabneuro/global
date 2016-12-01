%{
    pathedit.m -- function to edit the currently referenced paths.m file.
    Opens the <make_paths.m> file that corresponds to the currently active
    paths.mat file.
%}

function pathedit()

pathstr = pathfor( 'paths' );

try
    cd( pathstr )
catch
    error( 'path ''%s'' is not a valid path', pathstr );
end

edit( 'make_paths.m' );


end