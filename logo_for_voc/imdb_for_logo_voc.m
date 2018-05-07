function imdb = imdb_for_logo_voc(root_dir,image_set,flip)

if nargin<3
    flip = false;
end
cache_file = ['../imdb/imdb_logo_voc_',image_set];
if flip
    cache_file = [cache_file,'_flip'];
end
try 
    load(cache_file);
catch
    


end