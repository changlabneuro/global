%%

s.outcomes = { 'self'; 'self'; 'self'; 'both';'other' };
s.trials = { 'choice'; 'choice'; 'cued'; 'cued'; 'cued' };
s.rewards = { 'high'; 'low';'low';'low';'low' };
s.signs = { '+'; '-'; '-'; '+' ;'*' };

lab = Labels( s );

lab.labels
ind = lab.where( { 'both', 'self', 'other','choice', '-', '+', '*' 'cued' } )

%% prellocation

new = Labels();
new = preallocate(new, [1000 4] );
new2 = populate(new, lab);
new2 = new2.cleanup();

%% compare speed

look = processed.looking_duration;

labs = Labels( look.labels );
%%
for i = 1:1e2
  ind = where( labs, {'image__1', 'image__10', 'image__20', 'jodo', 'kuro'} );
end



%%

data = (1:4)';

obj = DataObject( data, s );