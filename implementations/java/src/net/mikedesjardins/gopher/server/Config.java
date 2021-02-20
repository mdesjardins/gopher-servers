package net.mikedesjardins.gopher.server;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Nasty static global config object.
 */
public class Config {
    private static final Logger LOGGER = Logger.getLogger(Config.class.getName());
    private static String host = "localhost";
    private static int port = 70;
    private static String root = "/var/gopher";
    private static String mapFilename = "gophermap";

    static {
        try {
            host = InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException e) {
            LOGGER.log(Level.WARNING, "Unable to determine host name.");
        }
    }

    /**
     * The host name as configured by the user. By default we try to determine it using getHostName, and if that fails
     * we fall back to 'localhost'.
     * @return hostname to be rendered on Gopher Menu Items.
     */
    public static String getHost() { return host; }
    public static void setHost(String host) { Config.host = host; }

    /**
     * The port number as configured by the user. Default is 70.
     * @return port number.
     */
    public static int getPort() { return port; }
    public static void setPort(int port) { Config.port = port; }
    public static void setPort(String port) { Config.port = Integer.parseInt(port); }

    /**
     * The root directory of the files to be served by this Gopher server. Defaults to /var/gopher.
     * @return a string path.
     */
    public static String getRoot() {
        return root;
    }
    public static void setRoot(String root) {
        Config.root = root;
    }

    /**
     * The name of the gophermap as configured by the user. Default is 'gophermap'.
     * @return The gophermap filename
     */
    public static String getMapFilename() { return mapFilename; }
    public static void setMapFilename(String mapFilename) { Config.mapFilename = mapFilename; }
}
