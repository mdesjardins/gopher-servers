package net.mikedesjardins.gopher.server;

/**
 * This class represents one row/item on a gopher menu. Non-informational rows contain a type, name, selector,
 * port, and host. This thing also knows how to turn itself into a string which may be rendered to a client.
 */
public class GopherMenuItem {
    private final String host;
    private final int port;
    private final FileType type;
    private final String selector;
    private final String name;

    /**
     * Main c'tor for a menu item that actually has stuff on it (i.e. not an informational line)
     */
    public GopherMenuItem(String host, int port, FileType type, String selector, String name) {
        this.host = host;
        this.port = port;
        this.type = type;
        this.selector = selector;
        this.name = name;
    }

    /**
     * This constructor is handy for informational lines which don't really have all the other junk listed here.
     * @param type Usually just FileType.INFO because that's the only thing you'd use this for. :)
     * @param text The information gets rendered in the name field, so this just populates "name".
     */
    public GopherMenuItem(FileType type, String text) {
        this.host = Config.getHost();
        this.port = Config.getPort();
        this.type = type;
        this.selector = "";
        this.name = text;
    }

    public String toString() {
        String typeAndName = type.gopherType + name;
        return String.join("\t", typeAndName, selector, host, Integer.toString(port));
    }
}
