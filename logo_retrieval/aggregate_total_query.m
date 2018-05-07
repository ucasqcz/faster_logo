function [roi_fea,total_fea] = aggregate_total_query(fea,conv_fea_blob,method)
	roi_fea = fea;
	if strcmp(method,'max')
		fea = max(max(fea,[],1),[],2);
		total_fea = squeeze(fea);
		total_fea = mean(total_fea,2);
		total_fea = reshape(total_fea,[],1);
	elseif strcmp(method,'sum')
		fea = sum(sum(fea,1),2);
		total_fea = squeeze(fea);
		total_fea = mean(total_fea,2);
		total_fea = reshape(total_fea,[],1);
	end
	
end