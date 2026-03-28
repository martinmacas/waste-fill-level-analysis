function [popt, pcurr, topt, tcurr, costopt, costcurr, alessopt,alesscurr, amoreopt, amorecurr,TT,xopt,xcurr]= optimize_collections(Time, p)

%Detect waste collections and after pick level
[c,cpresc, numcollections, schedule, afterpicklevel] = detect_collections(Time,p);

%Resample to hourly data
TT=timetable(Time, p);
TT=retime(TT,'hourly','linear');

%Estimate waste disposal signal from hourly data
tic
TT = estimate_disposal(TT);
toc

%Evaluating current state
params.afterpicklevel = mean(afterpicklevel);
xcurr = schedule;
params.alesscurr = 0;
params.amorecurr = 0;
[~, ~, ~, ~, ~,alesscurr, amorecurr] = costFcn(xcurr,TT,params);
params.alesscurr = alesscurr;
params.amorecurr = amorecurr;

%Optimize
%f = @(x)costFcn(x,TT,params)   ;
f = @(x)costFcn_constraints(x,TT,params)   ;

% options=optimoptions("particleswarm");
% options.PlotFcn='';%'pswplotbestf';
% tic
% [xopt,fval] = particleswarm(f,dim,0.01*ones(1,dim),0.99*ones(1,dim),options);
% toc

options=optimoptions("patternsearch");
options.PlotFcn = 'psplotbestf';
%options.PlotFcn = [];


dim=numcollections;
xinit=xcurr;
%xinit=rand(1,dim);
[xopt,fval] = patternsearch(f,xinit,[],[],[],[],0.01*ones(1,dim),0.99*ones(1,dim),options);

dim=dim-1;xinit=rand(1,dim);
[xopt_m1,fval_m1] = patternsearch(f,xinit,[],[],[],[],0.01*ones(1,dim),0.99*ones(1,dim),options);

dim=dim+2;xinit=rand(1,dim);
[xopt_p1,fval_p1] = patternsearch(f,xinit,[],[],[],[],0.01*ones(1,dim),0.99*ones(1,dim),options);

%If the reduced schedule was better, take it
if fval_m1<=fval,xopt=xopt_m1;fval=fval_m1;end
%If the extended schedule was better, take it
if fval_p1<=fval,xopt=xopt_p1;fval=fval_p1;end


xopt=sort(xopt);


%Evaluate current and optimized schedule
[costopt, popt, collopt, ratiofullopt, pcollopt, alessopt,amoreopt] = costFcn(xopt,TT,params);
[costcurr, pcurr, collcurr, ratiofullcurr, pcollcurr,alesscurr, amorecurr] = costFcn(xcurr,TT,params);
%simulated level p can reach more than 100 to enable cost computation,
%thus we must saturate it
pcurr(pcurr>100)=100;popt(popt>100)=100;
xcurr=sort(xcurr);
% 
% 
% disp('-------------------------');
% disp('Current schedule:');
% tmonday=dateshift(datetime('today'),'dayofweek','Monday','previous');
tcurr= weekratio2weektime(xcurr)';
tcurr = (datestr(tcurr,'ddd HH:MM'));
% disp(['Cost value=' num2str(costcurr)]);
% disp('-----------------');
% disp('Optimal schedule:');
topt=weekratio2weektime(xopt)';
topt = datestr(topt,'ddd HH:MM');
% disp(['Cost value=' num2str(fval)]);
