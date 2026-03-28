function [X,y,xnames] = prepare_data_bsklo(Time, p, labeltimes,schedule)
 [~,ind1]=ismember(labeltimes',Time);
    
    %detect collection using some method and add all false positives to
    %train set as negative examples (certain type of active learning)
    c = detect_collections_supervised_bsklo(Time,p, [],[]);
    ind0 = setdiff(find(c),ind1);

    %detect collection using other method and add all false positive to
    %train set if they are not there yet
    c=and([diff(p)<-15;false],[p(2:end)<15;false]);
    ind0 = [ind0;setdiff(setdiff(find(c),ind1),ind0)];

    %Add randomly remaining signal drops so as there will be the same
    %number of 0s and 1s
    c=diff(p)<0;
    ind_rest = setdiff(setdiff(find(c),ind1),ind0);
    ind_rest = ind_rest(randperm(length(ind_rest)));
    ind_rest = ind_rest((1:min(max(length(ind1)-length(ind0),0),length(ind_rest))));
    ind0 = [ind0;ind_rest];

    disp([length(ind0) length(ind1)]);
    
    ind1(ind1<=10)=[];ind1(ind1>length(Time)-10)=[];
    ind0(ind0<=10)=[];ind0(ind0>length(Time)-10)=[];

    ind = [ind0;ind1];
    [X,xnames] = feval('extract_features_collection_bsklo', p,Time,schedule,ind);
    y = [zeros(length(ind0),1);ones(length(ind1),1)];
   
%     close all;plot(Time,p); hold on; plot(Time(ind0),p(ind0),'gs','MarkerFaceColor','g','MarkerSize',6);plot(Time(ind1),p(ind1),'rs','MarkerFaceColor','r','MarkerSize',6);
%     legend('Signal','No collection','Collection');
%     pause;

end