function T = update_label_table(Tcurr,Tnew)
    [~,b] = setdiff(Tcurr.index,Tnew.index);
    T=Tcurr(b,:);
    %T=[Tcurr;Tnew];
    [~,b] = setdiff(Tnew ...
        .index,Tcurr.index);
    T=[T;Tnew(b,:)];
    [~,bnew,bcurr] = intersect(Tnew.index,Tcurr.index);
    for i=1:length(bnew)
        if Tnew(bnew(i),'prediction').Variables~=Tcurr(bcurr(i),'prediction').Variables
            newexplanation=Tnew(bnew(i),'explanation').Variables;
            currexplanation=Tcurr(bcurr(i),'explanation').Variables;
            Tnew(bnew(i),'explanation').Variables = {sprintf('%s\nprediction %d changed to %d\n%s',currexplanation{1},Tcurr(bcurr(i),'prediction').Variables,Tnew(bnew(i),'prediction').Variables,newexplanation{1})};
        end
        if Tnew(bnew(i),'label').Variables~=Tcurr(bcurr(i),'label').Variables
            if isnan(Tnew(bnew(i),'label').Variables)
                Tnew(bnew(i),'label').Variables = Tcurr(bcurr(i),'label').Variables;
            end
        end
     end
    %Tnew(bnew,'prediction').Variables = Tcurr(bcurr,'prediction').Variables;
    T=[T;Tnew(bnew,:)];
end