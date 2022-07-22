disp('Start Init');

insys_port = find_insys_port();

if isempty(insys_port)
    disp('Инсус не найдена');
else
    fprintf("Инсус подключена к порту %s\n", insys_port.Port);
end

if isempty(pup_port)
    disp('Плата ПУП не найдена');
else
    fprintf("Плата ПУП подключена к порту %s\n", pup_port.Port);
end

if isempty(pmes_port)
    disp('Плата измерений не найдена');
else
    fprintf("Плата измерений подключена к порту %s\n", pmes_port.Port);
end

disp('Complete Init');

%% function
function insys_port = find_insys_port()
    disp("Поиск Инсус...");
    baudrate = 115200;
    % ports = serialportlist("available");
    ports = "COM6";

    for port = ports
        fprintf("Попытка подключения к порту %s\n", port);
        insys_port = serialport(port, baudrate, Timeout = 5);
        insys_port.flush();

        w = warning('off', 'all');
        data = insys_port.readline();
        warning(w);

        if ~isempty(data)
            return;
        end

    end

    insys_port = [];

end
