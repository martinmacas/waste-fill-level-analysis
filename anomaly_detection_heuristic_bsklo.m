function  [ypred, score, forecast] = anomaly_detection_heuristic_bsklo(Time, p)
%ANOMALY_DETECTION_HEURISTIC  Detekce událostí v časové řadě stavu zaplnění nádob na sklo či pomalu se plnících nádob.
%
%   [ypred, score, forecast] = ANOMALY_DETECTION_HEURISTIC_BSKLO(Time, p)
%   provede heuristickou detekci anomálií na základě heuristických pravidel aplikovaných na signál zaplnění
%   odpadové nádoby. Funkce aplikuje heuristický algoritmus pro detekci
%   událostí v časové řadě zaplnění. 
%
%   Vstupní parametry:
%       Time        - datetime, časová informace signálu (vektor Nx1)
%       p           - double, vzorky stavu zaplnění odpadové nádoby
%                     v procentech (vektor Nx1)
%
%   Výstupní parametry:
%       ypred       - labely (označení) detekovaných anomálií (vektor Nx1)
%       score       - tento výstup u heuristická detekce není využit a je
%                     NaN, (skóre anomálnosti zde zatím nedává smysl)
%       forecast    - tento výstup u heuristická detekce není využit a je
%                     NaN (detekce nevyužívá žádnou odchylku od předpovědi či jiné reference)
%   
%   Význam labelů: 
%                   1 Odvoz nádoby - čištění
%                   2 Ucpaný vhoz
%                   4 Výpadek signálu
%                   6 Peak nahoru
%                   7 Sesuv
%                   9 Propad

len = length(Time); %Length of the signal

[Time,btime]=sort(Time);p=p(btime); %Sort time

L=zeros(len,1);% predicted labels

for i = 51 : len-50 %Last 50 samples can be postprocessed within Golemio with a delay
    
    %Class 1 Odvoz nadoby - cisteni
    c1 = p==100;
    c2 = p==0;
    if all([c1 c2])
        L(i:i+3)=1;
    end

    
    %Class 4 - Vypadek signalu
    c1 = (Time(i+1)-Time(i))>hours(24);
    if c1
        L(i) = 4;
    end
    
    %Class 2 - Ucpany vhoz
%     c1 = all(diff(p(i:i+3))==0);%zero difference for three consecutive steps
%     c2 = any(abs(hour(Time(i:i+3))-12)<5);%daytime
%     c3 = p(i)<96;%not full
%     c4 = hours((Time(i+3)-Time(i)))>2;%the three steps cover more than 2 hours
%     if all([c1 c2 c3 c4])
%         L(i:i+3)=2;
%     end

    %Class 6 - Peak nahoru
    d2 = (p(i+1)-p(i))/hours((Time(i+1)-Time(i)));%Derivation
    d1 = (p(i)-p(i-1))/hours((Time(i)-Time(i-1)));%Derivation
    c1 = d1>10;
    c2 =  d2<-9;
    if all([c1 c2])
        %lab=[lab 6];
        %plot(Time(i-10:i+10),p(i-10:i+10),'.-');pause;
        %L(i-1:i+1) = 6;
        L(i) = 6;
    end
 
 

    %Class 9 - Propad
    d2 = (p(i+1)-p(i))/hours((Time(i+1)-Time(i)));%Derivation
    d1 = (p(i)-p(i-1))/hours((Time(i)-Time(i-1)));%Derivation
    c1 = d1<-5;
    c2=  d1>-10;
    c3 = d2>1;
    if all([c1 c2 c3])
        %lab=[lab 9];
        %plot(Time(i-10:i+10),p(i-10:i+10),'.-');pause;
        L(i-1:i+1) = 9;
    end
 


    %Class 7 - Sesuv
    c1 = all(diff(p(i:i+3))<0);
    if all([c1])
        %lab=[lab 7];
    %    plot(Time(i:i+10),p(i:i+10),'.-');pause;
        L(i:i+3) = 7;
    end
  
end
Lorig = L;
%Merging neighboring labels
dL=diff([L;0]);q=and(dL==0, L~=0);
inds = find(diff([0;q])>0);
inde = find(diff([q;0])<0)+1;
for i=1:length(inds)
    lab = L(inds(i));
    L(inds(i):inde(i))=0;
    L(round((inds(i)+inde(i))/2))=lab;
end

%Resort the signal
L(btime)=L;
L(L==6)=0; L(Lorig==6) = 6;%Peaks should not be merged
%Output labels
ypred=L;

%Score and forecast does not make a sense in heuristic
score=nan(len, 1);
forecast=nan(len, 1);

end

