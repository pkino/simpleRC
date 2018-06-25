function  [step_half, N, l_num, x_kl, x_kt, ul, ut, l_start] = Res(a, b, c1, gamma)
%% �����ݒ�
% data*step_all�̍s��̃f�[�^�����
data = 1; % 1�X�e�b�v������̓��̓f�[�^��
step_half = 1500; % �����l��3200 �_�����M���͎���1500
step_all = 2*step_half; % �f�[�^��=�X�e�b�v��
theta = 0.01; % [s] 0.2 0.01

tau = 80; %[s] 400*theta
N = tau/theta; % delay��step��
l_num = 400;
% lin = 1;
% eta = 0.5; % 1.8 2 1.3
% c1 =-0.1; %0=���`���f���A-0.1=����`���f��
% gamma =0.5;

%�f�[�^�̒���
step_half =step_half*N;
step_all = step_all*N;




%% �ڕW�f�[�^�̐���
data_length = step_half/N+200; % �������߂ɏ���

% �i�[�ϐ��E�����l
ul = 0.5*rand(data,data_length); % ���̓f�[�^���w�K�ƃe�X�g�ō��ς���
ut = 0.5*rand(data,data_length);

% MG = load('MackeyGlass_t17.txt');
% ul = MG(1:data_length)';
% ut = MG(data_length+1:data_length*2)';


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
    dxl = dif(Xl(:,step-1),X_tau, a, b, c1, gamma, Jl(M_step_l,u_step_l));
    Xl(:,step) = Xl(:,step-1) + dxl*theta;
    
    M_step_t = M_step_t +1;
    dxt = dif(Xt(:,step-1),X_tau2, a, b, c1, gamma, Jt(M_step_t,u_step_t));
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
    dxl = dif(Xl(:,step-1), X_tau, a, b, c1, gamma, Jl(M_step_l,u_step_l));
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
    dxt = dif(Xt(:,step-1), X_tau2, a, b, c1, gamma, Jt(M_step_t,u_step_t));
    Xt(:,step) = Xt(:,step-1) + dxt*theta;
end

%% �w�K�f�[�^����d�݂����߂� memoryFunction
l_interval = N;
l_start = 100 + 50; % X(X0)�����肵���Ƃ��납��w�K�X�^�[�g
x_kl = zeros(l_num, data_length);
x_kt = zeros(l_num, data_length);
for k_step = 1:data_length-1
    x_kl(:,k_step) = Xl(:,X_index_l(k_step,1):l_interval/l_num:X_index_l(k_step,1)+l_interval-1);
    x_kt(:,k_step) = Xt(:,X_index_t(k_step,1):l_interval/l_num:X_index_t(k_step,1)+l_interval-1);
end

%% �e�X�g
% �e�X�g�܂ōs���ꍇ�͂��̃R�����g�A�E�g���O��
% taskDelay = 50;
% RC_MF_pinv(taskDelay, step_half, N, l_num,x_kl, x_kt, ul, ut, l_start)

end

%% ���f����`
function dx = dif(X, X_tau, a, b, c1, gamma, J)
dx = -a*X + b*X_tau + c1*X^3 + gamma*J;
end
