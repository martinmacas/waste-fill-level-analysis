function [X,xnames]=extract_features_collection_papir(p,Time,schedule,indc)
% EXTRACT_FEATURES_COLLECTION Extrahuje příznaky pro detekci svozu nádoby
% na papír nebo rychle se plnících nádob.
%
%   [X, xnames] = EXTRACT_FEATURES_COLLECTION_PAPIR(p, Time, schedule, indc)
%   provede extrakci příznaků na základě signálu zaplnění, časových údajů
%   a indexů indc míst, v kterých chceme extrahovat příznaky. Pro detekci svozů 
%   bude indc patrně obsahovat všechny indexy svozů (pozitivní příklady) a 
%   indexy míst, která chci odlišit od svozů (negativní příklady, třeba
%   všechna místa, kde dochází k poklesu a nejsou to svozy.
%
%   Vstupní parametry:
%       Time            - časová informace signálu (datetime, vektor Nx1)
%       p               - vzorky stavu zaplnění odpadové nádoby v procentech (double, vektor Nx1)
%       schedule        - rozvrh svozů
%       indc            - indexy událostí,pro které chci extrahovat
%                         příznaky (např. svozy a nesvozy) (double, vektor 1xn)
%
%   Výstupní parametry:
%       X               - matice s hodnotami příznaků v každém řádku (n × m double)
%       xnames          - názvy příznaků (1 × m cell array of char/string)
%
%

X = [diff(p(repmat(indc,1,3)+(-1:1)),[],2)./hours(diff(Time(repmat(indc,1,3)+(-1:1)),[],2)), ...%derivace
     diff(p(repmat(indc,1,3)+(-1:1)),[],2), ...%abs diference
     p(repmat(indc,1,2)+(0:1)) ...%aktualni a dalsi hodnota p
     abs(hour(Time(indc))+minute(Time(indc))/60-12) ...%vzdalenost od poledne
     diff(p(repmat(indc,1,2)+(0:1)),[],2)./p(indc) ...%relativni diference
     min(abs(weekratio(Time(indc))-schedule),[],2) ...%vzdalenost od planovaneho svozu
     hours(diff(Time(repmat(indc,1,2)+(0:1)),[],2))...
];
xnames = {'deriv-1','deriv0','diff-1','diff0','p0','p+1','noon_dist','diff0/p0','plan_dist','diffTime'};

end


% %all features
% X = [diff(p(repmat(indc,1,5)+(-2:2)),[],2)./hours(diff(Time(repmat(indc,1,5)+(-2:2)),[],2)), ...%derivace
%      diff(p(repmat(indc,1,5)+(-2:2)),[],2), ...%abs diference
%      p(repmat(indc,1,2)+(0:1)) ...%aktualni a dalsi hodnota p
%      abs(hour(Time(indc))+minute(Time(indc))/60-12) ...%vzdalenost od poledne
%      diff(p(repmat(indc,1,5)+(-2:2)),[],2)./p(repmat(indc,1,4)+(-2:1)) ...%relativni diference
%      min(abs(weekratio(Time(indc))-schedule),[],2) ...%vzdalenost od planovaneho svozu
%      hour(Time(indc)) ...%Hodina
%       ];
% xnames = {'deriv-2','deriv-1','deriv0','deriv+1','diff-2','diff-1','diff0','diff+1','p0','p+1','noon_dist','diff-2/p-2','diff-1/p-1','diff0/p0','diff+1/p+1','plan_dist','Hour'};
% % %Selected ones:
% % X=X(:,[14    13    16     1     9     5     3     7     8    12]);
% % xnames = xnames([14    13    16     1     9     5     3     7     8    12]);


%dalsit typy priznaku a poznamky:
%%Derivations t-4 to t+4
%        X = [diff(p(repmat(indc,1,9)+(-4:4)),[],2)./hours(diff(Time(repmat(indc,1,9)+(-4:4)),[],2)) ...
%            p(repmat(indc,1,3)+(-1:1)) ...
%            abs(hour(Time(indc))+minute(Time(indc))/60-12) ...
%            ];
%      
%
% X = [diff(p(repmat(indc,1,7)+(-3:3)),[],2)./hours(diff(Time(repmat(indc,1,7)+(-3:3)),[],2)) ...
%            p(repmat(indc,1,3)+(-1:1)) ...
%            abs(hour(Time(indc))+minute(Time(indc))/60-12) ...
%            ];

%reutls IF3-IF6
% X = [diff(p(repmat(indc,1,9)+(-4:4)),[],2) ...
%            p(repmat(indc,1,3)+(-1:1)) ...
%            abs(hour(Time(indc))+minute(Time(indc))/60-12) ...
%            ];

% X = [diff(p(repmat(indc,1,5)+(-2:2)),[],2) ...%difference -2:+2
%            p(repmat(indc,1,2)+(0:1)) ...%aktualni a dalsi hodnota p
%            abs(hour(Time(indc))+minute(Time(indc))/60-12) ...%vzdalenost od poledne
%            diff(p(repmat(indc,1,2)+(0:1)),[],2)./p(indc) ...%relativni diference
%            ];

% X = [median(diff(p(repmat(indc,1,5)+(-4:0)),[],2),2) ...%median difference -4:0
%      diff(p(repmat(indc,1,4)+(-2:1)),[],2), ...
%      p(repmat(indc,1,2)+(0:1)) ...%aktualni a dalsi hodnota p
%      abs(hour(Time(indc))+minute(Time(indc))/60-12) ...%vzdalenost od poledne
%      diff(p(repmat(indc,1,2)+(0:1)),[],2)./p(indc) ...%relativni diference
%            ];
% xnames = {'diff_median','diff-2','diff-1','diff-0','p(t)','p(t+1)','noon_dist','diff(p)/p'};

% X = [median(diff(p(repmat(indc,1,5)+(-4:0)),[],2),2) ...%median difference -4:0
%     median(diff(p(repmat(indc,1,5)+(0:4)),[],2),2) ...%median difference 0:4
%      diff(p(repmat(indc,1,2)+(0:1)),[],2), ...%abs diference
%      p(repmat(indc,1,2)+(0:1)) ...%aktualni a dalsi hodnota p
%      abs(hour(Time(indc))+minute(Time(indc))/60-12) ...%vzdalenost od poledne
%      diff(p(repmat(indc,1,2)+(0:1)),[],2)./p(indc) ...%relativni diference
%            ];
%xnames = {'diff_median-4','diff_median+4','diff-0','p(t)','p(t+1)','noon_dist','diff(p)/p'};

%Zjistil jsem, ze mediany jsou asi k nicemu, zkusim pridat opravdu derivace

% text(Time(indc),p(indc),string(1:length(indc)))
% Xts = X;
% load data_collection;
% figure;gplotmatrix([X;Xts(109,:)],[],[ones(size(X,1),1);2],'br','.O',[],'on',[],xnames)
% X=Xts;
% 
% text(Time(indc),p(indc),string(1:length(indc)))
% Xts = X;
% load data_collection_supervised;
% figure;gplotmatrix([X;Xts(37,:)],[],[y;2],'bgr','..O',[],'on',[],xnames)
% X=Xts;