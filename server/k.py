#!/usr/bin/env python
import socket, threading, k, sys, pprint

HOST = "localhost"

# Ensures the connection is still active
def keepalive(conn, addr):
    print("Client connected")
    with conn:
        while True:
            try:
                data = conn.recv(1024)
                if not data: break
                print(data)
                print(data.decode("utf-8"))
                r = k.k(data.decode("utf-8"))
                print(r)
                print('after k')
                pp = pprint.PrettyPrinter(width=41, compact=True)
                r = pp.pformat(r)
                print('after format')
                conn.sendall(r.encode('utf-8') + b'\n')
            except Exception as e:
                print(e)
                break
        print("Client disconnected")

# Listens for connections to the server and starts a new keepalive thread
def listenForConnections():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind((HOST, int(sys.argv[1])))
        while True:
            sock.listen()
            conn, addr = sock.accept()
            t = threading.Thread(target=keepalive, args=(conn, addr))
            t.start()

if __name__ == '__main__':
    # Starts up the socket server
    SERVER = threading.Thread(target=listenForConnections)
    SERVER.start()
