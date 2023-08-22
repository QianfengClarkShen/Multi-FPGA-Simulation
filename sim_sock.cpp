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
#include <poll.h>

#define SIM_SERVER 0
#define SIM_CLIENT 1
#define MAX_BUF_DEPTH 1024
typedef uint16_t u16;
typedef uint32_t u32;
typedef unsigned char uchar;

class sock_container {
public:
    int server_id;
    int client_id;
    int type;
    struct pollfd poll_fd;
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
    int c_server_id = accept(server_id, nullptr, nullptr);
    sock_container *cont = new sock_container;
    cont->server_id = server_id;
    cont->client_id = c_server_id;
    cont->type = SIM_SERVER;
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
    cont->poll_fd.fd = cont->client_id;
    cont->poll_fd.events = POLLIN;
    return (void*)cont;
}

extern "C" void sim_close(void* cont_v) {
    sock_container* cont = (sock_container*)cont_v;
    if (cont->server_id != -1)
        close(cont->server_id);
    if (cont->client_id != -1)
        close(cont->client_id);
    delete cont;
}

extern "C" int sim_write(void* cont_v, const uchar ptr[MAX_BUF_DEPTH], int bytes) {
    sock_container* cont = (sock_container*)cont_v;
    int sock_id = cont->client_id;
    return send(sock_id, (void*)ptr, bytes, 0);
}

extern "C" int sim_data_ready(void* cont_v) {
    sock_container* cont = (sock_container*)cont_v;
    return poll(&(cont->poll_fd), 1, 0);
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