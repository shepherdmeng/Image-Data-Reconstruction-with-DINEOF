function output = DeNormalize(data, varargin)

% DeNormalization, counters the normalization and initialization
% Usage: output = DeNormalize(data, ['param', values])
%
% Remember, that the DeNormalization must be done exactly in reverse order
% than Normalization! Parameters must also be given in correctly reversed
% order.
%
% Params include:
%    'mean'     Mean value or vector
%    'std'      Standard deviation value or vector
%
% Each parameter is accompanied with the corresponding value. Both
% parameters can be given multiple times, if necessary. Each pair is
% processed in the given order, which MUST be exactly reversed from the
% normalization performed.
%
% If no parameters are given, nothing is done to the data and output is the
% same as data given as input.

output = data;
[rows, columns] = size(data);

if mod(nargin,2) == 0
	disp('Number of arguments must be odd --> Aborted!');
	return;
end

for i = 1:2:nargin-1
	switch lower(varargin{i})
		case 'mean'
			if sum(size(varargin{i+1})) == 2
				output = output + varargin{i+1};
			elseif size(varargin{i+1},1) > size(varargin{i+1},2)
				output = output + (varargin{i+1} * ones(1,columns));
			else
				output = output + (ones(rows,1) * varargin{i+1});
			end

		case 'std'
			if sum(size(varargin{i+1})) == 2
				output = output .* varargin{i+1};
			elseif size(varargin{i+1},1) > size(varargin{i+1},2)
				output = output .* (varargin{i+1} * ones(1,columns));
			else
				output = output .* (ones(rows,1) * varargin{i+1});
			end

		otherwise
			disp(['Unrecognized switch ' varargin{i} ' --> Ignored!']);
	end
end

