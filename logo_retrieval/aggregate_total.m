function [roi_fea,total_fea] = aggregate_total(fea,conv_fea_blob,method)
	if strcmp(method,'max')
		fea = max(max(fea,[],1),[],2);
		roi_fea = squeeze(fea);
		total_fea = max(max(conv_fea_blob,[],1),[],2);
		total_fea = reshape(total_fea,[],1);
	elseif strcmp(method,'sum')
		fea = sum(sum(fea,1),2);
		roi_fea = squeeze(fea);
		total_fea = sum(sum(conv_fea_blob,1),2);
		total_fea = reshape(total_fea,[],1);
	end
	
end