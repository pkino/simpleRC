function  [NRMSE_pinv, l_start, step_half, N,  x_kl, x_kt, ul, ut, data, l_interval] = memoryFunction(lin, eta, c1, gamma)
% ����`���Ԓx��ɂ��RC

%% �����ݒ�
% data*step_all�̍s��̃f�[�^�����
data = 1; % 1�X�e�b�v������̓��̓f�[�^��
step_half = 3200; % �����l��3200
step_all = 2*step_half; % �f�[�^��=�X�e�b�v��
theta = 0.01; % [s] 0.2 0.01

tau = 80; %[s] 400*theta
N = tau/theta; % delay��step��
l_num = 400;
% lin = 1;
% eta = 0.5; % 1.8 2 1.3
% c1 =-0.1; %0=���`���f���A-0.1=����`���f��
% gamma =0.5;
taskDelay = 30;

%�f�[�^�̒���
step_half =step_half*N;
step_all = step_all*N;




%% �ڕW�f�[�^�̐���
data_length = step_half/N+200; % �������߂ɏ���
no_inf=1;

%�i�[�ϐ��E�����l
Yt_l = zeros(data,data_length);
Yt_t = zeros(data,data_length);
while no_inf>0
%     ul = 0.5*rand(data,data_length); % ���̓f�[�^���w�K�ƃe�X�g�ō��ς���
%     ut = 0.5*rand(data,data_length);
%     ul = [ones(1,100),zeros(1,data_length-100)];
    ul = normrnd(0,1,[data,data_length]); % ���̓f�[�^���w�K�ƃe�X�g�ō��ς���
    ut = normrnd(0,1,[data,data_length]);
    
    %     save('ul', 'ul');
    %     save('ut', 'ut');
    %     load('ul.mat');
    %     load('ut.mat');
    
        for y_step=taskDelay+1:data_length
            Yt_l(:,y_step) = ul(:,y_step-taskDelay);
            Yt_t(:,y_step) = ut(:,y_step-taskDelay);
        end
    
    no_inf=sum(sum(isnan(Yt_l)))+sum(sum(isinf(Yt_l)))+sum(sum(isnan(Yt_t)))+sum(sum(isinf(Yt_t)));
end


%% �����̎Z�o
X_step = step_all*2; %���������ŏ��̒�����
% �����Œ�̏ꍇ
i_period = N;
index=step_all/N;
step = (1:step_all/N+1)';
p_start = (step-1)*i_period+1;
p_interval(:,:) = p_start(2:index,:) - p_start(1:index-1,:);


%% Reservoir�ւ̃f�[�^�̑}��
p_begin = 1; % 15
W = 1; % ���͂̔g�̐� p_interval�ł̔g���̍��v��400�𒴂���悤�ɂƂ�
p_max = max(p_interval(p_begin:end,1));
% load('preM.mat');
preM = -0.1+0.2*round(rand(data,p_max*W*1)); % Mask
% save('preM','preM');

% ���߂̓��͂��쐬
Jl = zeros(length(preM),data_length, data); %�s���}�X�N�C�񂪓���u��2�����z��
Jt = zeros(length(preM),data_length, data);
for step = 1:data_length
    Jl(:,step) = ul(:,step).*preM;
    Jt(:,step) = ut(:,step).*preM;
end

% ���U�[�o�̃f�[�^�𖈃X�e�b�v�Ƃ��āC�����̎n�_�����o���Ȃ���MG�̌v�Z
Xl = zeros(1,X_step/2);
Xt = zeros(1,X_step/2);
X_index_l = ones(data_length,2,data); % ���͂����������L�^
X_index_t = ones(data_length,2,data);

X_tau = 0; % Xl(:,1)
X_tau2 =0; %Xt(:,1)
u_step_l = 1;
u_step_t = 1;
M_step_l = 1;
M_step_t = 1;
for step = 2:N
    M_step_l = M_step_l +1;
    dxl = dif(Xl(:,step-1),X_tau, lin, eta, c1, gamma, Jl(M_step_l,u_step_l));
    Xl(:,step) = Xl(:,step-1) + dxl*theta;
    
    M_step_t = M_step_t +1;
    dxt = dif(Xt(:,step-1),X_tau2, lin, eta, c1, gamma, Jt(M_step_t,u_step_t));
    Xt(:,step) = Xt(:,step-1) + dxt*theta;
end

while u_step_l < data_length
    if step >= p_start(u_step_l+1,1)-1
        X_index_l(u_step_l,2) = M_step_l;
        X_index_l(u_step_l+1, 1) = X_index_l(u_step_l, 1)+M_step_l;
        M_step_l = 0;
        u_step_l =u_step_l+1;
    end
    step = step+1;
    M_step_l = M_step_l +1;
    X_tau = Xl(:,step-N);
    dxl = dif(Xl(:,step-1), X_tau, lin, eta, c1, gamma, Jl(M_step_l,u_step_l));
    Xl(:,step) = Xl(:,step-1) + dxl*theta;
end

step = N;
while u_step_t < data_length
    if step >= p_start(u_step_t+1,1)-1
        X_index_t(u_step_t,2) = M_step_t;
        X_index_t(u_step_t+1, 1) = X_index_t(u_step_t, 1)+M_step_t;
        M_step_t = 0;
        u_step_t =u_step_t+1;
    end
    step = step+1;
    M_step_t = M_step_t +1;
    X_tau2 = Xt(:,step-N);
    dxt = dif(Xt(:,step-1), X_tau2, lin, eta, c1, gamma, Jt(M_step_t,u_step_t));
    Xt(:,step) = Xt(:,step-1) + dxt*theta;
end

%% �w�K�f�[�^����d�݂����߂� memoryFunction
l_interval = N;
l_start = 100 + 50; % X(X0)�����肵���Ƃ��납��w�K�X�^�[�g
t_start = l_start; % �e�X�g�X�^�[�g
x_kl = zeros(l_num, data_length);
x_kt = zeros(l_num, data_length);
for k_step = 1:data_length-1
    x_kl(:,k_step) = Xl(:,X_index_l(k_step,1):l_interval/l_num:X_index_l(k_step,1)+l_interval-1);
    x_kt(:,k_step) = Xt(:,X_index_t(k_step,1):l_interval/l_num:X_index_t(k_step,1)+l_interval-1);
end


C = zeros(l_num,l_num);
p = zeros(l_num,data);
for step = l_start:l_start+step_half/N-1
    C = C + x_kl(:,step)*x_kl(:,step)';
    p = p + Yt_l(:,step)*x_kl(:,step);
end
C = C/(step_half/N);
p = p/(step_half/N);

Wout = zeros(data,l_num);
Wout(1,:) = pinv(C)*p;
%
% % Y_pinv_C = zeros(step_half/N,3);
% % Y_pinv_C(:,1:2) = [(Yt_l(:,l_start:l_start+step_half/N-1))' (Wout(1,:)*x_kl(:,l_start:l_start+step_half/N-1))'];
% % Y_pinv_C(:,3) =  Y_pinv_C(:,1).*Y_pinv_C(:,2);
% % mf_C = mean(Y_pinv_C(:,3));
%
Y_pinv_C = zeros(step_half/N,3);
Y_pinv_C(:,1:2) = [(Yt_l(:,l_start:l_start+step_half/N-1))' (Wout(1,:)*x_kl(:,l_start:l_start+step_half/N-1))'];
Y_pinv_C(:,3) =  (Y_pinv_C(1:end,1)-Y_pinv_C(1:end,2)).^2;
sigma_ytC=std(Y_pinv_C(1:end,1));
NRMSE_pinv_C =((1/(step_half/N))*sum(Y_pinv_C(1:end,3))/(sigma_ytC^2))^0.5;
%
t_begin = t_start;
t_fin = t_start+step_half/N-1;

Y_pinv = zeros(step_half/N,3);
Y_pinv(:,1:2) = [(Yt_t(:, t_begin:t_fin))' (Wout(1,:)*x_kt(:, t_begin:t_fin))'];
% Y_pinv(:,3) =  Y_pinv(:,1).*Y_pinv(:,2);
% mf = mean(Y_pinv(:,3));
Y_pinv(:,3) =  (Y_pinv(1:end,1)-Y_pinv(1:end,2)).^2;
sigma_yt=std(Y_pinv(1:end,1));
NRMSE_pinv =((1/ (step_half/N))*sum(Y_pinv(1:end,3))/(sigma_yt^2))^0.5;
%
% %% �w�K�f�[�^����d�݂����߂� NRMSE
% %�w�K�ɕK�v�Ȑ������܂Ƃ߂�
% % l_start = 50; % X(X0)�����肵���Ƃ��납��w�K�X�^�[�g
% % t_start = l_start; % �e�X�g�X�^�[�g
% % l_interval = N;
% % x_kl = zeros(l_interval, data_length);
% % x_kt = zeros(l_interval, data_length);
% % for k_step = 1:data_length-1
% %     x_kl(:,k_step) = Xl(:,X_index_l(k_step,1):X_index_l(k_step,1)+l_interval-1);
% %     x_kt(:,k_step) = Xt(:,X_index_t(k_step,1):X_index_t(k_step,1)+l_interval-1);
% % end
%
% % %% �^���t�s��e�X�g
% % % �^���t�s��
% % Wout = zeros(data,l_interval);
% % Wout(1,:) =Yt_l(1,l_start:l_start+step_half/N-1)*pinv(x_kl(:,l_start:l_start+step_half/N-1));
% %
% % t_begin = t_start;
% % t_fin = t_start+step_half/N-1;
% %
% % Y_pinv_C = zeros(step_half/N,3);
% % Y_pinv_C(:,1:2) = [(Yt_l(:,l_start:l_start+step_half/N-1))' (Wout(1,:)*x_kl(:,l_start:l_start+step_half/N-1))'];
% % Y_pinv_C(:,3) =  (Y_pinv_C(1:end,1)-Y_pinv_C(1:end,2)).^2;
% % sigma_ytC=std(Y_pinv_C(1:end,1));
% % NRMSE_pinv_C =((1/(step_half/N))*sum(Y_pinv_C(1:end,3))/(sigma_ytC^2))^0.5;
% %
% % Y_pinv = zeros(step_half/N,3);
% % Y_pinv(:,1:2) = [(Yt_t(:, t_begin:t_fin))' (Wout(1,:)*x_kt(:, t_begin:t_fin))'];
% % Y_pinv(:,3) =  (Y_pinv(1:end,1)-Y_pinv(1:end,2)).^2;
% % sigma_yt=std(Y_pinv(1:end,1));
% % NRMSE_pinv =((1/ (step_half/N))*sum(Y_pinv(1:end,3))/(sigma_yt^2))^0.5;
% %
% %
% % %% ���ْl�����e�X�g
% % % X_tmp=x_kl(:,l_start:l_start + step_half/N-1);
% % % [U,S,V] = svd(X_tmp);
% % % [A,B]=size(S);
% % % for i=1:A
% % %     for j=1:B
% % %         if abs(S(i,j)) >1*10^-17 % ������ς����炢������
% % %             S(i,j)=1/S(i,j);
% % %             %S(i,j)=S(i,j)/( S(i,j)^2+reg^2); %Tikhonov Regularization
% % %         else
% % %             S(i,j)=0;
% % %         end
% % %     end
% % % end
% % % Wout2 =Yt_l(1,l_start:l_start+step_half/N-1)*(V*S'*U');
% % % % load('Wout2.mat');
% % %
% % % Y_SVD_C = zeros(step_half/N,3);
% % % Y_SVD_C(:,1:2) = [(Yt_l(:,t_start:t_start+step_half/N-1))' (Wout2(1,:)*x_kl(:,t_start:t_start+step_half/N-1))'];
% % % Y_SVD_C(:,3) =  (Y_SVD_C(1:end,1)-Y_SVD_C(1:end,2)).^2;
% % % sigma_ytC=std(Y_SVD_C(1:end,1));
% % % NRMSE_SVD_C =((1/(step_half/N))*sum(Y_SVD_C(1:end,3))/(sigma_ytC^2))^0.5;
% % %
% % % Y_SVD = zeros(step_half/N,3);
% % % Y_SVD(:,1:2) = [(Yt_t(:, t_begin:t_fin))' (Wout2(1,:)*x_kt(:, t_begin:t_fin))'];
% % % Y_SVD(:,3) =  (Y_SVD(1:end,1)-Y_SVD(1:end,2)).^2;
% % % sigma_yt2=std(Y_SVD(1:end,1));
% % % NRMSE_SVD =((1/ (step_half/N))*sum(Y_SVD(1:end,3))/(sigma_yt2^2))^0.5;
% % % Xl;
end

%% ���f����`
function dx = dif(X, X_tau, lin, eta, c1, gamma, J)
dx = -lin*X + eta*X_tau + c1*X^3 + gamma*J;
end
