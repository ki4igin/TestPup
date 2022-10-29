clear
close all
% название платы для теста "az" или "el"
pup_name = 'az';
run("init");

pup_port = dev_ports.pup;
pmes_port = dev_ports.pmes;
kama_port = dev_ports.kama;

% kama_send(dev_ports.kama, [50.0 12.0 54545]);

% Задание режима ПУП
pup_write(pup_name, pup_port, 0x1, 2);
pause(0.5);

% Задание коррекции ошибки
pup_send_cor(pup_name, pup_port, 0);
pause(0.1);
pup_send_deg(pup_name, pup_port, 0);

% return
input("Нажмите Enter для начала теста")

f = figure;
p = plot(0, 0, 'o', 'MarkerFaceColor', 'red');
al = animatedline('Color', [0 .7 .7]);
txt = text(0, 0, "");

deg_test = (0:1:360)';
%deg_test = repelem(1,100);
k = 2;

deg_ref = repelem(deg_test, k);
deg_mes = deg_ref * 0;
deg_delta = deg_ref * 0;

xticks(1:k:length(deg_ref));
xticklabels(deg_test);

pup_send_deg(pup_name, pup_port, deg_test(1));
pause(0.2);
pup_send_deg(pup_name, pup_port, deg_test(1));
pause(0.2);

for i = 1:length(deg_ref)
    if mod(i, k) == 1
        fprintf("\n"); 
%         pup_send_deg(pup_name, pup_port, deg_ref(i));    
        kama_send(kama_port, [deg_ref(i), 50, 3000]);    
        fprintf("Ref degree %4.1f\n", deg_ref(i)); 
        fprintf(" Asin\t Acos\t Azap\t dsin\t dcos\t dzap\t dAz\t dEl\n"); 
    end

    pause(0.05);
    % pmes_port.write("TEST", "uint8");
    % data = pmes_port.pmes.read(8, "single");
    data = zeros(1,7);
    % disp(data);
%     deg_mes(i) = data(7); %for azimuth
    %deg_mes(i) = data(8); %for elevation
%     fprintf("%6.1f |%6.1f |%6.1f |%6.1f |%6.1f |%6.1f |%6.1f |%6.1f\n", data);   
%     deg_delta(i) = deg_ref(i) - deg_mes(i);

    if deg_delta(i) > 180
        deg_delta(i) = deg_delta(i) - 360;
    elseif deg_delta(i) < -180
        deg_delta(i) = deg_delta(i) + 360;
    end

%     x = i;
%     y = deg_delta(i);
% 
%     if isvalid(f)
%         addpoints(al, x, y);
%         p.XData = x;
%         p.YData = y;
%         txt.Position = [x, y];
%         txt.String = ['\leftarrow' num2str(y)];
%         drawnow limitrate
%     else
%         break;
%     end

end

outdata = [deg_ref, deg_mes, deg_delta, ];
save('data.mat', 'outdata');

input("Нажмите Enter для продолжения")
pup_send_cor(pup_name, pup_port, 0.5);
pup_write(pup_name, pup_port, 0x1, 1);
delete(pmes_port);
delete(pup_port);
delete(kama_port);

disp("Press Ctrl+C to exit ;)");

while true
end

%% function
function pup_send_deg(name, port, deg)
    arguments
        name
        port        
        deg (1,1) double
    end
    cmd = typecast(int32(deg * 10), "uint32");;
    pup_write(name, port, 0x2, cmd)
end

function pup_send_cor(name, port, correction)
    arguments
        name
        port        
        correction (1,1) double
    end
    cmd = typecast(int32(correction * 10), "uint32");
    cmd = uint32(bitshift(cmd, 16));
    pup_write(name, port, 0x6, cmd)
end

function pup_write(name, port, id, cmd)
    arguments
        name
        port
        id (1,1) uint8
        cmd (1,1) uint32
    end

    id = bitand(id, 0xF);
    if name == 'az'
        id = bitor(id, 0x10);
    elseif name == 'el'
        id = bitor(id, 0x20);
    end

    id = uint8(id);
    cmd = uint32(cmd);
    message = uint8(zeros(6, 1));
    message(1) = id;
    message(2:5) = fliplr(typecast(cmd, 'uint8'));
    message(6) = mod(sum(message), 256);
    port.write(message, 'uint8');
    fprintf("Send to Pup:");
    fprintf(" 0x%02X", message);
    fprintf("\n");
end

function kama_send(port, coords)
    arguments        
        port
        coords (1, 3) double
    end

    int_az = uint32(coords(1) * 16384/180);
    int_el = uint32(abs(coords(2) * 16384/180));
    el_is_neg = coords(2) < 0;
    int_r = uint32(coords(3));

    buf = uint8(zeros(1, 26));
    buf(1) = 0xEB;

    buf(12) = uint8(bitshift(bitand(int_az, 0b0111000000000000u32), -12));
    buf(13) = uint8(bitshift(bitand(int_az, 0b0000111111100000u32), -5));
    buf(14) = uint8(bitshift(bitand(int_az, 0b0000000000011111u32), 2));

    buf(15) = uint8(bitshift(bitand(int_r, 0b011000000000000000000000u32), -21));
    buf(16) = uint8(bitshift(bitand(int_r, 0b000111111100000000000000u32), -14));
    buf(17) = uint8(bitshift(bitand(int_r, 0b000000000011111110000000u32), -7));
    buf(18) = uint8(bitand(int_r, 0b000000000000000001111111u32));

    buf(19) = uint8(bitshift(bitand(int_el, 0b0111000000000000u32), -12));
    buf(20) = uint8(bitshift(bitand(int_el, 0b0000111111100000u32), -5));
    buf(21) = uint8(bitshift(bitand(int_el, 0b0000000000011111u32), 2));
    if el_is_neg
        buf(19) = bitor(buf(19), 0x40);
    end

    buf(25) = 0x9C;

    crc = sum(buf);
    crc = mod(crc, 256) + bitshift(crc, -8);
    crc = mod(crc, 256) + bitshift(crc, -8);
    crc = mod(crc, 256) + bitshift(crc, -8);

    buf(26) = uint8(crc);

    port.write(buf, 'uint8');
    fprintf("Send from Kama:");
    fprintf(" 0x%02X", buf);
    fprintf("\n");

end
