%GENERACION VALORES SENO

%Generamos el seno que empezara en 128 y alcanzara valor maximo 255 y valor
%minimo 0
x=(floor(128*sin([0:2*pi/255:2*pi]))+128)'

%Codigo para .MIF
for i=0:1:255
  disp([num2str(i),' : ',num2str(x(i+1)),';']);
end

%Codigo para componente
%for i=0:1:255
%  disp(['                   ',num2str(x(i+1)),' WHEN ',num2str(i),',']);
%end

%for i=0:1:255
%    disp(['                    WHEN ',num2str(i),' => valorFormaOnda <= ',num2str(x(i+1)),';']);
%end