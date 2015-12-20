% Janarthanan MARIASEELAN
% Akshay Domun
% 12/15/2015
% University of Arizona
clc
clear all


%% Declaration of the step time between two reception of bytes
inter=0.85;

%% Selection of how you want to receipt the data (serial/textfile)

% If you select the serial way , please connect the pc with the pic and put
% the good port for the input of the function serial (line 18).

% Otherwise please put the good name of your  text file into the variable
% filename (line 91)

choice = input('Please press a to launch the serial program or another letter for the text program ','s');

%% RS232
% This is the part which permit us to communicate between two devices : in
% this case we have our PC and the circuit
if choice == 'a'
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
t = [0:1:79];
%% Text File
else
% If we have data from a text format we'll use this program    

filename = 'matricetest3.txt'; %matrix.txt is a name of folder,we have to change it by the name of the binary file
matrix=importdata(filename); %to import the data of the binary file

%% Conversion of the binary vectors to decimal vectors

for i=1:8 % 1st column /matrix
    Q(:,1)=matrix(:,1);
end

A=cellfun(@(x) bin2dec(num2str(x)), num2cell(Q));%conversion binary to decimal

% num2str converts a numeric array into a string representation.

% num2cell convert array to cell array with consistently sized cells

% Cellfun apply function to each cell in cell array

% @ = adress to x , which mean all of the function is applied  to x

% To convert the  binary vectors to decimal, each element of the A matrix 
%will be include in cells , those cells will be transform in string 
%because the function bin2dec can convert only string binary 

for i=1:8 %2nd column /matrix
    R(:,1)=matrix(:,2);
end
B = cellfun(@(x) bin2dec(num2str(x)), num2cell(R));%conversion binary to decimal

for i=1:8 %3rd column /matrix
    S(:,1)=matrix(:,3);
end
C =cellfun(@(x) bin2dec(num2str(x)), num2cell(S));

for i=1:8 %3rd column /matrix
    T(:,1)=matrix(:,4);
end
D =cellfun(@(x) bin2dec(num2str(x)), num2cell(T));

for i=1:8 %3rd column /matrix
    U(:,1)=matrix(:,5);
end
E =cellfun(@(x) bin2dec(num2str(x)), num2cell(U));
%% Error detection
% We'll get 5 vector column the last two column will correspond to a
% control code : if the data are well send , the two last column will
% display respectively 255 in binary and 0

for i=1:length(D)
if D(i) < 255
 disp('----Error in Data transmission----')
 fprintf('Error occured at line %d',i)
end
end
for i=1:length(E)
if E(i)> 0
 disp('----Error in Data transmission----')
 fprintf('Error occured at line %d',i)
 
end
end




%% Declaration of time vector
t = [0:inter:3*inter];

end

%% Declaration of each acceleraton
Accx=A;
Accy=B;
Accz=C;


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


