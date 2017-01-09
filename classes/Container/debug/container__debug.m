data = cell(4, 1);
cont = Container( data, lab );

%%

cont = Container.create_from( look );

%%


%%

c = Container();
c = c.preallocate( nan(1000, 2), cont.nfields() );

c = c.populate( cont(1:50) );
c = c.cleanup();

%%

b = Container();
tic;
for i = 1:1e3
  b = append( b, cont(1:50) );
end
toc;
%%

c = Container();
c = c.preallocate( nan(10000, 2), cont.nfields() );
tic;
for i = 1:1e3
  c = populate( c, cont(1:50) );
end
c = c.cleanup();
toc;
%%
tic
p = pup(1:1e3);
p = p.compress();
toc;
%%
c = cont.set_field( 'file_names', '100' );
tic;
c = c(1:1e3);
c = c.compress();
toc;
%%
tic;
d = c.decompress();
toc;
%%
tic;
p = p.unpack();
toc;