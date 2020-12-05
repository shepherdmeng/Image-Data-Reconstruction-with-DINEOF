function [output, eigenvalues, varargout] = EOFCore(data, mask, eofs, varargin)

% Calculating the EOF estimates
% Usage: [estimated, eigenvalues] = EOF(data, mask, value, [stop_criterion], [max_iteration_rounds]);
%
% data must be in the correct EOF format with only 2 dimensions, one
% spatial and one temporal.
%
% mask is a binary matrix with the same size as data. It has one in the
% case of missing value (already replaced by Initialization) and zero in
% the case of known value from the dataset.
%
% value can be a scalar, defining the number of EOFs to use. Or it can be a
% vector, defining which specific EOFs to use. Or it can be a matrix, defining
% which EOFs to use in each round, where rounds are the rows of the matrix. In
% a case there is different number of EOFs selected for each round, the
% selections should be padded with zeros.
%
% [stop_criterion] defines the minimum amount of change, after which
% the iteration is terminated. Default is one.
%
% [max_iteration_rounds] defines the maximum number of iteration rounds to
% perform. Default is infinity.

switch nargin
  case 3
    stop = 1;
    rounds = inf;
  case 4
    stop = varargin{1};
    rounds = inf;
  case 5
    if isempty(varargin{1})
      stop = 1;
    else
      stop = varargin{1};
    end
    
    rounds = varargin{2};
end

if isscalar(eofs)
  if eofs > min(size(data))
    value = 1:min(size(data));
  else
    value = 1:eofs;
  end
else
  value = eofs;
end

if isvector(value)
  % In case normal EOF procedure is needed, consecutive or selected EOFs
  value(value == 0) = [];
  
  reference = zeros(size(data));
  
  [U, eigenvalues, V] = svds(data, max(value));
  
  output = data - data .* mask + ...
    U(:,value) * eigenvalues(value,value) * V(:,value)' .* mask;
  
  roundcount = 1;
  
  while sum(sum((reference .* mask - output .* mask) .^2)) > stop
    if roundcount >= rounds
      break;
    end
    
    reference = output;
    
    [U, eigenvalues, V] = svds(output, max(value));
    
    output = data - data .* mask + ...
      U(:,value) * eigenvalues(value,value) * V(:,value)' .* mask;
    
    roundcount = roundcount + 1;
  end
  
  switch nargout
    case 3
      varargout{1} = roundcount;
    case 4
      varargout(1) = U;
      varargout(2) = V;
  end
  
else
  % In case EOF Pruned calculation is needed
  for round = 1:min([size(value,1) rounds])
    % Sorting and separating the selected EOFs for this round
    index = sort(value(round,:));
    index(index == 0) = [];
    
    [U, eigenvalues, V] = svds(data, max(index));
    
    output = data - data .* mask + ...
      U(:,index) * eigenvalues(index,index) * V(:,index)' .* mask;
  end
  
  switch nargout
    case 3
      varargout{1} = [];
    case 4
      varargout(1) = [];
      varargout(2) = [];
  end
  
end % If isvector

