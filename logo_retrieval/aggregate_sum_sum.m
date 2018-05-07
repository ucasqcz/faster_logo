function [roi_fea,total_fea] = aggregate_sum_sum(fea,score,score_flag)
	fea = sum(sum(fea,1),2);
	roi_fea = squeeze(fea);
	if score_flag
		score = score';
		score = score.^2;
		mask = repmat(score,size(roi_fea,1),1);
	else
		mask = ones(size(roi_fea));
	end

	total_fea = sum(roi_fea.*mask,2);
	total_fea = reshape(total_fea,[],1);
	
end