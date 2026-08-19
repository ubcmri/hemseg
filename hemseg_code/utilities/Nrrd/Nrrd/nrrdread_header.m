function img = nrrdread_header(filename)
% Read image and metadata from a NRRD file (see http://teem.sourceforge.net/nrrd/format.html)
%   img = cli_imageread(filename) reads the image volume and associated metadata
%
%   img.pixelData: pixel data array
%   img.ijkToLpsTransform: pixel (IJK) to physical (LPS, assuming 'space' is 'left-posterior-superior')
%     coordinate system transformation, the origin of the IJK coordinate system is (1,1,1) to match Matlab matrix indexing
%   img.metaData: contains all the descriptive information in the image header
%   img.metaDataFieldNames: Contains full names of metadata fields that cannot be used as Matlab field names because they contains
%     special characters (space, dot, etc). Special characters in field names are replaced by underscore by default when the NRRD
%     file is read. Full field names are used when writing the image to NRRD file.
%
%  Supports reading of 3D and 4D volumes.
%
%   Current limitations/caveats:
%   * Block datatype is not supported.
%   * Only tested with "gzip" and "raw" file encodings.
%
% Partly based on the nrrdread.m function with copyright 2012 The MathWorks, Inc.

fid = fopen(filename, 'rb');
assert(fid > 0, 'Could not open file.');
cleaner = onCleanup(@() fclose(fid));

% NRRD files must start with the NRRD word and a version number
theLine = fgetl(fid);
assert(numel(theLine) >= 4, 'Bad signature in file.')
assert(isequal(theLine(1:4), 'NRRD'), 'Bad signature in file.')

% The general format of a NRRD file (with attached header) is:
% 
%     NRRD000X
%     <field>: <desc>
%     <field>: <desc>
%     # <comment>
%     ...
%     <field>: <desc>
%     <key>:=<value>
%     <key>:=<value>
%     <key>:=<value>
%     # <comment>
% 
%     <data><data><data><data><data><data>...

img.metaData = {};
img.metaDataFieldNames = {};
% Parse the file a line at a time.
while (true)

  theLine = fgetl(fid);

  if (isempty(theLine) || feof(fid))
    break;
  elseif (theLine == -1)      
    % End of the header.
    break;
  end  
   
  if (isequal(theLine(1), '#'))
      % Comment line.
      continue;
  end
  
  % "fieldname:= value" or "fieldname: value" or "fieldname:value"
  parsedLine = regexp(theLine, ':=?\s*', 'split','once');
  
  assert(numel(parsedLine) == 2, 'Parsing error')
  
  field = parsedLine{1};
  value = parsedLine{2};
      
  % Cannot use special characters in field names, so replace them by underscore
  % and store the original field name in img.metaDataFieldNames so that it can be
  % restored when writing the data.
  fieldName=regexprep(field,'\W','_');
  if ~strcmp(fieldName,field)
    img.metaDataFieldNames.(fieldName) = field;
  end
  
  img.metaData(1).(fieldName) = value;
  
end


% Get the size of the data.
assert(isfield(img.metaData, 'sizes') && ...
       isfield(img.metaData, 'dimension') && ...
       isfield(img.metaData, 'encoding'), ...
       'Missing required metadata fields (sizes, dimension, or encoding).')

dims = sscanf(img.metaData.sizes, '%d');
ndims = sscanf(img.metaData.dimension, '%d');
assert(numel(dims) == ndims);

% For convenience, compute the transformation matrix between physical and pixel coordinates
switch (ndims)
 case {3}
  axes_directions=reshape(sscanf(img.metaData.space_directions,'(%f,%f,%f) (%f,%f,%f) (%f,%f,%f)'),3,3);
 case {4}
  axes_directions=reshape(sscanf(img.metaData.space_directions,'none (%f,%f,%f) (%f,%f,%f) (%f,%f,%f)'),3,3);
 otherwise
  assert(false, 'Unsupported pixel data dimension')
end
if ~isfield(img.metaData,'space_origin')
    img.metaData.space_origin='(0,0,0)';
end
axes_origin=sscanf(img.metaData.space_origin,'(%f,%f,%f)');
ijkZeroBasedToLpsTransform=[[axes_directions, axes_origin]; [0 0 0 1]];
ijkOneBasedToIjkZeroBasedTransform=[[eye(3), [-1;-1;-1] ]; [0 0 0 1]];
ijkOneBasedToLpsTransform=ijkZeroBasedToLpsTransform*ijkOneBasedToIjkZeroBasedTransform;
% Use the one-based IJK transform (origin is at [1,1,1])
img.ijkToLpsTransform=ijkOneBasedToLpsTransform;

