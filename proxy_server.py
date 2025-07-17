import threading
import logging
import os
import time
import json
import socket
import collections

# 初始化日志记录器
logger = logging.getLogger("ProxyServer")
logging.basicConfig(level=logging.INFO)

# 存储服务器套接字
server_sockets = {}
server_sockets_lock = threading.Lock()

proxy_rules = {}
RULES_FILE = 'proxy_rules.json'

def load_rules():
    """
    加载转发规则
    """
    global proxy_rules
    if os.path.exists(RULES_FILE):
        try:
            with open(RULES_FILE, 'r', encoding='utf-8') as f:
                proxy_rules = json.load(f)
            logger.info(f"已加载 {len(proxy_rules)} 条转发规则")
        except Exception as e:
            logger.error(f"加载规则文件失败: {e}")
            proxy_rules = {}
    else:
        logger.info("规则文件不存在，将使用空规则")
        proxy_rules = {}

def handle_client(client_socket, remote_address, local_port):
    remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        remote_socket.connect(remote_address)
        def forward(src, dst, direction):
            try:
                while True:
                    data = src.recv(4096)
                    if not data:
                        break
                    dst.sendall(data)
            except Exception:
                pass
            finally:
                try: src.close()
                except: pass
                try: dst.close()
                except: pass
        t1 = threading.Thread(target=forward, args=(client_socket, remote_socket, 'up'), daemon=True)
        t2 = threading.Thread(target=forward, args=(remote_socket, client_socket, 'down'), daemon=True)
        t1.start(); t2.start(); t1.join(); t2.join()
    except Exception as e:
        logger.error(f"处理客户端连接时出错: {e}")
    finally:
        try: client_socket.close()
        except: pass
        try: remote_socket.close()
        except: pass

def start_proxy_server(local_port, remote_ip, remote_port):
    local_address = ('0.0.0.0', int(local_port))
    remote_address = (remote_ip, int(remote_port))
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server_socket.bind(local_address)
        server_socket.listen(5)
        logger.info(f"代理服务器已启动，监听 {local_address[1]} -> {remote_ip}:{remote_port}")
        with server_sockets_lock:
            server_sockets[local_port] = server_socket
        while True:
            client_socket, _ = server_socket.accept()
            threading.Thread(target=handle_client, args=(client_socket, remote_address, local_port), daemon=True).start()
    except Exception as e:
        logger.error(f"启动代理服务器时出错 (端口 {local_port}): {e}")
    finally:
        with server_sockets_lock:
            if local_port in server_sockets:
                del server_sockets[local_port]
        try: server_socket.close()
        except: pass
        logger.info(f"代理服务器已停止 (端口 {local_port})")

def start_all_proxy_servers():
    logger.info("启动所有代理服务器...")
    threads = []
    for local_port, rule in proxy_rules.items():
        # 兼容旧格式（list/tuple）和新格式（dict）
        if isinstance(rule, dict):
            remote_ip = rule.get('remote_ip')
            remote_port = rule.get('remote_port')
        else:
            remote_ip, remote_port = rule
        t = threading.Thread(target=start_proxy_server, args=(int(local_port), remote_ip, int(remote_port)), daemon=True)
        t.start()
        threads.append(t)
    return threads

def stop_all_proxy_servers():
    with server_sockets_lock:
        for port, server_socket in list(server_sockets.items()):
            try:
                # 先shutdown再close，确保所有连接被强制断开
                server_socket.shutdown(socket.SHUT_RDWR)
            except Exception:
                pass
            try:
                server_socket.close()
                logger.info(f"已关闭端口 {port} 的服务器套接字")
            except Exception as e:
                logger.error(f"关闭端口 {port} 的服务器套接字时出错: {e}")
        server_sockets.clear()

def watch_rules_file(interval=2):
    last_mtime = None
    while True:
        try:
            mtime = os.path.getmtime(RULES_FILE)
            if last_mtime is None:
                last_mtime = mtime
            elif mtime != last_mtime:
                logger.info("检测到规则文件变动，重新加载并应用规则...")
                stop_all_proxy_servers()
                load_rules()
                start_all_proxy_servers()
                last_mtime = mtime
        except Exception:
            pass
        time.sleep(interval)

if __name__ == "__main__":
    load_rules()
    start_all_proxy_servers()
    logger.info("代理服务器已启动，支持热加载规则，按 Ctrl+C 退出")
    watcher = threading.Thread(target=watch_rules_file, daemon=True)
    watcher.start()
    try:
        while True:
            threading.Event().wait(1)
    except KeyboardInterrupt:
        logger.info("接收到退出信号，正在关闭服务器...")
        stop_all_proxy_servers()
        logger.info("服务器已完全关闭")

