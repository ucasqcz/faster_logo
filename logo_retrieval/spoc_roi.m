function [fea,rois_feature] = spoc_roi(conf,im,fea,rois,score_flag,scores)
    if nargin < 6
        scores = rois(:,5);
        rois = rois(:,1:4);
    end
    [fea_rois,~ ] = get_blobs(conf,im,rois);
    fea_rois = fea_rois(:,2:end);
    
    fea = permute(fea,[2,1,3,4]);
    mask = zeros(size(fea,1),size(fea,2));
    
    fea_rois = round(fea_rois / conf.feat_stride);
    fea_rois = refine_roi_bound(fea_rois,[size(fea,1),size(fea,2)]);
    
    rois_feature = {};
    
	
    for i = 1:size(fea_rois,1)
        tmp = mask(fea_rois(i,2):fea_rois(i,4),fea_rois(i,1):fea_rois(i,3));
        tmp = tmp + score_flag*scores(i) + (1-score_flag)*1;
        mask(fea_rois(i,2):fea_rois(i,4),fea_rois(i,1):fea_rois(i,3)) = tmp;
        rois_feature{i} = fea(fea_rois(i,2):fea_rois(i,4),fea_rois(i,1):fea_rois(i,3),:);
    end
    re_mask = repmat(mask,1,1,size(fea,3));
    fea = fea.*re_mask;
    fea = sum(sum(fea,1),2) / (size(fea,1)*size(fea,2));
    fea = squeeze(fea);
    fea = reshape(fea,[],1);
end
function [fea_rois] = refine_roi_bound(fea_rois,fea_size)
    x1 = fea_rois(:,1);
    x1(x1<1) = 1;
    y1 = fea_rois(:,2);
    y1(y1<1) = 1;
    x2 = fea_rois(:,3);
    x2(x2>fea_size(2)) = fea_size(2);
    y2 = fea_rois(:,4);
    y2(y2>fea_size(1)) = fea_size(1);
    fea_rois = [x1,y1,x2,y2];
end
function [rois_blob, im_scale_factors] = get_blobs(conf, im, rois)
    im_scale_factors = get_image_blob_scales(conf, im);
    rois_blob = get_rois_blob(conf, rois, im_scale_factors);
end

function im_scales = get_image_blob_scales(conf, im)
    im_scales = arrayfun(@(x) prep_im_for_blob_size(size(im), x, conf.test_max_size), conf.test_scales, 'UniformOutput', false);
    im_scales = cell2mat(im_scales); 
end

function [rois_blob] = get_rois_blob(conf, im_rois, im_scale_factors)
    [feat_rois, levels] = map_im_rois_to_feat_rois(conf, im_rois, im_scale_factors);
    rois_blob = single([levels, feat_rois]);
end

function [feat_rois, levels] = map_im_rois_to_feat_rois(conf, im_rois, scales)
    im_rois = single(im_rois);
    
    if length(scales) > 1
        widths = im_rois(:, 3) - im_rois(:, 1) + 1;
        heights = im_rois(:, 4) - im_rois(:, 2) + 1;
        
        areas = widths .* heights;
        scaled_areas = bsxfun(@times, areas(:), scales(:)'.^2);
        levels = max(abs(scaled_areas - 224.^2), 2); 
    else
        levels = ones(size(im_rois, 1), 1);
    end
    
    feat_rois = round(bsxfun(@times, im_rois-1, scales(levels))) + 1;
end