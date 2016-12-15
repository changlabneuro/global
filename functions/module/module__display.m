function module__display( obj )

props = properties( obj );

if ( ~isempty(props) )
    print__items( obj, props, 'submodules' ); return;
end

funcs = methods( obj );

funcs = funcs( ~strcmp(funcs, class(obj)) );    %   remove constructor
funcs = funcs( ~strcmp(funcs, 'disp') );        %   remove display

if ( ~isempty(funcs) )
    print__items( obj, funcs, 'methods' ); return;
end

fprintf( '\n MODULE ''%s'' with no defined methods or submodules\n\n', class(obj) );

end

function print__items( obj, items, type )

fprintf( '\n MODULE ''%s'' with %s:\n', class(obj), type );

for i = 1:numel(items)
    fprintf( '\n - ''%s''', items{i} );
end

fprintf('\n\n');

end