%% 递归的获得一个文件夹内的所有文件路径
function [files] = getRecurFiles(path)
    list = dir(path);
    list = list(3:end);
    list = {list.name};
    files = {};
    for i = 1:length(list)
        tmp = fullfile(path,list{i});
        if isdir(tmp)
            innerList = getRecurFiles(tmp);
            files = [files innerList];
        else
            files = [files tmp];
        end
    end 
end