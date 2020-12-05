%% DINEOF data reconstruction
% test example 'TestDataset.mat'
% input: Dataset=[latitude * longitude, data length]); Here=(97 * 121, 131);

%% Predefined parameters
Lat_M = 97;
Lat_N = 121;
datalength = 131;
pixels = 11737;
Lat = reshape(Dataset(1:pixels,1), Lat_M, Lat_N);
Lon = reshape(Dataset(1:pixels,2), Lat_M, Lat_N);
Data = reshape(Dataset(:,3:datalength+2), Lat_M, Lat_N, datalength);
nMonteCarlo = 10;
percentMonteCarlo = 10;
initialization = 'column';
stopping = 0.1; % minimum threshold for early stop
rounds = 1000; % maximun number of iterations

%% Count valid data and coverage
count = 0;
for ii = 1:Lat_M
    for jj = 1:Lat_N
        Data_tmp = squeeze(Data(ii,jj,:));
        [c, ~] = find(~isnan(Data_tmp)==1);
        Coverage(ii,jj) = length(c)/length(Data_tmp);
        if Coverage(ii,jj) == 0
            Coverage(ii,jj) = NaN;
            Lat(ii,jj) = NaN;
            Lon(ii,jj) = NaN;
        else
            count = count+1;
            Data_Used(count,1:length(Data_tmp)) = Data_tmp;
            Lat_Used(count) = Lat(ii,jj);
            Lon_Used(count) = Lon(ii,jj);
        end
    end
end

%% EOF analysis, find the aimed EOFs
data = Data_Used;
[rows, columns] = size(data);
data(isnan(data)) = 0;
[PC, EigenVector, EigenValue, Cum, Mean_Eof] = Func_EOFszb(data);
[c,d] = find(Cum > 0.85); 
maxeof = d(1);

data = Data_Used;
[data2, testData, testIndex] = SelectSet(data, percentMonteCarlo); % randomly select data
[dataNorm, normMeans, normStds] = Normalize(data2, 'meanrows', 'stdrows'); % normalization

% Results
valErrors = ones(nMonteCarlo, maxeof) * inf;


%% Learning section
for mc = 1:nMonteCarlo
  % Validationset selection
  [dataMC, valData, valIndex] = SelectSet(dataNorm, percentMonteCarlo);
  
  % Initialization
  [dataInit, mask] = InitMissing(dataMC, initialization);
  
  % EOF estimations for the validation set values
  outputs = EOFMulti(dataInit, mask, maxeof, 'original', valIndex, ...
    stopping, rounds);
  
  % Validation error calculation for each eof
  valErrors(mc, :) = mean((outputs - repmat(valData, maxeof, 1)) .^2, 2);
end

[aa, bb] = min(mean(valErrors, 1));
[dataInit, maskTest] = InitMissing(dataNorm, initialization);

% Filling
dataFilled = EOFCore(dataInit, maskTest, bb, stopping, rounds);

% Denormalization, using the reversed order than in Normalization
dataFilled = DeNormalize(dataFilled, 'std', normStds, 'mean', normMeans);

% Test error calculation
testError = mean((dataFilled(testIndex) - testData) .^2);


%% Final filling of the data set
% In case there's missing values
if any(isnan(data))
  % Dataset normalization. Remember to DeNormalize!
  % Normalization does not do anything to the missing values
  [dataNorm, normMeans, normStds] = Normalize(data, 'meanrows', 'stdrows');
  
  % Initialization
  [dataInitFinal, maskFinal] = InitMissing(dataNorm, initialization);
  
  % Filling
  dataFilled = EOFCore(dataInitFinal, maskFinal, bb, stopping, rounds);
  
  % DeNormalizing the filled dataset
  dataFilled = DeNormalize(dataFilled, 'std', normStds, 'mean', normMeans);
  
  dataFilledFinal = data;
  dataFilledFinal(isnan(data)) = dataFilled(isnan(data));
end

%% Plot figure, install m_map for geo-plotting
for ss = 1:25:datalength
    figure;
    set(gcf, 'outerposition', get(0,'screensize'));
    % before DINEOF
    subplot(1,2,1)
    m_proj('miller', 'lat',[28 33], 'lon',[121 125]);
    m_pcolor(Lon, Lat, Data(:,:,ss));
    shading flat;
    m_gshhs_h('patch',[.83 0.83 .18]);
    m_grid('linest','none','linewidth',2,'tickdir','in');
    colorbar('v');
    % after DINEOF
    for ii = 1:Lat_M
        for jj = 1:Lat_N
            [c,d] = find(abs(Lon(ii,jj)-Lon_Used)<0.000001 & ...
                abs(Lat(ii,jj)-Lat_Used)<0.00001);
            if isempty(c)
                Data2(ii,jj) = NaN;
            else
                Data2(ii,jj) = dataFilled(d, ss);
            end
        end
    end
    subplot(1,2,2)
    m_proj('miller', 'lat',[28 33], 'lon',[121 125]);
    m_pcolor(Lon, Lat, Data2);
    shading flat;
    m_gshhs_h('patch',[.83 0.83 .18]);
    m_grid('linest','none','linewidth',2,'tickdir','in');
    colorbar('v');
end
