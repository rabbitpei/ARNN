clc;
clear;
close all;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%    data preparation   %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%    Input any time-series data   %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%    Dataset folder: Data, including gene expression, HK hospital admission,  %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   tempressure, SLP, Solar, stock, traffic, typhoon, wind speed    %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%    example:  Lorenz  system    %%%%%%%%%%%%%%%%%%%

Y=load('Lorenz.txt');% coupled lorenz system
%load Y;
noisestrength=0;
X=Y+noisestrength*rand(size(Y));% noise could be added

ii=0;
ii_set=[224];   %sample init, can be changed
for ii=ii_set
    ii          % init
    trainlength=50;         %  length of training data (observed data), m
    xx=X(2000+ii+50-trainlength:size(X,1),:)';       % after transient dynamics
    noisestrength=0;   % strength of noise
    xx_noise=xx+noisestrength*rand(size(xx));
    
    traindata=xx_noise(:,1:trainlength);
    
    k=60;  % embedding dimension, which could be determined using FNN or set empirically
    
    predict_len=19;     % L
    
    jd=1; % the index of target variable
    
    D=size(xx_noise,1);     % number of variables in the system.
    real_y=xx(jd,:);
    real_y_noise=real_y+noisestrength*rand(size(real_y));
    traindata_y=real_y_noise(1:trainlength);
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%    ARNN start     %%%%%%%%%%%%%%%%%%%%%%%%%%
    for i=1:trainlength
        traindata_x_NN(:,i)=NN_F(traindata(:,i));
    end
    
    w_flag=zeros(size(traindata_x_NN,1));
    A=zeros(predict_len,size(traindata_x_NN,1));   
    B=zeros(size(traindata_x_NN,1),predict_len);  
    for iter=1:1000         % cal coeffcient B
        random_idx=sort([jd,randsample(setdiff(1:size(traindata_x_NN,1),jd),k-1)]);
        traindata_x=traindata_x_NN(random_idx,1:trainlength);       
        
        clear super_bb super_AA;
        for i=1:size(traindata_x,1)
            %  Ax=b,  1: x=pinv(A)*b,    2: x=A\b,    3: x=lsqnonneg(A,b)
            b=traindata_x(i,1:trainlength-predict_len+1)';     
            clear B_w;
            for j=1:trainlength-predict_len+1
                B_w(j,:)=traindata_y(j:j+predict_len-1);
            end
            B_para=(B_w\b)';
            B(random_idx(i),:)=(B(random_idx(i),:)+B_para+B_para*(1-w_flag(random_idx(i))))/2;
            w_flag(random_idx(i))=1;
        end
       
    end
   
    clear super_bb super_AA;
    for i=1:size(traindata_x_NN,1)
        kt=0;
        clear bb;
        AA=zeros(predict_len-1,predict_len-1);
        for j=(trainlength-(predict_len-1))+1:trainlength
            kt=kt+1;
            bb(kt)=traindata_x_NN(i,j);
            %col_unknown_y_num=j-(trainlength-(predict_len-1));
            col_known_y_num=trainlength-j+1;
            for r=1:col_known_y_num
                bb(kt)=bb(kt)-B(i,r)*traindata_y(trainlength-col_known_y_num+r);
            end
            AA(kt,1:predict_len-col_known_y_num)=B(i,col_known_y_num+1:predict_len);
        end
        
        super_bb((predict_len-1)*(i-1)+1:(predict_len-1)*(i-1)+predict_len-1)=bb;
        super_AA((predict_len-1)*(i-1)+1:(predict_len-1)*(i-1)+predict_len-1,:)=AA;
    end

    pred_y_tmp=(super_AA\super_bb')';
   
    tmp_y=[real_y(1:trainlength), pred_y_tmp];
    for j=1:predict_len
        Ym(j,:)=tmp_y(j:j+trainlength-1);
    end
    BX=[B,traindata_x_NN];
    IY=[eye(predict_len),Ym];
    A=IY*pinv(BX);
    clear  union_predict_y_NN;
    for j1=1:predict_len-1
        tmp_y=zeros(predict_len-j1,1);
        kt=0;
        for j2=j1:predict_len-1
            kt=kt+1;
            row=j2+1;
            col=trainlength-j2+j1;
            tmp_y(kt)=A(row,:)*traindata_x_NN(:,col);
        end     
        union_predict_y_ARNN(j1)=mean(tmp_y);
    end
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%      result  %%%%%%%%%%%%%%%%%%%%%%
    
    myreal=real_y(trainlength+1:trainlength+predict_len-1);
    for u=1:predict_len-1
         error(u)=(union_predict_y_ARNN(u)-myreal(u))^2;
    end
    RMSE=sqrt(sum(error))/(predict_len-1);
    
    union_predict_y_ARNN

end


