function imdb = imdb_for_logo(root_dir,image_set)

if strcmp(image_set,'all')
    set_name = 'all';
else
    set_name = [image_set,'set'];
end
imdb.root_dir = root_dir;
imdb.set = image_set;

filenames_txt = [set_name,'.filenames.txt'];filenames_txt = fullfile(root_dir,filenames_txt);
relpaths_txt = [set_name,'.relpaths.txt'];relpaths_txt = fullfile(root_dir,relpaths_txt);
spaces_txt = [set_name,'.spaces.txt'];spaces_txt = fullfile(root_dir,spaces_txt);

names_list = read_file(filenames_txt);
relpaths_list = read_file(relpaths_txt);
spaces_list = read_file(spaces_txt,1);
imdb.img_name = names_list;
imdb.img_dir = cellfun(@(x) fullfile(root_dir,x),relpaths_list,'un',false);
imdb.img_num = length(names_list);
imdb.img_to_id = containers.Map(imdb.img_name,1:imdb.img_num);
classes = cellfun(@(x) x{1},spaces_list,'un',false);
% names = cellfun(@(x) x{2},spaces_list,'un',false);
% if names ~= names_list disp('error img list\n'); end

u_classes = unique(classes);
class_num = length(u_classes);
imdb.num_classes = class_num;
imdb.class_to_id = containers.Map(u_classes,1:class_num);
imdb.img_class_str = classes;
imdb.img_class_id = cellfun(@(x) imdb.class_to_id(x),classes,'un',false);









function name_list = read_file(filepath,with_space)
    space_flag = 0;
    if nargin ~= 2
        space_flag = 0;
    else
        space_flag = with_space;
    end
    file = fopen(filepath,'r');
    tline = fgetl(file);
    
    name_list = {};
    while(ischar(tline))
        tline = deblank(tline);
        if space_flag
            tparts = regexp(tline,'\s+','split');
        else
            tparts = tline;
        end
        name_list = [name_list,{tparts}];
        tline = fgetl(file);
    end
    fclose(file);