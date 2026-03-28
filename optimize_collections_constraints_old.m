function [popt, pcurr, topt, tcurr, costopt, costcurr, alessopt,alesscurr, amoreopt, amorecurr,TT,xopt,xcurr,copt,ccurr]= optimize_collections_constraints(Time, p,schedule,cdetected,level_after)

%Detect waste collections and after pick level 
%[c,cpresc, numcollections, schedule, afterpicklevel] = detect_collections(Time,p);
%[c, scores, threshold, level_after,level_before] = detect_collections_supervised(Time,p,[],schedule);
%afterpicklevel=mean(level_after);      
numcollections = length(schedule);
timec=Time(cdetected);
%Resample to hourly data using linear interp to make disposal smoother
%TT=retime(timetable(Time, p),'hourly','linear');
TT=timetable(Time, p);

%Estimate waste disposal signal from hourly data
tic
TT = estimate_disposal(TT);
dp=TT.dp;
toc

%Resample to hourly data using nearest interp to prevent stepwise decline
%during collection period
%TT=retime(timetable(Time, p),'hourly','nearest');
TT.dp=dp;
%Evaluating current state
params.timec = timec;
params.level_after = level_after;
xcurr = schedule;
params.alesscurr = 0;
params.amorecurr = 0;
[~, ~, ~, ~, ~,alesscurr, amorecurr] = costFcn(xcurr,TT,params);
params.alesscurr = alesscurr;
params.amorecurr = amorecurr;

%Optimize
%f = @(x)costFcn(x,TT,params)   ;
f = @(x)costFcn_constraints(x,TT,params)   ;
dim=numcollections;
% 
% options=optimoptions("particleswarm");
% options.SwarmSize=50;
% xinit=constraint_encoding(xcurr,3,20);
% options.InitialSwarmMatrix=[xinit;rand(options.SwarmSize-1,dim)];
% options.PlotFcn='pswplotbestf';
% tic
% [xopt,fval] = particleswarm(f,dim,0.01*ones(1,dim),0.99*ones(1,dim),options);
% toc

options=optimoptions("patternsearch");
options.PlotFcn = 'psplotbestf';
%options.PlotFcn = [];
xinit=constraint_encoding(xcurr,3,20);
% xinit=rand(1,dim);
 [xopt,fval] = patternsearch(f,xinit,[],[],[],[],0.01*ones(1,dim),0.99*ones(1,dim),options);



dim=dim-1;
if dim>0
    %xinit=rand(1,dim);
    xinit(randi(dim))=[];
    [xopt_m1,fval_m1] = patternsearch(f,xinit,[],[],[],[],0.01*ones(1,dim),0.99*ones(1,dim),options);
else
    fval_m1 = Inf;xopt_m1=NaN;
end
dim=dim+2;
%xinit=rand(1,dim);
xinit=[constraint_encoding(xcurr,3,20) rand];
[xopt_p1,fval_p1] = patternsearch(f,xinit,[],[],[],[],0.01*ones(1,dim),0.99*ones(1,dim),options);

Xopt={xopt,xopt_m1,xopt_p1};
[a,b]=min([fval fval_m1 fval_p1]);
xopt=Xopt{b};

xopt = constraint_decoding(xopt,3,20);

xopt=sort(xopt);


%Evaluate current and optimized schedule
[costopt, popt, copt, ratiofullopt, pcollopt, alessopt,amoreopt] = costFcn(xopt,TT,params);
[costcurr, pcurr, ccurr, ratiofullcurr, pcollcurr,alesscurr, amorecurr] = costFcn(xcurr,TT,params);
%simulated level p can reach more than 100 to enable cost computation,
%thus we must saturate it
%pcurr(pcurr>100)=100;popt(popt>100)=100;
%xcurr=sort(xcurr);
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
