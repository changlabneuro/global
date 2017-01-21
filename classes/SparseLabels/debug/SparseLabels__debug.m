tic;
% im_sm.get_indices({ 'monkeys', 'days'});
% im_sm.disp();
for i = 1:1e2
  b = im_cl.only( {'cron', 'ephron', 'high', 'low'} );
end
toc;
%%

im_cs = imc;
im_cl = imc.full();
%%
tic;
im_cs.append( im_cs );
toc;

%%
tic;

tester = im_cs;
for i = 1

% cron = tester.only('cron');
eph = tester.only({'tarantino', 'ephron'});

tester = tester.append(eph);
end

toc;

%%

tic;
im_cs.get_indices({'monkeys','rois','imgGaze'})
toc;