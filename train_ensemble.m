function [Mdl, threshold] = train_ensemble(X,y)
%TRAIN_ENSEMBLE Trénuje ensemble klasifikátor s automatickou optimalizací hyperparametrů
% a určí optimální rozhodovací práh na základě ROC křivky.
%
%   [Mdl, threshold] = TRAIN_ENSEMBLE(X, y)
%
%   Vstupní parametry:
%       X - matice (NxM) vstupních dat, kde N je počet vzorků a M počet
%           příznaků (features).
%       y - vektor (Nx1) cílových tříd (binární klasifikace, hodnoty 0 nebo 1).
%
%   Výstupní parametry:
%       Mdl       - natrénovaný model ensemble klasifikátoru (objekt fitcensemble).
%       threshold - optimální rozhodovací práh pro klasifikaci na základě ROC
%                   analýzy (bod s nejmenší vzdáleností od ideálního bodu ROC).
%
%   Popis:
%       Funkce natrénuje ensemble klasifikátor (výchozí metoda fitcensemble)
%       nad vstupními daty X a labely y s automatickou optimalizací hyperparametrů.
%       Následně provede predikci na trénovacích datech a spočítá skóre (pravděpodobnosti).
%       Na základě těchto skóre vypočítá ROC křivku, vyhledá bod na křivce s
%       minimální vzdáleností od ideálního bodu (0,1) a použije odpovídající práh
%       jako optimální threshold pro binární rozhodnutí.
%
%   Poznámky:
%       - Pokud součet pravděpodobností není přibližně 1, nastaví se transformace
%         skóre na logit a predikce se provede znovu.
%       - Komentované části kódu ukazují možné alternativní přístupy, včetně
%         nastavení nákladové matice nebo použití jiných modelů.
%
%   Příklad použití:
%       load fisheriris
%       X = meas(51:end,3:4);
%       y = strcmp('virginica', species(51:end));
%       [Mdl, threshold] = train_ensemble(X, y);
%


% costMatrix = [0 1;   % Cost of predicting 1 when true class is 0 (FP)
%               3 0];  % Cost of predicting 0 when true class is 1 (FN)
% Mdl = fitcensemble(X, y, ...
%     'ClassNames', [0 1], ...
%     'Cost', costMatrix, ...
%     'OptimizeHyperparameters', 'auto');
%Mdl.ScoreTransform = 'none';

%Mdl = fitctree(X,y,'OptimizeHyperparameters','auto');
%Mdl = fitcsvm(X, y,'OptimizeHyperparameters','auto');
%   BoxConstraint    KernelScale
%     _____________    ___________
% 
%         506.2          128.28   
% Mdl = fitPosterior(Mdl);  % Optional: to get probabilities

    Mdl = fitcensemble(X,y,'OptimizeHyperparameters','auto');
    
    [ypred,scores] = predict(Mdl,X);
    
    if ~all(abs(sum(scores,2)-1)<0.001)
        Mdl.ScoreTransform='logit';
        [ypred,scores] = predict(Mdl,X);
    end
    
    % Compute ROC
    [fp, tp, thresholds] = perfcurve(y, scores(:,2), 1);
    
    % Calculate distance to point (0,1) – ideal point in ROC space
    distances = sqrt(fp.^2 + (1 - tp).^2);
    [~, minIdx] = min(distances);
    
    % Get optimal threshold
    threshold = thresholds(minIdx);

end