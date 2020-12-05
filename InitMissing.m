function [output, mask] = InitMissing(data, method, varargin)

% Initialization function (V.1.2)
% Extracting the mask and filling the data.
%
% Usage: [filled, mask] = InitMissing(data, method, [value]);
%
% data must be in the correct EOF format with only 2 dimensions, one
% spatial and one temporal.
%
% Valid methods include 'total', 'row', 'column', 'interpolation' and
% 'value'. First three are initializations by respective mean values of
% the data matrix.
% The fourth one is based on linear interpolation through temporal
% dimension (first dimension, through rows). The last method replaces all
% missing values by given [value] parameter.
%
% filled is the filled data matrix.
%
% mask is a matrix with ones in the case of filled value and zeros
% otherwise.

dim = ndims(data);

if dim > 2
  disp(['Incomprehensible amount of dimensions, ' num2str(dim)]);
  output = inf;
  return;
end

[rows, columns] = size(data);
mask = isnan(data);

output = data;

switch lower(method)
  case 'total'
    means = mean(output(~isnan(output)));
    output(isnan(output)) = means;
    
  case 'row'
    means = ones(rows,1) * inf;
    
    for i = 1:rows
      means(i) = mean(output(i, ~isnan(output(i,:))));
      
      if isnan(means(i))
        means(i) = Inf;
      else
        output(i, isnan(output(i,:))) = means(i);
      end
      
      output(means(i) == Inf,:) = mean(means(means ~= Inf));
    end
    
  case 'column'
    means = ones(1,columns) * inf;
    
    for i = 1:columns
      means(i) = mean(output(~isnan(output(:,i)), i));
      
      if isnan(means(i))
        means(i) = Inf;
      else
        output(isnan(output(:,i)), i) = means(i);
      end
      
      output(:,means(i) == Inf) = mean(means(means ~= Inf));
    end
    
  case 'interpolation'
    [xx, yy] = find(isnan(output), 1);
    
    while ~isempty(xx)
      eka = xx - 1;
      
      while isnan(output(xx,yy))
        if xx == rows
          break;
        else
          xx = xx + 1;
        end
      end
      
      toka = xx;
      
      if eka == 0
        dist = toka - 1;
        
        for i = 1:dist
          output(toka-i, yy) = output(toka, yy);
        end
        
      elseif toka == rows
        dist = rows - eka;
        
        for i = 1:dist
          output(eka+i, yy) = output(eka, yy);
        end
        
      else
        dist = toka - eka - 1;
        value = (output(toka, yy) - output(eka, yy)) / (dist+1);
        
        for i = 1:dist
          output(eka+i, yy) = output(eka, yy) + i * value;
        end
        
      end
      
      [xx, yy] = find(isnan(output), 1);
    end
    
    means = 0;
    
  case 'value'
    if nargin < 3
      disp('Value parameter is missing!');
      output = inf;
      return;
    else
      value = varargin{1};
    end
    
    output(isnan(output)) = value;
    
  otherwise
    disp('Method unknown!');
    mask = inf;
    return;
end

