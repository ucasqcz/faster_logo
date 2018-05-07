function [imdb_test,imdb_trainval] = prepare_imdb(logo_dataset)
try
    imdb_test = load('../imdb/imdb_logo_test.mat');
    imdb_test = imdb_test.imdb;
catch
    imdb_test = imdb_for_logo(logo_dataset,'test');
    imdb = imdb_test;
    save('../imdb/imdb_logo_test.mat','imdb','-v7.3');
    clear imdb;
end
try
    imdb_trainval = load('../imdb/imdb_logo_trainval.mat');
    imdb_trainval = imdb_trainval.imdb;
catch
    imdb_trainval = imdb_for_logo(logo_dataset,'trainval');
    imdb = imdb_trainval;
    save('../imdb/imdb_logo_trainval.mat','imdb','-v7.3');
    clear imdb;
end
end