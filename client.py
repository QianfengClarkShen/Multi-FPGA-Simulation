'''
 @author Qianfeng (Clark) Shen
 @email qianfeng.shen@gmail.com
 @create date 2023-08-22 11:00:40
 @modify date 2023-08-22 11:00:40
    This is a simple client program that sends two integers to the systemverilog socket server
    The socket server then pass the two integers to the adder module (DUT) written in systemverilog
    This python script then tries to receive the sum of the two integers from the server
'''
import socket

if __name__ == '__main__':
    host = 'localhost'
    port = 15000
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((host, port))
    print('Connected to server')
    num1 = 22
    num2 = 33
    buf_in = num1.to_bytes(4, byteorder='little') + num2.to_bytes(4, 'little')
    s.send(buf_in)
    print('Sent two integers to server: %d, %d' % (num1, num2))
    print('Waiting for result from server...')
    buf_out = s.recv(4)
    num3 = int.from_bytes(buf_out, 'little')
    print('Received result from server: %d' % num3)
    s.close()
    print('Connection closed')
