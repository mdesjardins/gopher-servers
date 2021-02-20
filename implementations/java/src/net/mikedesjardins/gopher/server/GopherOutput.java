package net.mikedesjardins.gopher.server;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * This Abstract Base Class represents a thing that can be streamed out to a Gopher Client from the server. There's
 * a convenience method in here that converts a selector to a path, but it assumes that you are in the root directory.
 */
public abstract class GopherOutput {
    protected String selector;
    public GopherOutput(String selector) {
        this.selector = selector;
    }
    public abstract InputStream stream() throws IOException;

    /**
     * Utility method that resolves a selector to a path in our gopher root.
     * @return A full filesystem path to our desired selector.
     */
    protected Path selectorToPath() {
        return Paths.get(Config.getRoot(), selector);
    }
}
