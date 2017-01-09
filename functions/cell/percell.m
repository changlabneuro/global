%{
    percell.m -- shortcut function for calling cellfun when the output is
    known to be non-uniform (i.e., a cell array). Basically avoids having
    to type cellfun( ... 'UniformOutput', false ) everywhere.
%}

function out = percell( func, cellarray, varargin )

params = struct( ...
    'UniformOutput', false ...
);
params = struct2varargin( parsestruct( params, varargin ) );

out = cellfun( func, cellarray, params{:} );

end