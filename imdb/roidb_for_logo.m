function roidb = roidb_for_logo(imdb)
    gt_dir = fullfile(imdb.root_dir,'classes','masks');
    img_num = imdb.img_num;
    roidb.set = imdb.set;
    roidb.root_dir = imdb.root_dir;
%     num = 1;
    rois = [];
    for i = 1:img_num
        img_name = imdb.img_name{i};
        img_class = imdb.img_class_str{i};
        if strcmp(img_class,'no-logo') continue;end    
        filepath = fullfile(gt_dir,img_class,[img_name,'.bboxes.txt']);
        rect = read_rect_file(filepath);
        tmp.img_name = img_name;
        tmp.img_id = i;
        tmp.gt_boxes = rect;
        tmp.img_class_str = img_class;
        tmp.img_class_id = imdb.class_to_id(img_class);
        rois = [rois;tmp];
    end
    roidb.img_num = length(rois);
    roidb.rois = rois;
    
    
    function rect = read_rect_file(filepath)
        file = fopen(filepath,'r');
        tline = fgetl(file);
        tline = fgetl(file);
        rect = [];
        while(ischar(tline))
            tline = deblank(tline);
            tparts = regexp(tline,'\s+','split');
            tparts = cellfun(@(x) str2num(x),tparts,'un',false);
            tparts = cell2mat(tparts);
            rect = [rect;tparts];
            tline = fgetl(file);
        end
        fclose(file);
