function [deltaMap,cmap] = getSlope(imseries,mask,x_values)

dim = size(imseries);
n_frame = size(imseries,1);

deltaMap = cell(1,n_frame-1);

red_cmap = zeros(100,3);
red_cmap(:,1) = (1:100)/100;
red_cmap = flip(red_cmap,1);
green_cmap = zeros(100,3);
green_cmap(:,2) = (1:100)/100;

cmap = [red_cmap; green_cmap];

for i_comparison = 1:n_frame-1
    curr_slope = (imseries{i_comparison+1} - imseries{i_comparison})/(x_values(i_comparison+1) - x_values(i_comparison));
%     curr_slope = (imseries{i_comparison+1} - imseries{i_comparison})./(imseries{i_comparison});
    
    curr_slope(mask) = 0;
    deltaMap{i_comparison} = double(curr_slope);
end