function [outputs, varargout] = EOFMulti(data, mask, neof, initeof, index, varargin)

% Function for selecting the number of EOFs to be used.
%
% Usage: outputs = EOFMulti(data, mask, neof, initeof, index, ...
%                           [stop_criterion], [max_iteration_rounds])
% 
% data must be in the correct EOF format with only 2 dimensions, one
% spatial and one temporal. 
% 
% mask is a binary matrix with the same size as data. It has one in the
% case of missing value (already replaced by Initialization) and zero in
% the case of known value from the dataset.
% 
% neof defines the maximum number of EOFs to be used. It can be also a vector
% defining minimum and maximum EOFs or [min step max] EOFs.
%
% initeof can be either 'previous' or 'original'. Previous uses the result
% of previous EOF calculation as initialization to the next one. Original
% uses the original data in every calculation. Previous is faster than
% original, but can be unconsistent when calculating single tests with only
% certain number of EOFs.
%
% index is the validation set index, which defines the positions of the
% data, where validation data has been removed. This is needed because not
% necessarily all missing data values are used in validation.
% 
% [stop_criterion] defines the minimum amount of change, after which 
% the iteration is terminated. Default is one.
% 
% [max_iteration_rounds] defines the maximum number of iteration rounds to
% perform. Default is infinity.
%
% outputs matrix includes the values of every calculation results from 1
% EOF to neof. The values are collected from validation value locations
% specified in index.

switch nargin
  case 5
    stop = 1;
    rounds = inf;
  case 6
    stop = varargin{1};
    rounds = inf;
  case 7
    if isempty(varargin{1})
      stop = 1;
    else
      stop = varargin{1};
    end

    rounds = varargin{2};
end

if sum(size(neof)) == 2
  neofmin = 1;
  neofmax = neof;
  neofstep = 1;
elseif max(size(neof)) == 2
  neofmin = neof(1);
  neofmax = neof(2);
  neofstep = 1;
elseif max(size(neof)) == 3
  neofmin = neof(1);
  neofstep = neof(2);
  neofmax = neof(3);
else
  disp('Number of EOFs can include at maximum 3 numbers!');
  disp('[[mineof], [stepeof], maxeof]');
  outputs = Inf;
  return;
end

if neofmax > min(size(data))
  neofmax = min(size(data));
end

outputs = ones(neofmax, length(index)) * inf;
roundCount = ones(1, neofmax) * inf;

switch lower(initeof)
  case 'previous'
    % Selecting the number of EOF
    for i = neofmin:neofstep:neofmax
%       disp(['Calculating EOF number ' num2str(i)]);
      [data, eigenvalues, elapsed] = EOFCore(data, mask, i, stop, rounds);
      outputs(i,:) = data(index);
      roundCount(i) = elapsed;
    end
  case 'original'
    % Selecting the number of EOF
    for i = neofmin:neofstep:neofmax
%       disp(['Calculating EOF number ' num2str(i)]);
      [data2, eigenvalues, elapsed] = ...
        EOFCore(data, mask, i, stop, rounds);
      outputs(i,:) = data2(index);
      roundCount(i) = elapsed;
    end
  otherwise
    disp('No such method of initializing EOF!');
    return;
end

switch nargout
  case 2
    varargout{1} = roundCount;
end

