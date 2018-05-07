%% retrieval logo data set
function script_logo_retrieval_demo_max_sum_score()

addpath('../../');
addpath('../../external/caffe/matlab');

startup;
clear all;clc;
addpath('../imdb');
logo_dataset = '/data1/NLPRMNT/wanghongsong/DataSet/FlickrLogos-v2';
[imdb_test,imdb_trainval] = prepare_imdb(logo_dataset);

method = 'max_sum_trainval';
score_flag = findstr(method,'score');
if numel(score_flag) ~= 0
	score_flag = 1;
else
	score_flag = 0;
end
fprintf('score flag is %d\n',score_flag);

opts.gpu_id                 = auto_select_gpu;
opts.per_nms_topN           = 6000;
opts.nms_overlap_thres      = 0.7;
opts.after_nms_topN         = 300;
opts.use_gpu                = true;
gpuDevice(opts.gpu_id);

opts.test_scales            = 600;

model_path = '/data1/NLPRMNT/wanghongsong/faster_rcnn/output/faster_rcnn_final/faster_rcnn_LogoFlickr32_fea';
model = load_proposal_detection_model(model_path);

model.conf_proposal.test_scales = opts.test_scales;
model.conf_detection.test_scales = opts.test_scales;
if opts.use_gpu
    model.conf_proposal.image_means = gpuArray(model.conf_proposal.image_means);
    model.conf_detection.image_means = gpuArray(model.conf_detection.image_means);
end


% proposal net
rpn_net = caffe.Net(model.proposal_net_def, 'test');
rpn_net.copy_from(model.proposal_net);
% fast rcnn net
fast_rcnn_net = caffe.Net(model.detection_net_def, 'test');
fast_rcnn_net.copy_from(model.detection_net);

if(opts.use_gpu)
    caffe.set_mode_gpu();
else
    caffe.set_mode_cpu();
end

str = ['img_fea_',method];
img_fea= {};
conv_5_fea = {};
% gen feature
try 
    load([str,'.mat']);
%	load('conv_5_fea.mat');
catch
    for i = 1:length(imdb_trainval.img_dir)
        im = imread(imdb_trainval.img_dir{i});
		im_size = size(im);
		
        if opts.use_gpu
            im = gpuArray(im);
        end

        th = tic();
        [boxes, scores]             = proposal_im_detect(model.conf_proposal, rpn_net, im);
        t_proposal = toc(th);
        th = tic();
        aboxes_tmp                      = boxes_filter([boxes, scores], opts.per_nms_topN, opts.nms_overlap_thres, opts.after_nms_topN, opts.use_gpu);
        t_nms = toc(th);
        fprintf('%dth %s (%dx%d) : time  %f \n',i,imdb_trainval.img_name{i},size(im,1),size(im,2),t_nms+t_proposal);
		
        [fea] = fast_rcnn_feat_roi(model.conf_detection,fast_rcnn_net,im, ...
            rpn_net.blobs(model.last_shared_output_blob_name), ...
            aboxes_tmp(:,1:4),opts.after_nms_topN);
        %% aggregation method
%        [roi_fea,total_fea]  = aggregate(fea);
		[roi_fea,total_fea] = aggregate_max_sum(fea,aboxes_tmp(:,5),score_flag);
        %% L2 normalization
        total_fea = total_fea/sqrt(sum(total_fea.^2));
        tmp_fea.roi_fea = roi_fea;
        tmp_fea.fea = total_fea;
        tmp_fea.name = imdb_trainval.img_name{i};
        img_fea{i} = tmp_fea;  
    end
    save([str,'.mat'],'img_fea','-v7.3');
%	save('conv_5_fea.mat','conv_5_fea','-v7.3');
end

imdb_test = imdb_reduction(imdb_test);
roidb_test = roidb_for_logo(imdb_test);

%%  use aggregation feature
db_fea = cellfun(@(x) x.fea,img_fea,'un',false);
db_name = cellfun(@(x) x.name,img_fea,'un',false);
db_roi_fea = cellfun(@(x) x.roi_fea,img_fea,'un',false);


db_fea_mat = cell2mat(db_fea);

%% 更改 query expansion 加上 query 图片
rerank_num = [500];qe_num = [1,3,5];
%rerank_num = [500];qe_num = [1,3,5];

for r_i = 1:numel(rerank_num)
for q_j = 1:numel(qe_num)

r_n = rerank_num(r_i);q_n = qe_num(q_j);

if(r_n == 0 && q_n ~= 0)
	continue;
end
if(r_n ~= 500 && q_n ~= 0)
	continue;
end

result_head = ['./retrieval_result_part_re_rerank_',num2str(r_n),'_qe_',num2str(q_n),'_'];
result_dir = [result_head,method];
if ~exist(result_dir,'dir') mkdir(result_dir);end

for i = 1:960 %length(imdb_test.img_name)
    name = imdb_test.img_name{i};
	%% get query fea
	q_dir = imdb_test.img_dir{i};
	q_im = imread(q_dir);
	if(opts.use_gpu)
		q_im = gpuArray(q_im);
	end
	
	%% use part roi as query image
	th = tic();
	[~, ~]             = proposal_im_detect(model.conf_proposal, rpn_net, q_im);
	t_proposal = toc(th);
	
	img_id = imdb_test.img_to_id(name);
	rois = roidb_test.rois(img_id).gt_boxes;
	rois(:,3) = rois(:,1) + rois(:,3) + 1;
	rois(:,4) = rois(:,2) + rois(:,4) + 1;
	rois = [rois,ones(size(rois,1),1)];
	
	th = tic();
	[fea] = fast_rcnn_feat_roi(model.conf_detection,fast_rcnn_net,q_im, ...
            rpn_net.blobs(model.last_shared_output_blob_name), ...
            rois(:,1:4),opts.after_nms_topN);
	[roi_fea,total_fea] = aggregate_max_sum(fea,rois(:,5),score_flag);
	total_fea = total_fea/sqrt(sum(total_fea.^2));
	t_fea = toc(th);
	fprintf('%dth %s (%dx%d) : time  %f \n',i,imdb_trainval.img_name{i},size(q_im,1),size(q_im,2),t_fea+t_proposal);
	q_fea = total_fea;
	
    %assert(strcmp(name,db_name{id}));
    dis = bsxfun(@minus,db_fea_mat,q_fea);
    dis = sum(dis.^2,1);
    dis = dis/max(dis);
    dis = 1-dis;
    [re,ind] = sort(dis,'descend');
	
	
%	rerank_num = 500;
	if r_n ~= 0
		tmp_q_fea = q_fea;
		dis_rerank = zeros(1,r_n);
		qe_fea_rerank = zeros(size(q_fea,1),r_n);
		for k = 1:r_n
			% roi_fea L2 normalization
			fea_mat = db_roi_fea{ind(k)};
			fea_sum = sqrt(sum(fea_mat.^2,1));
			fea_mat = bsxfun(@rdivide,fea_mat,fea_sum);
			fea_mat(isnan(fea_mat)) = 0;
			dis_rois = bsxfun(@minus,fea_mat,tmp_q_fea);
			
			dis_rois = sum(dis_rois.^2,1);
			dis_rois = dis_rois/max(dis_rois);
			dis_rois = 1 - dis_rois;
			[dis_rerank(k),id] = max(dis_rois);
			qe_fea_rerank(:,k) = fea_mat(:,id);
		end
		tmp_ind = ind(1:r_n);
		[re_rerank,ind_rerank] = sort(dis_rerank,'descend');
		ind(1:r_n) = tmp_ind(ind_rerank);
	end
	
	%% query expansion
	if r_n == 500 && q_n ~= 0
		qe_fea_rerank = qe_fea_rerank(:,ind_rerank);
		q_x_num = q_n;
	% 	q_x_mean = mean(db_fea_mat(:,ind(1:q_x_num)),2);
		q_x_mean = qe_fea_rerank(:,1:q_x_num);
		q_x_mean = [q_x_mean,q_fea];
		q_x_mean = mean(q_x_mean,2);
	%	q_x_mean = mean(qe_fea_rerank(:,1:q_x_num),2);
	%	q_x_mean = mean(db_fea_mat(:,ind(1:q_x_num)),2);
	
		q_x_mean = q_x_mean / sqrt(sum(q_x_mean.^2));
		dis_qx = bsxfun(@minus,db_fea_mat,q_x_mean);
		dis_qx = sum(dis_qx.^2,1);
		dis_qx = dis_qx/max(dis_qx);
		dis_qx = 1-dis_qx;
		[re,ind] = sort(dis_qx,'descend');
	end
	

	
    file_name = [name,'.result2.txt'];
    out_file = fopen(fullfile(result_dir,file_name),'w');
    
    for idx = 1:numel(re)
        fprintf(out_file,'%s\t%f\n',imdb_trainval.img_dir{ind(idx)},re(idx));
    end
    
    fclose(out_file);
    fprintf('finish %d img : %s\n',i,name);
end

end
end

end
function proposal_detection_model = load_proposal_detection_model(model_dir)
    ld                          = load(fullfile(model_dir, 'model'));
    proposal_detection_model    = ld.proposal_detection_model;
    clear ld;
    
    proposal_detection_model.proposal_net_def ...
                                = fullfile(model_dir, proposal_detection_model.proposal_net_def);
    proposal_detection_model.proposal_net ...
                                = fullfile(model_dir, proposal_detection_model.proposal_net);
    proposal_detection_model.detection_net_def ...
                                = fullfile(model_dir, proposal_detection_model.detection_net_def);
    proposal_detection_model.detection_net ...
                                = fullfile(model_dir, proposal_detection_model.detection_net);
    
end
function aboxes = boxes_filter(aboxes, per_nms_topN, nms_overlap_thres, after_nms_topN, use_gpu)
    % to speed up nms
    if per_nms_topN > 0
        aboxes = aboxes(1:min(length(aboxes), per_nms_topN), :);
    end
    % do nms
    if nms_overlap_thres > 0 && nms_overlap_thres < 1
        aboxes = aboxes(nms(aboxes, nms_overlap_thres, use_gpu), :);       
    end
    if after_nms_topN > 0
        aboxes = aboxes(1:min(length(aboxes), after_nms_topN), :);
    end
end