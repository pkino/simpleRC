function  [x_kl, x_kt] = ...
    timeDelayReservoir(seed_no, ul, ut, theta, learnDimension, ...
    biasCheck, inputCheck, a, b, c, p, gamma)
% step_half, N, learnDimension, x_kl, x_kt, ul, ut, l_start

%% �����ݒ�
% data*step_all�̍s��̃f�[�^�����
data = 1; % 1�X�e�b�v������̓��̓f�[�^��
% theta = 0.01; % [s] 0.2 0.01

tau = 80; %[s] 400*theta
N = tau/theta; % delay��step��
% lin = 1;
% eta = 0.5; % 1.8 2 1.3
% c1 =-0.1; %0=���`���f���A-0.1=����`���f��
% gamma =0.5;

%�f�[�^�̒���
dataLen = length(ul); % �������߂ɏ���


%% �����̎Z�o
% �����Œ�̏ꍇ
i_period = N;
index=dataLen;
step = (1:dataLen+1)';
p_start = (step-1)*i_period+1;
p_interval(:,:) = p_start(2:index,:) - p_start(1:index-1,:);


%% Reservoir�ւ̃f�[�^�̑}��
p_begin = 1; % 15
p_max = max(p_interval(p_begin:end,1));
seed_mask = seed_no;
rng(seed_mask,'twister');
maskCheck = 1;
while maskCheck > 0
    preM = -0.1+0.2*round(rand(data,p_max)); % Mask
    if abs(sum(preM)) < 1e-5
        maskCheck = 0;
    end
end

% ���߂̓��͂��쐬
Jl = zeros(length(preM),dataLen, data); %�s���}�X�N�C�񂪓���u��2�����z��
Jt = zeros(length(preM),dataLen, data);
for step = 1:dataLen
    Jl(:,step) = ul(:,step).*preM;
    Jt(:,step) = ut(:,step).*preM;
end

% ���U�[�o�̃f�[�^�𖈃X�e�b�v�Ƃ��āC�����̎n�_�����o���Ȃ���MG�̌v�Z
Xl = zeros(1,dataLen*N);
Xt = zeros(1,dataLen*N);
X_index_l = ones(dataLen,2,data); % ���͂����������L�^
X_index_t = ones(dataLen,2,data);

X_tau = 0; % Xl(:,1)
X_tau2 =0; %Xt(:,1)
u_step_l = 1;
u_step_t = 1;
M_step_l = 1;
M_step_t = 1;
for step = 2:N
    M_step_l = M_step_l +1;
    dxl = dif(Xl(:,step-1),X_tau, a, b, c, p, gamma, Jl(M_step_l,u_step_l));
    Xl(:,step) = Xl(:,step-1) + dxl*theta;
    
    M_step_t = M_step_t +1;
    dxt = dif(Xt(:,step-1),X_tau2, a, b, c, p, gamma, Jt(M_step_t,u_step_t));
    Xt(:,step) = Xt(:,step-1) + dxt*theta;
end

while u_step_l < dataLen
    if step >= p_start(u_step_l+1,1)-1
        X_index_l(u_step_l,2) = M_step_l;
        X_index_l(u_step_l+1, 1) = X_index_l(u_step_l, 1)+M_step_l;
        M_step_l = 0;
        u_step_l =u_step_l+1;
    end
    step = step+1;
    M_step_l = M_step_l +1;
    X_tau = Xl(:,step-N);
    dxl = dif(Xl(:,step-1), X_tau,a, b, c, p, gamma, Jl(M_step_l,u_step_l));
    Xl(:,step) = Xl(:,step-1) + dxl*theta;
end

step = N;
while u_step_t < dataLen
    if step >= p_start(u_step_t+1,1)-1
        X_index_t(u_step_t,2) = M_step_t;
        X_index_t(u_step_t+1, 1) = X_index_t(u_step_t, 1)+M_step_t;
        M_step_t = 0;
        u_step_t =u_step_t+1;
    end
    step = step+1;
    M_step_t = M_step_t +1;
    X_tau2 = Xt(:,step-N);
    dxt = dif(Xt(:,step-1), X_tau2, a, b, c, p, gamma, Jt(M_step_t,u_step_t));
    Xt(:,step) = Xt(:,step-1) + dxt*theta;
end

%% �w�K�f�[�^
l_interval = N;

x_kl = zeros(learnDimension, dataLen);
x_kt = zeros(learnDimension, dataLen);
for k_step = 1:dataLen-1
    x_kl(:,k_step) = Xl(:,X_index_l(k_step,1):l_interval/learnDimension:X_index_l(k_step,1)+l_interval-1);
    x_kt(:,k_step) = Xt(:,X_index_t(k_step,1):l_interval/learnDimension:X_index_t(k_step,1)+l_interval-1);
end

if inputCheck == 0
    x_kl = vertcat(zeros(1,dataLen),x_kl);
    x_kt = vertcat(zeros(1,dataLen),x_kt);
else
    x_kl = vertcat(ul,x_kl);
    x_kt = vertcat(ut,x_kt);
end
if biasCheck == 0
    x_kl = vertcat(zeros(1,dataLen),x_kl);
    x_kt = vertcat(zeros(1,dataLen),x_kt);
else
    x_kl = vertcat(ones(1,dataLen),x_kl);
    x_kt = vertcat(ones(1,dataLen),x_kt);
end
end

%% ���f����`
function dx = dif(X, X_tau, a, b, c, p, gamma, J)
dx = -a*X + b*X_tau + c*X^p + gamma*J;
end
