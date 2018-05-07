%% ��ÿ�����ļ�����ѡ��һ������������֯
%   path:       ��ʼ·��
%   num:        ÿ���ļ��в�������,  numΪ0ʱȫ������
%   totalNum:   �����ܹ���������Ŀ
%   savePath:   ���������浽�µ�·����
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
        