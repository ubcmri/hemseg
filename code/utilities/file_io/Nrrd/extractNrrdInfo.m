function [affine_matrix,voxel_size,origin] = extractNrrdInfo(metaData,ijkToLpsTransform)


origin_tokens = strsplit(metaData.space_origin,{'(',',',')'});
origin = [str2num(origin_tokens{2}) str2num(origin_tokens{3}) str2num(origin_tokens{4})];

affine_matrix = ijkToLpsTransform;

voxel_size = zeros(1,3);
voxel_size(1) =   round(sqrt(sumsqr(ijkToLpsTransform(1:3,1))),5);
voxel_size(2) =   round(sqrt(sumsqr(ijkToLpsTransform(1:3,2))),5);
voxel_size(3) =   round(sqrt(sumsqr(ijkToLpsTransform(1:3,3))),5);
