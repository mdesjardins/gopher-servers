package net.mikedesjardins.gopher.server;

import java.net.ServerSocket;
import java.net.Socket;

/**
 * The main Server class. This class really just sits in an infinite loop and hands the real work off to a
 * thread to do the real work.
 */
public class GopherServer {
    public void serve() {
        try (ServerSocket serverSocket = new ServerSocket(Config.getPort())) {
            while (true) {
                Socket socket = serverSocket.accept();
                new GopherServerThread(socket).start();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
