function imdb_test = imdb_reduction(imdb_test)
    % remove non-logo image
    class_id = imdb_test.class_to_id('no-logo');
    img_class_id = cell2mat(imdb_test.img_class_id);
    logo_index = find(img_class_id ~= class_id);
    
    imdb_new = imdb_test;
    imdb_new.img_name = imdb_new.img_name(logo_index);
    imdb_new.img_dir = imdb_new.img_dir(logo_index);
    imdb_new.img_num = numel(logo_index);
    imdb_new.num_classes = imdb_new.num_classes - 1;
    imdb_new.img_to_id = containers.Map(imdb_new.img_name,1:imdb_new.img_num);
    remove(imdb_new.class_to_id,'no-logo');
    imdb_new.img_class_str = imdb_new.img_class_str(logo_index);
    imdb_new.img_class_id = imdb_new.img_class_id(logo_index);
    
    imdb_test = imdb_new;
    
end