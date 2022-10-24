clear
run("init")

kama_send(dev_ports.kama, [50.0 12.0 54545]);

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
    deg_test = [(355.5:0.1:359.9)'; (0.0:0.1:5.0)'];
    deg_test = repelem(45, 10);
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

function kama_send(port, coords)

    arguments
        port (1, 1) 
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

    % port.write(buf, 'uint8');
    fprintf("Send from Kama:");
    fprintf(" 0x%02X", buf);
    fprintf("\n");

end
