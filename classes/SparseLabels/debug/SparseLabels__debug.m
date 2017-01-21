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
tester = fix_;
tic;
tester.get_indices({'monkeys','rois','imgGaze'})
toc;

%%
tester2 = fix_sparse;
tic;
% lag = tester.only('lager');
% cron = tester.only('cron');
% comb = lag.append( cron );
% profile on;
newer2 = append(tester2, tester2);
newer2 = append(newer2, tester2);
% newer = append(newer, tester);
% newer = append(newer, tester);
% newer = append(newer, tester);
% profile viewer;
% tester = tester.append(tester);
% tester = tester.append(tester);

toc;

%%

tester = fix_sparse;
tic;
tester.only({'cron','1','ubdl','ubdn'});
toc;
%%