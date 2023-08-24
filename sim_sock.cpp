/**
 * @author Qianfeng (Clark) Shen
 * @email qianfeng.shen@gmail.com
 * @create date 2023-08-22 10:49:09
 * @modify date 2023-08-22 10:49:09
 * @desc:
 * This program provides a socket interface for systemverilog Direct Programming Interface (DPI) to use.
 */

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fstream>
#include <sstream>

#define SIM_SERVER 0
#define SIM_CLIENT 1
#define MAX_BUF_DEPTH 1024
typedef uint16_t u16;
typedef uint32_t u32;
typedef unsigned char uchar;

static std::ifstream tcp_status_fd;

class sock_container {
public:
    int server_id;
    int client_id;
    int type;
    int ip_addr;
    int port;
};

sock_container* sim_server_init(int ip_addr, int port) {
    int server_id = socket(AF_INET, SOCK_STREAM, 0);
    if (server_id == -1)
        return nullptr;
    int reuse = 1;
    setsockopt(server_id, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(int));
    struct sockaddr_in serverAddr;
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons((u16)port);
    serverAddr.sin_addr.s_addr = ip_addr;
    if (bind(server_id, (struct sockaddr*)&serverAddr, sizeof(serverAddr)) == -1)
        return nullptr;
    if (listen(server_id, 5) == -1)
        return nullptr;
    sock_container *cont = new sock_container;
    cont->server_id = server_id;
    cont->client_id = -1;
    cont->type = SIM_SERVER;
    cont->ip_addr = ip_addr;
    cont->port = port;
    return cont;
}

sock_container* sim_client_init(int ip_addr, int port) {
    int client_id = socket(AF_INET, SOCK_STREAM, 0);
    if (client_id == -1)
        return nullptr;
    struct sockaddr_in serverAddr;
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons((u16)port);
    serverAddr.sin_addr.s_addr = ip_addr;
    if (connect(client_id, (struct sockaddr*)&serverAddr, sizeof(serverAddr)) == -1)
        return nullptr;
    sock_container *cont = new sock_container;
    cont->server_id = -1;
    cont->client_id = client_id;
    cont->type = SIM_CLIENT;
    cont->ip_addr = ip_addr;
    cont->port = port;
    return cont;
}

extern "C" void* sim_init(int ip_addr, int port, int type) {
    sock_container* cont = nullptr;
    if (type == SIM_SERVER)
        cont = sim_server_init(ip_addr, port);
    else
        cont = sim_client_init(ip_addr, port);
    if (!cont)
        return nullptr;
    if (!tcp_status_fd.is_open())
        tcp_status_fd.open("/proc/net/tcp", std::ios::in);
    if (!tcp_status_fd.is_open())
        return nullptr;
    return (void*)cont;
}

extern "C" void sim_close(void* cont_v) {
    sock_container* cont = (sock_container*)cont_v;
    if (cont->server_id != -1)
        close(cont->server_id);
    if (cont->client_id != -1)
        close(cont->client_id);
    if (tcp_status_fd.is_open())
        tcp_status_fd.close();
    delete cont;
}

int sim_socket_status(void* cont_v) {
    sock_container* cont = (sock_container*)cont_v;
    int ip_addr = cont->ip_addr;
    int port = cont->port;
    std::string line;
    tcp_status_fd.clear();
    tcp_status_fd.seekg(0, std::ios::beg);
    std::getline(tcp_status_fd, line);
    int sl;
    u32 localAddress;
    u32 localPort;
    u32 remAddress;
    u32 remPort;
    u32 st;
    u32 txQueue;
    u32 rxQueue;
    u32 tr;
    u32 tmWhen;
    u32 retrnsmt;
    u32 uid;
    u32 timeout;
    u32 inode;
    while (std::getline(tcp_status_fd, line)) {
        std::istringstream iss(line);
        iss >> sl;
        iss.ignore(256, ':');
        iss >> std::hex >> localAddress;
        iss.ignore(256, ':'); // Ignore local_address colon
        iss >> std::hex >> localPort;
        iss >> std::hex >> remAddress;
        iss.ignore(256, ':'); // Ignore rem_address colon
        iss >> std::hex >> remPort;
        iss >> std::hex >> st;
        iss >> std::dec >> txQueue;
        iss.ignore(256, ':');
        iss >> std::dec >> rxQueue;
        iss >> tr;
        iss.ignore(256, ':');
        iss >> tmWhen;
        iss >> retrnsmt;
        iss >> uid;
        iss >> timeout;
        iss >> inode;
        if (localAddress == ip_addr && localPort == port && remAddress != 0)
            return st;
    }
    return 0;
}

int sim_rx_ready(void* cont_v) {
    sock_container* cont = (sock_container*)cont_v;
    int ip_addr = cont->ip_addr;
    int port = cont->port;
    std::string line;
    tcp_status_fd.seekg(0);
    std::getline(tcp_status_fd, line);
    int sl;
    u32 localAddress;
    u32 localPort;
    u32 remAddress;
    u32 remPort;
    u32 st;
    u32 txQueue;
    u32 rxQueue;
    u32 tr;
    u32 tmWhen;
    u32 retrnsmt;
    u32 uid;
    u32 timeout;
    u32 inode;
    while (std::getline(tcp_status_fd, line)) {
        std::istringstream iss(line);
        iss >> sl;
        iss.ignore(256, ':');
        iss >> std::hex >> localAddress;
        iss.ignore(256, ':'); // Ignore local_address colon
        iss >> std::hex >> localPort;
        iss >> std::hex >> remAddress;
        iss.ignore(256, ':'); // Ignore rem_address colon
        iss >> std::hex >> remPort;
        iss >> std::hex >> st;
        iss >> std::dec >> txQueue;
        iss.ignore(256, ':');
        iss >> std::dec >> rxQueue;
        iss >> tr;
        iss.ignore(256, ':');
        iss >> tmWhen;
        iss >> retrnsmt;
        iss >> uid;
        iss >> timeout;
        iss >> inode;
        if (localAddress == ip_addr && localPort == port && remAddress != 0)
            return rxQueue;
    }
    return 0;
}

extern "C" int sim_keep_alive(void* cont_v) {
    int status = sim_socket_status(cont_v);
    if (status == 1)
        return 0;
    sock_container* cont = (sock_container*)cont_v;
    int server_id = cont->server_id;
    int client_id = cont->client_id;
    if (status != 0 && client_id != -1)
        close(client_id);
    client_id = accept(server_id, nullptr, nullptr);
    if (client_id == -1)
        return -1;
    cont->client_id = client_id;
    return 0;
}

extern "C" int sim_write(void* cont_v, const uchar ptr[MAX_BUF_DEPTH], int bytes) {
    sock_container* cont = (sock_container*)cont_v;
    int sock_id = cont->client_id;
    return send(sock_id, (void*)ptr, bytes, 0);
}

extern "C" int sim_data_ready(void* cont_v) {
    return sim_rx_ready(cont_v);
}

extern "C" int sim_read(void* cont_v, uchar ptr[MAX_BUF_DEPTH], int bytes) {
    sock_container* cont = (sock_container*)cont_v;
    int sock_id = cont->client_id;
    return recv(sock_id, (void*)ptr, bytes, 0);
}

extern "C" void sim_sleep(int seconds){
    sleep(seconds);
}

extern "C" void sim_usleep(int useconds){
    usleep(useconds);
}