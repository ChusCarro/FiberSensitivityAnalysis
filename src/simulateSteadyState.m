function simulateSteadyState(pathToSave, param, values,nNodes, CL, nCLs, Cai_ind, dt,project)

initialPath=pwd();
sim_stat = load([pathToSave '/status.mat']);

if(isempty(dir([pathToSave '/SS' num2str(CL)])))
  mkdir([pathToSave '/SS' num2str(CL)])
  copyfile([pathToSave '/base'],[pathToSave '/SS' num2str(CL) '/base'])
  createFileStimulus([pathToSave '/SS' num2str(CL) '/base'],[0:CL:(nCLs-1)*CL],1,sim_stat.IStim);
end

pathSS  = [pathToSave '/SS' num2str(CL)];


if(isempty(dir([pathSS '/control'])))

    copyfile([pathSS '/base'],[pathSS '/control'])
    createMainFile([pathSS '/control'],'main_file_SS_initial', project, ...
                 ['Calculation of Steady State for CL=' num2str(CL) 'ms in control conditions'] ,...
                 CL*(nCLs-1),dt,[],['SS_restart'],CL*(nCLs-1),0,false)
    createMainFile([pathSS '/control'],'main_file_SS_last', project, ...
                 ['Calculation of last Steady State Cycle for CL=' num2str(CL) 'ms in control conditions'] ,...
                 CL,dt,['SS_restart_' num2str(round(CL*(nCLs-1)/dt)) '_prc_'],[],0,0,true)

    cd([pathSS '/control']);
    ! ./runelv 1 data/main_file_SS_initial.dat post/SS_initial_
    ! ./runelv 1 data/main_file_SS_last.dat post/SS_
    ! rm post/SS_initial_*
end

a=load([pathSS '/control/post/SS_prc0_00000101.var']);
dt_results = a(2,1)-a(1,1);
V=zeros(length(a(:,2)),5);
Cai=V;

V(:,1)=a(:,2);
Cai(:,1)=a(:,Cai_ind+3);
a=load([pathSS '/control/post/SS_prc0_00000126.var']);
V(:,2)=a(:,2);
Cai(:,2)=a(:,Cai_ind+3);
a=load([pathSS '/control/post/SS_prc0_00000151.var']);
V(:,3)=a(:,2);
Cai(:,3)=a(:,Cai_ind+3);
a=load([pathSS '/control/post/SS_prc0_00000176.var']);
V(:,4)=a(:,2);
Cai(:,4)=a(:,Cai_ind+3);
a=load([pathSS '/control/post/SS_prc0_00000201.var']);
V(:,5)=a(:,2);
Cai(:,5)=a(:,Cai_ind+3);

for i=1:5
    [APD90{i},APD_time{i}]=calculateAPD(V(:,i),dt_results,0.9);
    Trian{i} = APD90{i}-calculateAPD(V(:,i),dt_results,0.5);
    Diastolic{i} = calculateDiastolic(Cai(:,i),dt_results);
    Systolic{i} = calculateSystolic(Cai(:,i),dt_results);
end

CV_v = 1000./(APD_time{5}-APD_time{1});
sim_stat.(['SS' num2str(CL)]).control.APD90_v = APD90;
sim_stat.(['SS' num2str(CL)]).control.APD90 = mean(cell2mat(APD90'));
sim_stat.(['SS' num2str(CL)]).control.APD_time = APD_time;
sim_stat.(['SS' num2str(CL)]).control.CV_v = CV_v;
sim_stat.(['SS' num2str(CL)]).control.CV = mean(CV_v);
sim_stat.(['SS' num2str(CL)]).control.Trian_v = Trian;
sim_stat.(['SS' num2str(CL)]).control.Trian = mean(cell2mat(Trian'));
sim_stat.(['SS' num2str(CL)]).control.Diastolic_v = Diastolic;
sim_stat.(['SS' num2str(CL)]).control.Diastolic = mean(cell2mat(Diastolic'));
sim_stat.(['SS' num2str(CL)]).control.Systolic_v = Systolic;
sim_stat.(['SS' num2str(CL)]).control.Systolic = mean(cell2mat(Systolic'));
save([pathToSave '/status.mat'],'-struct','sim_stat');

for i=1:length(param)

  pathParam = [pathSS '/P_' num2str(param(i))];

  if(isempty(dir(pathParam)))
    mkdir(pathParam)
    copyfile([pathSS '/base'],[pathParam '/base'])
  end

  parfor j=1:length(values)
    pathValue = [pathParam '/V_' num2str(values(j))];

    if(isempty(dir(pathValue)))
      copyfile([pathParam '/base'],pathValue)
      createMainFile(pathValue,'main_file_SS_initial', project, ...
                 ['Calculation of Steady State for CL=' num2str(CL) 'ms and P_' num2str(i) '=' num2str(values(j))] ,...
                 CL*(nCLs-1),dt,[],['SS_restart'],CL*(nCLs-1),1,false)
       createMainFile(pathValue,'main_file_SS_last', project, ...
                 ['Calculation of last Steady State Cycle for CL=' num2str(CL) 'ms and P_' num2str(i) '=' num2str(values(j))] ,...
                 CL,dt,['SS_restart_' num2str(round(CL*(nCLs-1)/dt)) '_prc_'],[],0,1,true)

      createFileParamNode(pathValue,values(j),param(i),nNodes);
      cd(pathValue);
      ! ./runelv 1 data/main_file_SS_initial.dat post/SS_initial_
      ! ./runelv 1 data/main_file_SS_last.dat post/SS_
      ! rm post/SS_initial_*
    end 
  end
end

for i=1:length(param)

  pathParam = [pathSS '/P_' num2str(param(i))]

  for j=1:length(values)
    pathValue = [pathParam '/V_' num2str(values(j))] 
    a=load([pathValue '/post/SS_prc0_00000101.var']);
    dt_results = a(2,1)-a(1,1);
    V=zeros(length(a(:,2)),5);
    Cai=zeros(length(a(:,2)),5);
    V(:,1)=a(:,2);
    Cai(:,1)=a(:,Cai_ind+3);
    a=load([pathValue '/post/SS_prc0_00000126.var']);
    V(:,2)=a(:,2);
    Cai(:,2)=a(:,Cai_ind+3);
    a=load([pathValue '/post/SS_prc0_00000151.var']);
    V(:,3)=a(:,2);
    Cai(:,3)=a(:,Cai_ind+3);
    a=load([pathValue '/post/SS_prc0_00000176.var']);
    V(:,4)=a(:,2);
    Cai(:,4)=a(:,Cai_ind+3);
    a=load([pathValue '/post/SS_prc0_00000201.var']);
    V(:,5)=a(:,2);
    Cai(:,5)=a(:,Cai_ind+3);
    APD90_j = cell(1,5);
    APD_time_j = cell(1,5);
    Diastolic = cell(1,5);
    Systolic = cell(1,5);
    for k=1:5
        [APD90{k},APD_time{k}]= calculateAPD(V(:,k),dt_results,0.9);
        Trian{k}= APD90{k}-calculateAPD(V(:,k),dt_results,0.5);
        Diastolic{k} = calculateDiastolic(Cai(:,k),dt_results);
        Systolic{k} = calculateSystolic(Cai(:,k),dt_results);
    end
    CV_v = 1000./(APD_time{5}-APD_time{1});
    sim_stat.(['SS' num2str(CL)]).variations.APD90_v{i,j} = APD90;
    sim_stat.(['SS' num2str(CL)]).variations.APD90{i,j} = mean(cell2mat(APD90'));
    sim_stat.(['SS' num2str(CL)]).variations.APD_time{i,j} = APD_time;
    sim_stat.(['SS' num2str(CL)]).variations.CV_v{i,j} = CV_v;
    sim_stat.(['SS' num2str(CL)]).variations.CV{i,j} = mean(CV_v');
    sim_stat.(['SS' num2str(CL)]).variations.Trian_v{i,j} = Trian;
    sim_stat.(['SS' num2str(CL)]).variations.Trian{i,j} = mean(cell2mat(Trian'));
    sim_stat.(['SS' num2str(CL)]).variations.Diastolic_v{i,j} = Diastolic;
    sim_stat.(['SS' num2str(CL)]).variations.Diastolic{i,j} = mean(cell2mat(Diastolic'));
    sim_stat.(['SS' num2str(CL)]).variations.Systolic_v{i,j} = Systolic;
    sim_stat.(['SS' num2str(CL)]).variations.Systolic{i,j} = mean(cell2mat(Systolic'));
  end
end


save([pathToSave '/status.mat'],'-struct','sim_stat');

cd(initialPath)
