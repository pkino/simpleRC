data = NRMSE;
Maxeig = logspace(eigMin, eigMax, eigNum);
Eiggap =  logspace(gapMax, gapMin, gapNum);
searchNum = 5;

cIndex = 3;
[bestPerform, bestIndex] = min(data(:,searchNum+1));
bestC = data(bestIndex, cIndex);

horizontal = eigNum;
vertical = gapNum;
other = gammaNum*cNum;

map = zeros(vertical, horizontal,2);
for step = 1:vertical
    for step2 = 1:horizontal
        plotter = data((step-1)*vertical*other+(step2-1)*other+1:(step-1)*vertical*other+(step2-1)*other+other, 1:searchNum+2);
        
        % c�Œ�
        plotter = plotter(plotter(:,cIndex) == bestC,:);
        
        
        [map(step,step2,1), miniIndex]  = min(plotter(:,end-1));
        map(step,step2,2) = plotter(miniIndex,end);
        
        % �e�l���m�肽���Ƃ��̓R�����g�A�E�g���O��
%         miniIndex
%         c=plotter(miniIndex,3)
    end
end

%% �}�b�v�`��
figure;
set(gca,'XScale','log')
X = repelem(Maxeig',vertical);
Y = repmat(Eiggap',horizontal,1);
Z = reshape(map(:,:,1),numel(map(:,:,1)),1);
c = Z;
imagesc([eigMin eigMax], [gapMax gapMin], map(:,:,1));
caxis([min(min(map(:,:,1))), 1]);
colorbar;

