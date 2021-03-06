%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%程序初始化操作%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
close all;

iBeacon_IMU_location = ParticleFilter();
GPS_IMU_location = GPS_IMU_PF();
Adopted_location = zeros(2,361);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%全局变量定义%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outdoor_sensor_data=361;
indoor_sensor_data=0;
sensor_data=outdoor_sensor_data+indoor_sensor_data;
d=0.1;%标准差
Theta=CreateGauss(0,d,1,sensor_data);%GPS航迹和DR航迹的夹角
ZOUT=zeros(4,outdoor_sensor_data);
ZIN=zeros(4,indoor_sensor_data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%读取传感器数据%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fgps=fopen('sensor_data_041518.txt','r');%%%打开文本

for n=1:sensor_data
    gpsline=fgetl(fgps);%%%读取文本指针对应的行
    if ~ischar(gpsline) break;%%%判断是否结束
    end;
    %%%%读取室内数据
   time=sscanf(gpsline,'[Info] 2016-04-15%s(ViewController.m:%d)-[ViewController outputAccelertion:]:lat:%f;lon:%f;heading:%f;distance:%f;beacon_lat:%f;beacon_lon:%f');
   data=sscanf(gpsline,'[Info] 2016-04-15 %*s (ViewController.m:%*d)-[ViewController outputAccelertion:]:lat:%f;lon:%f;heading:%f;distance:%f;beacon_lat:%f;beacon_lon:%f');
   if(isempty(data))
       break;
   end
        result=lonLat2Mercator(data(6,1),data(5,1));
        gx(n)=result.X;%GPS经过坐标变换后的东向坐标，换算成米数
        gy(n)=result.Y;%GPS经过坐标变换后的北向坐标，换算成米数
        Phi(n)=(data(3,1)+90)*pi/180;%航向角
        dd(n)=data(4,1);%某一周期的位移
        ZIN(:,n)=[gx(n),gy(n),Phi(n),dd(n)];
        if ZIN(1,n) == 0
            Adopted_location(1,n) = GPS_IMU_location(1,n);
            Adopted_location(2,n) = GPS_IMU_location(2,n);
        else
            Adopted_location(1,n) = iBeacon_IMU_location(1,n);
            Adopted_location(2,n) = iBeacon_IMU_location(2,n);
        end
end
fclose(fgps);%%%%%关闭文件指针

cordinatex=round(ZIN(1,5));
cordinatey=round(ZIN(2,5));

[groundtruthx,groundtruthy]=Groud_Truth();
groundtruth = [groundtruthx,groundtruthy]';
iBeacon_IMU_location_line=iBeacon_IMU_location(:,2:361)-groundtruth(:,2:361);
iBeacon_IMU_location_error=sqrt(iBeacon_IMU_location_line(1,:).^2+iBeacon_IMU_location_line(2,:).^2);
GPS_IMU_location_line=GPS_IMU_location(:,2:361)-groundtruth(:,2:361);
GPS_IMU_location_error=sqrt(GPS_IMU_location_line(1,:).^2+GPS_IMU_location_line(2,:).^2);
Adopted_location_line=Adopted_location(:,2:361)-groundtruth(:,2:361);
Adopted_location_error=sqrt(Adopted_location_line(1,:).^2+Adopted_location_line(2,:).^2);

x_Adopted_location = zeros(1,11);
c_Adopted_location = zeros(1,11);
[b_Adopted_location, x_Adopted_location(1,2:11)]=hist(Adopted_location_error,10);
num=numel(Adopted_location_error);
%figure;plot(x_Adopted_location(1,2:11),b_Adopted_location/num);   %概率密度
c_Adopted_location(1,2:11)=cumsum(b_Adopted_location/num);        %累积分布

x_iBeacon_IMU_location = zeros(1,11);
c_iBeacon_IMU_location = zeros(1,11);
[b_iBeacon_IMU_location, x_iBeacon_IMU_location(1,2:11)]=hist(iBeacon_IMU_location_error,10);
num=numel(iBeacon_IMU_location_error);
%figure;plot(x_Adopted_location(1,2:11),b_Adopted_location/num);   %概率密度
c_iBeacon_IMU_location(1,2:11)=cumsum(b_iBeacon_IMU_location/num);        %累积分布

x_GPS_IMU_location = zeros(1,11);
c_GPS_IMU_location = zeros(1,11);
[b_GPS_IMU_location, x_GPS_IMU_location(1,2:11)]=hist(GPS_IMU_location_error,10);
num=numel(GPS_IMU_location_error);
%figure;plot(x_Adopted_location(1,2:11),b_Adopted_location/num);   %概率密度
c_GPS_IMU_location(1,2:11)=cumsum(b_GPS_IMU_location/num);        %累积分布

figure;
plot(x_Adopted_location,c_Adopted_location,'r');hold on;
plot(x_iBeacon_IMU_location,c_iBeacon_IMU_location,'b');hold on;
plot(x_GPS_IMU_location,c_GPS_IMU_location,'g');hold off;
legend('iBeacon/IMU/GPS定位', 'iBeacon/IMU定位','GPS/IMU定位');
xlabel('定位误差/m', 'FontSize', 10); ylabel('累积概率分布/%', 'FontSize', 10);

figure(3);
set(gca,'FontSize',12);
plot(groundtruthx,groundtruthy,'r');hold on;
%plot( ZIN(1,:), ZIN(2,:), 'o');hold on;
plot(Adopted_location(1,:), Adopted_location(2,:), 'g');hold off;
axis([cordinatex-100 cordinatex+200 cordinatey-200 cordinatey+100]),grid on;
legend('真实轨迹', '粒子滤波轨迹');
xlabel('x', 'FontSize', 20); ylabel('y', 'FontSize', 20);
axis equal;
