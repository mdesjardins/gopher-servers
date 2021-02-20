package net.mikedesjardins.gopher.server;

import java.util.logging.Level;
import java.util.logging.Logger;

public class Main {
    private static final Logger LOGGER = Logger.getLogger(Main.class.getName());

    public static void main(String[] args) {
        for (String arg : args) {
            if (arg.startsWith("--port=")) {
                Config.setPort(arg.split("=")[1]);
            } else if (arg.startsWith("--host=")) {
                Config.setHost(arg.split("=")[1]);
            } else if (arg.startsWith("--root=")) {
                Config.setRoot(arg.split("=")[1]);
            } else if (arg.startsWith("--mapfilename=")) {
                Config.setMapFilename(arg.split("=")[1]);
            }
        }
        LOGGER.log(Level.INFO, "Starting Starting Gopher Server at " + Config.getHost() + " on port " + Config.getPort() + ", serving from " + Config.getRoot());
        GopherServer gopherServer = new GopherServer();
        gopherServer.serve();
    }
}
