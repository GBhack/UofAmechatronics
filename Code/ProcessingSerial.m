% Janarthanan MARIASEELAN
% Akshay Domun
% 12/15/2015
% University of Arizona
clc
clear all

%% RS232
%vThis is the part which permit us to communicate between two devices : in
% this case we have our PC and the circuit

obj1=serial('COM4');% we declare which port of our pc will be use to communicate with the circuit 
set(obj1,'BaudRate',9600); % we set the transmission rate of bite in bit per seconds
set(obj1,'InputBufferSize',450); % we set the buffer which permit us to have x value if the input value is equal to x 
fopen(obj1) % start the communication
Y=fread(obj1,400,'uint8'); % read the data from the circuit
K=Y'; % we will get a vector line
Z=vec2mat(K,5);% this vector line will be transform in a 170 x 5 matrix
fread(obj1,450,'uint8');
fclose(obj1)% stop the communication


 
%% Error detection
% We'll get 5 vector column the last two column will correspond to a
% control code : if the data are well send , the two last column will
% display respectively 255 in binary and 0
    A(:,1)=Z(:,1);
    B(:,1)=Z(:,2);
    C(:,1)=Z(:,3);
    D(:,1)=Z(:,4);
    E(:,1)=Z(:,5);
    

for i=1:length(D)
if D(i) ~= 65
 disp('----Error in Data transmission----')
 fprintf('Error occured at line %d',i)
end
end
for i=1:length(E)
if E(i)~= 66
 disp('----Error in Data transmission----')
 fprintf('Error occured at line %d',i)
 
end
end


%% Decleration of the time vector 
t = [0:1:169];

%% Declaration of each acceleraton
Accx=convert1;
Accy=convert2;
Accz=convert3;


%% Conversion decimal to Gs
Accx1=-9+(18/255)*Accx;
Accy1=-9+(18/255)*Accy;
Accz1=-9+(18/255)*Accz;

%% Integrators
% We'll integrate two times the acceleration with the function cumtrapz in
% order to get first the velocity and then the position.

% Acceleration integrator
    Vx=cumtrapz(Accx1,t);
    Vy=cumtrapz(Accy1,t);
    Vz=cumtrapz(Accz1,t);

% Velocity Integrator
    Xx=cumtrapz(Vx,t);
    Xy=cumtrapz(Vy,t);
    Xz=cumtrapz(Vz,t);
    
%% Representations of Acceleration , velocity and position in different plots

% Plot of each velocity , position , and aceeleration on each axis ( example : Vx) 
figure (1)

%Plot of the acceleration on x
subplot(3,3,1), plot(t,Accx1,'b')
grid on
xlabel('time in second')
ylabel('m/s²')
title('acceleration on x in fucntion of time')

%Plot of the acceleration on y
subplot(3,3,2), plot(t,Accy1,'r')
grid on
xlabel('time in second')
ylabel('m/s²')
title('acceleration on y in fucntion of time')

%Plot of the acceleration on z
subplot(3,3,3), plot(t,Accz1,'g')
grid on
xlabel('time in second')
ylabel('m/s²')
title('acceleration on z in fucntion of time')

%Plot of the velocity on x
subplot(3,3,4), plot(t,Vx,'b')
grid on
xlabel('time in second')
ylabel('m/s')
title('Velocity on x in fucntion of time')

%Plot of the velocity on y
subplot(3,3,5), plot(t,Vy,'r')
grid on
xlabel('time in second')
ylabel('m/s')
title('Velocity on y in fucntion of time')

%Plot of the velocity on z
subplot(3,3,6), plot(t,Vz,'g')
grid on
xlabel('time in second')
ylabel('m/s')
title('Velocity on z in fucntion of time')

%Plot of the position on x
subplot(3,3,7), plot(t,Xx,'b')
grid on
xlabel('time in second')
ylabel('m')
title('position on x in fucntion of time')

%Plot of the position on y
subplot(3,3,8), plot(t,Xy,'r')
grid on
xlabel('time in second')
ylabel('m')
title('position on y in fucntion of time')

%Plot of the position on z
subplot(3,3,9), plot(t,Xz,'g')
grid on
xlabel('time in second')
ylabel('m')
title('position on z in fucntion of time')


%% Dimensional plot

figure(2)

plot3(Xx,Xy,Xz)
grid on
xlabel('Xx')
ylabel('Xy')
zlabel('Xz')
title('position on the 3 axis in 3d  in fucntion of time')


%% plot of each element per axis ( the first plot will be Accx ,VX , and Xx,the second one is Accy , Vy , Xy )


figure(3)

%plot on the x axis
subplot(3,2,1:2), plot(t,Accx1,'b-',t,Vx,'r',t,Xx,'g')
grid on
xlabel('time in second')
ylabel('m/s², m/s, m')
title('acceleration , velocity and position on the x axis  in fucntion of time')

%plot on the y axis
subplot(3,2,3:4), plot(t,Accy1,'b-',t,Vy,'r',t,Xy,'g')
grid on
xlabel('time in second')
ylabel('m/s², m/s, m')
title('acceleration , velocity and position on the y axis  in fucntion of time')

%plot on the z axis
subplot(3,2,5:6), plot(t,Accz1,'b-',t,Vz,'r',t,Xz,'g')
grid on
xlabel('time in second')
ylabel('m/s², m/s, m')
title('acceleration , velocity and position on the z axis  in fucntion of time')

%% Plot of each element in one figure

figure(4)
plot(t,Accx1,'b')
grid on
xlabel('time in second')
ylabel('m/s²')
title('acceleration on x in fucntion of time')

figure(5)
plot(t,Accy1,'r')
grid on
xlabel('time in second')
ylabel('m/s²')
title('acceleration on y in fucntion of time')

figure(6)
plot(t,Accz1,'g ')
grid on
xlabel('time in second')
ylabel('m/s²')
title('acceleration on z in fucntion of time')

figure(7)
plot(t,Vx,'b')
grid on
xlabel('time in second')
ylabel('m/s')
title('Velocity on x in fucntion of time')

figure(8)
plot(t,Vy,'r')
grid on
xlabel('time in second')
ylabel('m/s')
title('Velocity on y in fucntion of time')

figure(9)
plot(t,Vz,'g')
grid on
xlabel('time in second')
ylabel('m/s')
title('Velocity on z in fucntion of time')

figure(10)
plot(t,Xx,'b')
grid on
xlabel('time in second')
ylabel('m')
title('position on x in fucntion of time')

figure(11)
plot(t,Xy,'r')
grid on
xlabel('time in second')
ylabel('m')
title('position on y in fucntion of time')

figure(12)
plot(t,Xz,'g')
grid on
xlabel('time in second')
ylabel('m')
title('position on z in fucntion of time')