function [output, valData, valIndex] = SelectSet(data, percent, varargin)

% This function randomly removes data for example validation.
% Usage: [output, valData, valIndex] = SelectSet(data, percent, method, [cloud])
%
% data must be 2-D or 3-D matrix with possible missing values marked as
% NaN. When clouds are used, the data must be in 3-D.
%
% percent defines the percent of non-missing data to remove from the data.
% Must be a real number between 0 and 100.
%
% method can be either 'random' or 'cloud'. Random removes single data
% points randomly from data and cloud uses the [cloud] mask matrix
% provided. When 'cloud' method is used, data must be in 3-D.
%
% cloud mask matrix can be either 2-D or 3-D binary matrix. 2-D represents
% one cloud and 3-D many clouds.

if nargin > 2
  switch lower(varargin{1})
    case 'random'
      method = 'random';
    case 'cloud'
      if nargin > 3
        method = 'cloud';
        cloudMask = varargin{2};
      else
        disp('No cloud mask defined, using random set selection!');
        method = 'random';
      end

    otherwise
      disp('Incorrect method defined, using random set selection!');
      method = 'random';
  end

else
  method = 'random';
end

% Calculated
nData = numel(data);
nValData = floor((nData - sum(sum(sum(isnan(data))))) ...
  * percent / 100);

valIndex = zeros(1,nValData);
valData = ones(1,nValData) * inf;

switch lower(method)
  case 'random'
    i = 1;

    while i <= nValData
      valIndex(i) = floor(rand * (nData - 1) + 1);

      if ~isnan(data(valIndex(i)))
        valData(i) = data(valIndex(i));
        data(valIndex(i)) = NaN;
        i = i + 1;
      end
    end

    output = data;

  case 'cloud'
    switch ndims(cloudMask)
      case 2
        nClouds = 1;
      case 3
        nClouds = size(cloudMask,3);
      otherwise
        disp('Cloudmask defined wrong!');
        disp('Use either 2 or 3 dimensional binary matrix!');
        return;
    end % Cloudmask dimension switch

    cloudCounter = 0;
    places = [];
    
    output = data;
    [rows,columns,time] = size(output);
    mask = isnan(output);
    origDataMissing = sum(sum(sum(isnan(output))));

    % Main loop
    while sum(sum(sum(isnan(output)))) - origDataMissing < nValData
      placeBad = 1;

      while placeBad
        % Getting the cloud
        cloud = cloudMask(:,:,mod(cloudCounter,nClouds)+1);
        
        % Cropping the cloud
        while sum(cloud(1,:)) == 0
          cloud(1,:) = [];
        end
        
        while sum(cloud(end,:)) == 0
          cloud(end,:) = [];
        end
        
        while sum(cloud(:,1)) == 0
          cloud(:,1) = [];
        end
        
        while sum(cloud(:,end)) == 0
          cloud(:,end) = [];
        end
                       
        % Getting anchor point and dimension boundaries
        anchor = floor(size(cloud)/2);
        spaceUpLeft = anchor - 1;
        spaceLowRight = size(cloud) - anchor;

        % Placing a cloud randomly to the data set
        location = floor(rand(size(size(output))) .* ...
          (size(output) - 1)) + 1;

        % Checking the validity of the placing
        try
          validity = ...
            sum(sum(mask(location(1)-spaceUpLeft(1):location(1)+spaceLowRight(1),...
            location(2)-spaceUpLeft(2):location(2)+spaceLowRight(2),location(3)) ...
            .* cloud));
        catch
          if location(1)-spaceUpLeft(1) <= 0
            cloud = cloud(spaceUpLeft(1)-(location(1)-1)+1:end,:);
            spaceUpLeft(1) = location(1) - 1;

          elseif location(1)+spaceLowRight(1) > rows
            cloud = cloud(1:end-spaceLowRight(1)+(rows-location(1)),:);
            spaceLowRight(1) = rows - location(1);
          end

          if location(2)-spaceUpLeft(2) <= 0
            cloud = cloud(:,spaceUpLeft(2)-(location(2)-1)+1:end);
            spaceUpLeft(2) = location(2) - 1;

          elseif location(2)+spaceLowRight(2) > columns
            cloud = cloud(:,1:end-spaceLowRight(2)+(columns-location(2)));
            spaceLowRight(2) = columns - location(2);
          end

          try
            validity = ...
              sum(sum(mask(location(1)-spaceUpLeft(1):location(1)+spaceLowRight(1),...
              location(2)-spaceUpLeft(2):location(2)+spaceLowRight(2),location(3)) ...
              .* cloud));
          catch
            disp('Kosahti!');
            disp(lasterr);
            return;
          end
        end

        if validity == 0
          placeBad = 0;
        end
      end

      % Saving all necessary information for validation error calculation
      places = [places; location];

      % Applying the cloud
      cloud(find(cloud == 1)) = NaN;
      cloud(find(cloud == 0)) = 1;

      output(location(1)-spaceUpLeft(1):location(1)+spaceLowRight(1),...
        location(2)-spaceUpLeft(2):location(2)+spaceLowRight(2),location(3)) = ...
        output(location(1)-spaceUpLeft(1):location(1)+spaceLowRight(1),...
        location(2)-spaceUpLeft(2):location(2)+spaceLowRight(2),location(3)) ...
        .* cloud;

      cloudCounter = cloudCounter + 1;
    end % Main loop

    maskValData = isnan(output) - mask;
    valIndex = find(maskValData == 1);
    valData = data(valIndex);
end % Method switch

