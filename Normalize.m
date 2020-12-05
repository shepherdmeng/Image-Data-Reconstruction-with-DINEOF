function [output, varargout] = Normalize(data, varargin)

% Normalization function (V.2.2):
% Usage: [output, ['means'], ['stds']] = Normalize(data, ['params']);
%
% Normalization function can handle data matrixes with missing values.
%
% Params include:
%    'mean'     To remove global mean
%    'std'      To remove global standard deviation
%    'meancols' To remove column means
%    'meanrows' To remove row means
%    'stdcols'  To remove column standard deviation
%    'stdrows'  To remove row standard deviation
%
% Paramters can be given in any order. If no parameters are given the total
% mean and standard deviation are removed, same as 'mean' and 'std'. Output
% parameters are given in the above order, depending on the normalizations
% given.
%
% Returns the normalized data and the removed means and standard
% deviations.
%
% If there is a full row or column of missing values, the Normalization
% function returns the mean or std of other rows or columns when necessary. This
% is to avoid problems in denormalization later.

output = data;
[rows, columns] = size(output);

if nargin == 1
  totalmean = mean(output(~isnan(output)));
  output = output - totalmean;
  
  totalstd = std(output(~isnan(output)));
  output = output ./ totalstd;
  
  varargout{1} = totalmean;
  varargout{2} = totalstd;
else
  for i = 1:nargin-1
    switch lower(varargin{i})
      case 'mean'
        totalmean = mean(output(~isnan(output)));
        output = output - totalmean;
        
        varargout{i} = totalmean;
      case 'std'
        totalstd = std(output(~isnan(output)));
        output = output ./ totalstd;
        
        varargout{i} = totalstd;
      case 'meanrows'
        means = ones(rows,1) * inf;
        
        for j = 1:rows
          means(j) = mean(output(j,~isnan(output(j,:))));
        end
        
        output = output - (means * ones(1,columns));
        means(isnan(means)) = mean(means(~isnan(means)));
        varargout{i} = means;
      case 'meancols'
        means = ones(1,columns) * inf;
        
        for j = 1:columns
          means(j) = mean(output(~isnan(output(:,j)),j));
        end
        
        output = output - (ones(rows,1) * means);
        means(isnan(means)) = mean(means(~isnan(means)));
        varargout{i} = means;
      case 'stdrows'
        stds = ones(rows,1) * inf;
        
        for j = 1:rows
          stds(j) = std(output(j,~isnan(output(j,:))));
        end
        
        output = output ./ (stds * ones(1,columns));
        stds(isnan(stds)) = mean(stds(~isnan(stds)));
        varargout{i} = stds;
      case 'stdcols'
        stds = ones(1,columns) * inf;
        
        for j = 1:columns
          stds(j) = std(output(~isnan(output(:,j)),j));
        end
        
        output = output ./ (ones(rows,1) * stds);
        stds(isnan(stds)) = mean(stds(~isnan(stds)));
        varargout{i} = stds;
      otherwise
        disp(['Unrecognized switch ' varargin{i} ' --> ignored!']);
    end
  end
end

