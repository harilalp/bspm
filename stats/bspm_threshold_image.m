function out = bspm_threshold_image(in, heightThresh, sizeThresh, binflag, outname, doposneg, ndilate)
% BSPM_THRESHOLD_IMAGE
%
% USAGE: out = bspm_threshold_image(in, heightThresh, sizeThresh, binflag, outname)
%
%   ARGUMENTS
%       in:                     input image name (full path if not in current directory)
%       heightThresh:   intensity threshold f(if < .10, will assume it is
%                               an alpha level and will covert to critical t)
%       sizeThresh:      extent threshold for defining clusters
%       binflag:            flag to binarize output image (default = 0)
%       outname:         name for file to write (default = no file written)
%       
% Created January 1, 2013 - Bob Spunt

% --------------------------------- Copyright (C) 2014 ---------------------------------
%	Author: Bob Spunt
%	Affilitation: Caltech
%	Email: spunt@caltech.edu
%
%	$Revision Date: Aug_20_2014
if nargin<6, doposneg = 0; end
if nargin<5, outname = []; end; 
if nargin<4, binflag = 0; end;
if nargin<3, mfile_showhelp; return; end
if iscell(in), in = char(in); end;
if nargin<7, ndilate = 0; end


% load images
% ------------------------------------------------------
try
    in_hdr = spm_vol(in);
    in = spm_read_vols(in_hdr);
catch
    in = in;
end
imdims = size(in);
% if necessary, calculate critical t
if ismember(heightThresh,[.10 .05 .01 .005 .001 .0005 .0001]);
    tmp = in_hdr.descrip;
    idx1 = regexp(tmp,'[','ONCE');
    idx2 = regexp(tmp,']','ONCE');
    df = str2num(tmp(idx1+1:idx2-1));
    heightThresh = bspm_p2t(heightThresh, df);
end
in(in==0)=NaN;
in0 = in; 
if doposneg
    in(abs(in) < heightThresh) = NaN;
else
    in(in<heightThresh) = NaN;
end


% grab voxels
% ------------------------------------------------------
[X, Y, Z] = ind2sub(imdims, find(~isnan(in)));
voxels = sortrows([X Y Z])';

% get cluster indices of voxels
% ------------------------------------------------------
cl_index    = spm_clusters(voxels);
cl_bin      = repmat(1:max(cl_index), length(cl_index), 1)==repmat(cl_index', 1, max(cl_index)); 
cl_pass     = cl_bin(:,sum(cl_bin) >= sizeThresh); 
cl_vox      = voxels(:, any(cl_pass, 2));
cl_idx      = sub2ind(imdims, cl_vox(1,:), cl_vox(2,:), cl_vox(3,:)); 
out         = nan(size(in)); 
out(cl_idx) = in(cl_idx);
m = double(~isnan(out));
if ndilate
    kernel = cat(3,[0 0 0; 0 1 0; 0 0 0],[0 1 0; 1 1 1; 0 1 0],[0 0 0; 0 1 0; 0 0 0]);
    for i = 1:ndilate, m = spm_dilate(m, kernel); end
    out = in0; 
    out(m~=1) = NaN; 
end
if binflag
    out =  m; 
else
    out(out==0) = NaN; 
end
if ~isempty(outname)
    
    h = in_hdr;
    h.fname = outname;
    tmp = h.descrip;
    h.descrip = [tmp sprintf(' - THRESHOLDED: %2.3f, %d', heightThresh, sizeThresh)];
    spm_write_vol(h,out);
    
end
end






 
 
 
 
 
 
 
 
