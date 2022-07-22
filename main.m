clear
run("init")

% Задание режима ПУП
pup_write(pup_port, 0x11, 1);
pause(0.5);

% Задание коррекции ошибки
pup_write(pup_port, 0x16, 0);
pause(0.1);

% return
input("Нажмите Enter для начала теста")

% hold on
f = figure;
tiledlayout(2, 1);
ax1 = nexttile;
ax2 = nexttile;
linkaxes([ax1 ax2], 'x');
p = plot(ax2, 0, 0, 'o', MarkerFaceColor = 'red');
p_new_old = plot(ax1, [0 0], [0 0], 'o', MarkerFaceColor = 'red');
al = animatedline(ax2, 'Color', "red");
al_new = animatedline(ax1, 'Color', "green");
al_old = animatedline(ax1, 'Color', "blue");
% hold off
txt = text(0, 0, "\leftarrow' num2str(0)");
txt_new = text(ax1, 0, 0, "\leftarrow' num2str(0)");
txt_old = text(ax1, 0, 0, "\leftarrow' num2str(0)");

while true
    line = insys_port.readline();
    data = sscanf(line, "Time = %ld , Pulse cnt = %d");

    if isempty(data)
        continue;
    end

deg_test = [(355.5:0.1:359.9)'; (0.0:0.1:5.0)'];
deg_test = repelem(45,10);
k = 10;

deg_ref = repelem(deg_test, k);
deg_mes = deg_ref * 0;
deg_delta = deg_ref * 0;

xticks(1:k:length(deg_ref));
xticklabels(deg_test);

pup_write(pup_port, 0x12, uint32(deg_test(1) * 10));
pause(0.2);
pup_write(pup_port, 0x12, uint32(deg_test(1) * 10));
pause(0.2);

for i = 1:length(deg_ref)
    if mod(i, k) == 1
        fprintf("\n"); 
        pup_write(pup_port, 0x12, uint32(deg_ref(i) * 10));        
        fprintf("Ref degree %4.1f\n", deg_ref(i)); 
        fprintf(" Asin\t Acos\t Azap\t dsin\t dcos\t dzap\t dAz\t dEl\n"); 
    end

    pause(0.3);
    pmes_port.write("TEST", "uint8");
    data = pmes_port.read(8, "single");
    % disp(data);
    deg_mes(i) = data(7);
    fprintf("%6.1f |%6.1f |%6.1f |%6.1f |%6.1f |%6.1f |%6.1f |%6.1f\n", data);   
    deg_delta(i) = deg_ref(i) - deg_mes(i);

    if deg_delta(i) > 180
        deg_delta(i) = deg_delta(i) - 360;
    elseif deg_delta(i) < -180
        deg_delta(i) = deg_delta(i) + 360;
    end

    x = i;
    y = deg_delta(i);

    if isvalid(f)
        addpoints(al, x, y);
        p.XData = x;
        p.YData = y;
        txt.Position = [x, y];
        txt.String = ['\leftarrow' num2str(y)];
        drawnow limitrate
    else
        break;
    end

    if cnt_new == cnt
        k = 0;
    end

    if cnt == cnt_old
        k = k + 1;
    end

    if k > 2
        cnt_new_old = cnt_new;
        cnt_new = cnt;
    end

    cnt_old = cnt;

    if cnt_new_old == 0
        continue;
    end

    delta_cnt = cnt_new - cnt_new_old;

    addpoints(al, i, delta_cnt);
    addpoints(al_new, i, cnt_new);
    addpoints(al_old, i, cnt_new_old);
    p.XData = i;
    p.YData = delta_cnt;
    p_new_old.XData = [i i];
    p_new_old.YData = [cnt_new cnt_new_old];
    txt.Position = [i, delta_cnt];
    txt_new.Position = [i, cnt_new];
    txt_old.Position = [i, cnt_new_old];
    txt.String = ['\leftarrow' num2str(delta_cnt)];
    txt_new.String = ['\leftarrow' num2str(cnt_new)];
    txt_old.String = ['\leftarrow' num2str(cnt_new_old)];
    xlim([0 (i * 1.3)])
    % ylim(ax1, [0 (cnt_new * 1.3)])
    drawnow limitrate
end
 
outdata = [cnt_new, cnt_new_old, delta_cnt];
save('data.mat', 'outdata');
disp("cnt_new, cnt_old, delta_cnt save to outdata in data.mat");

pup_write(pup_port, 0x11, 0);
delete(pup_port);
delete(pmes_port);

disp("Press Ctrl+C to exit ;)");

while true
end

%% function
function pup_write(pup_port, id, cmd)
    id = uint8(id);
    cmd = uint32(cmd);
    message = uint8(zeros(6, 1));
    message(1) = id;
    message(2:5) = fliplr(typecast(cmd, 'uint8'));
    message(6) = mod(sum(message), 256);
    pup_port.write(message, 'uint8');
    fprintf("Send to Pup:");
    fprintf(" 0x%02X", message);
    fprintf("\n");
end
