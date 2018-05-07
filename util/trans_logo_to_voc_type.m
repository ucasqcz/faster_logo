function trans_logo_to_voc_type(src_fold,dst_fold)

src_fold = '/data1/NLPRMNT/wanghongsong/DataSet/FlickrLogos-v2';
dst_fold = '/data1/NLPRMNT/wanghongsong/DataSet/FlickrLogos32/VOCdevit/FlickrLogos32';

addpath(fullfile(dst_fold,'../','VOCcode'));
%% copy imgs
img_dst_fold = fullfile(dst_fold,'JPEGImages');
if length(dir(img_dst_fold)) <= 3
    img_fold = fullfile(src_fold,'classes','jpg');
    file_path = getRecurFiles(img_fold);
    [s,~,~] = cellfun(@(x) copyfile(x,img_dst_fold),file_path,'un',false);
end

%% calc the gt label
mask_fold = fullfile(src_fold,'classes','masks');
mask_path = getRecurFiles(mask_fold);
bool_txt = cellfun(@(x) numel(strfind(x,'.txt')),mask_path,'un',false);
bool_txt = cell2mat(bool_txt);
mask_path = mask_path(find(bool_txt>0));

recs = cellfun(@(x) txt_to_rec(x),mask_path,'un',false);
% save the recs
tmp_fold = fullfile(dst_fold,'Annotations');
file_num = length(recs);
r = cellfun(@(x) write_xml(x,tmp_fold),recs,'un',false);

disp('finished!');
end
function rec = txt_to_rec(path)
tic;
[fold,name,~] = fileparts(path);
[fold,label,~] = fileparts(fold);

img_name = sp_str(name);
boxes = get_boxes(path);
img_path = fullfile(fold,'../','jpg',label,img_name);
s = size(imread(img_path));
x.width = s(2);x.height = s(1);x.depth = s(3);

rec.annotation.folder = 'FlickrLogos32';
rec.annotation.filename = img_name;
rec.annotation.source.database = 'FlickrLogos32';
rec.annotation.size = x;
rec.annotation.segmented = '0';

for i = 1:size(boxes,1)
    b.xmin = num2str(boxes(i,1));b.ymin = num2str(boxes(i,2));b.xmax = num2str(boxes(i,3));b.ymax = num2str(boxes(i,4));
    t(i).name = label;t(i).bndbox = b;
end
rec.annotation.object = t;
toc
end
function img_name = sp_str(name)
pos = strfind(name,'.');
img_name = name(1:pos(2)-1);
end
function boxes = get_boxes(path)
file = fopen(path,'r');
tline = fgetl(file);
tline = fgetl(file);
boxes = [];
while(ischar(tline))
    t_part = regexp(tline,'\s+','split');
    t_part = cellfun(@(x) str2num(x),t_part,'un',false);
    boxes = [boxes;cell2mat(t_part)];
    tline = fgetl(file);
end
fclose(file);

boxes(:,3) = boxes(:,1) + boxes(:,3) - 1;
boxes(:,4) = boxes(:,2) + boxes(:,4) - 1;
end
function s = write_xml(rec,fold)
tic;
img_name = rec.annotation.filename;
[~,name,ext] = fileparts(img_name);
save_xml = [name,'.xml'];
path = fullfile(fold,save_xml);
VOCwritexml(rec,path);
s = 1;
toc
end