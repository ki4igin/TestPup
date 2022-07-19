disp('Start Init');

pup_port = find_pup_port();
pmes_port = find_pmes_port();

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
function pup_port = find_pup_port()
    disp("Поиск ПУП...");
    baudrate = 115200;
    ports = serialportlist("available");

    for port = ports
        fprintf("Попытка подключения к порту %s\n", port);
        pup_port = serialport(port, baudrate, 'Timeout', 0.5);
        pup_port.flush();

        w = warning('off', 'all');
        data = pup_port.read(6, "uint8");
        warning(w);

        if ~isempty(data)
            return;
        end

    end

    pup_port = [];

end

function pmes_port = find_pmes_port()
    disp("Поиск платы измерений...");
    baudrate = 115200;
    ports = serialportlist("available");

    for port = ports
        fprintf("Попытка подключения к порту %s\n", port);
        pmes_port = serialport(port, baudrate, 'Timeout', 0.5);
        pmes_port.flush();

        w = warning('off', 'all');
        pmes_port.write("TEST", "uint8");
        data = pmes_port.read(8, "single");
        warning(w);

        if ~isempty(data)
            return;
        end

    end

    pmes_port = [];

end
