% Copyright (C) 2013 Alex Burka
% 
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with Octave; see the file COPYING.  If not, see
% <http://www.gnu.org/licenses/>.

% deltas

% Author: Alex Burka <alex@seas1366.wireless-pennnet.upenn.edu>
% Created: 2013-07-24

function [ D ] = deltas (X)

n = size(X,2);
combs = combnk(1:n, 2);
D = cell(1, size(combs,1));

for i=1:size(combs,1)
    D{i} = zeros(size(X,1), size(X,3), size(X,4));
    for j=1:size(X,1)
        D{i}(j,:,:) = squeeze(X(j,combs(i,1),:,:)) \ squeeze(X(j,combs(i,2),:,:));
    end
end

end
