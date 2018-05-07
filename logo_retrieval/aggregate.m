function [roi_fea,total_fea] = aggregate(in)
    % first sum then max pooling
    fea = sum(sum(in,1),2);
    roi_fea = squeeze(fea);
    total_fea = max(roi_fea,[],2);
end