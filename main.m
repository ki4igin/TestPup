init

% Задание режима ПУП
% pup_port.write(0x11, 1);

% input("Нажмите Enter для начала теста")
deg_ref = (0:0.1:359.9)';
data = deg_ref + rand(length(deg_ref), 1);
deg_mes = deg_ref * 0;
deg_delta = deg_ref * 0;

figure
p = plot(0, 0, 'o', MarkerFaceColor = 'red');
al = animatedline('Color', [0 .7 .7]);
txt = text(0, 0, "");

for i = 1:length(deg_ref)
    % pup_write(0x11, uint32(deg_ref(i) * 10));
    % mes_port.write("test", 4);
    % data = mes_port.read(6, "single");
    % deg_mes(i) = data(2);
    deg_mes(i) = data(i);
    deg_delta(i) = deg_mes(i) - deg_ref(i);

    x = deg_ref(i);
    y = deg_delta(i);

    addpoints(al, x, y);
    p.XData = x;
    p.YData = y;
    txt.Position = [x, y];
    txt.String = ['\leftarrow' num2str(y)];
    drawnow limitrate

    pause(0.01);

end

outdata = [deg_ref, deg_mes, deg_delta];
save('data.mat', 'outdata');

disp("Press Ctrl+C to exit ;)");
while true
end

%% function
function pup_write(pup_port, id, cmd)
    id = uint8(id);
    cmd = uint32(cmd);
    message = uint8(zeros(6, 1));
    message(1) = id;
    message(2:5) = typecast(cmd, 'uint8');
    message(6) = mod(sum(message), 256);
    pup_port.write(message, 6);
    fprintf("Send to Pup:");
    fprintf(" 0x%02X", message);
    fprintf("\n");
end
