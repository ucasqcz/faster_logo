%% 从每个子文件夹中选择一定样本重新组织
%   path:       初始路径
%   num:        每个文件夹采样数量,  num为0时全部采样
%   totalNum:   返回总共的样本数目
%   savePath:   将样本保存到新的路径下
function totalNum = sampleFiles(path,saveFold,num)
    list = dir(path);
    list = list(3:end);
    list = {list.name};
    totalNum = 0;
    if ~exist(saveFold,'dir')
        mkdir(saveFold);
    end
    
    for i = 1:length(list)
        files = getRecurFiles(fullfile(path,list{i}));
        tmpNum = length(files);
        if ~(num == 0 || num >= tmpNum)
            or = randperm(tmpNum);
            or = or(1:num);
            files = files(or);
        end
        re = cellfun(@(x) copyfile(x,saveFold,'f'),files,'UniformOutput',false);
        totalNum = totalNum + length(files);
    end
end
        