init

i = 0;
cnt_old = 0;
k = 0;
cnt_new = 0;
cnt_new_old = 0;

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

    if ~isvalid(f)
        break;
    end

    disp(line);

    i = i + 1;
    % time_ms = data(1);
    cnt = data(2);

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
