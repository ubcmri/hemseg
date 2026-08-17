function changeLps2RasNrrd(nrrd_filepath,postfix_string)

img=nrrdread(nrrd_filepath);
[dirpath,basename,ext] = fileparts(nrrd_filepath);
[affine_matrix,voxel_size,origin] = extractNrrdInfo(img.metaData,img.ijkToLpsTransform);

% affine_matrix(1:3,4) = origin;
affine_matrix(1,:) = -affine_matrix(1,:);
affine_matrix(2,:) = -affine_matrix(2,:);

img.ijkToLpsTransform = affine_matrix;

nrrdwrite([dirpath filesep basename postfix_string ext],img);
