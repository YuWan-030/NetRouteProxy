import subprocess
import sys
import threading
import time

def run_admin():
    subprocess.run([sys.executable, 'proxy_admin.py'])

def run_server():
    subprocess.run([sys.executable, 'proxy_server.py'])

if __name__ == '__main__':
    t1 = threading.Thread(target=run_admin, daemon=True)
    t2 = threading.Thread(target=run_server, daemon=True)
    t1.start()
    t2.start()
    print('管理服务和转发服务已同时启动。按 Ctrl+C 退出。')
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print('收到退出信号，主程序已退出。')

