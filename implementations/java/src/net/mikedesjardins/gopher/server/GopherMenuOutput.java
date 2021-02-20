package net.mikedesjardins.gopher.server;

import java.io.InputStream;
import java.nio.file.Paths;
import java.util.logging.Logger;

/**
 * A "GopherOutput" class. This descendant of GopherOutput is used to emit a GopherMenu (as opposed to a file or
 * an error message).
 */
public class GopherMenuOutput extends GopherOutput {
    private static final Logger LOGGER = Logger.getLogger(GopherMenuOutput.class.getName());

    public GopherMenuOutput(String selector) {
        super(selector);
    }

    @Override
    public InputStream stream() {
        Paths.get(Config.getRoot(), selector);

        GopherMenu gopherMenu = GopherMenuFactory.create(selectorToPath());
        return gopherMenu.stream();
    }
}
