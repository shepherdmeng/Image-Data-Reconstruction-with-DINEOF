
function [PCA, EigenVector_Spatial, EigenValue, Cum,Mean_Eof] = Func_EOFszb(Eof_Data)

s = size(Eof_Data);
ss = min(s);
% Std_Eof = std(Eof_Data,1,2);
% Std_Eof = repmat(Std_Eof, [1,ss]);
Mean_Eof = mean(Eof_Data,2);
Mean_Eof = repmat(Mean_Eof, [1,ss]);
% Eof_Data = (Eof_Data - Mean_Eof)./Std_Eof;
Eof_Data = (Eof_Data - Mean_Eof);
%  Mean_Eof = Mean_Eof*0;
RSS_Eof = (Eof_Data'*Eof_Data);

[EigenVector, EigenValue] = eig(RSS_Eof);
EigenVector = fliplr(EigenVector);  
EigenValue = rot90(EigenValue, 2);     
EigenValue = diag(EigenValue);
EigenVector_Spatial1 = Eof_Data * EigenVector;
for ss = 1:length(EigenValue)
    EigenVector_Spatial(:,ss) = EigenVector_Spatial1(:,ss)/sqrt(EigenValue(ss));
end

PCA = EigenVector_Spatial' * Eof_Data; 
EigenValue = EigenValue * length(EigenValue);
for ii=1:length(EigenValue)
    Cum(ii) = sum(EigenValue(1:ii))/sum(EigenValue);
end