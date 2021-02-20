package net.mikedesjardins.gopher.server;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public class GopherNotFoundOutput extends GopherOutput {
    public GopherNotFoundOutput(String selector) {
        super(selector);
    }

    @Override
    public InputStream stream() throws IOException {
        String result = "3 '" + this.selector + "' doesn't exist!\t\t" + Config.getHost() + "\t" + Config.getPort() + "\r\n";
        return new ByteArrayInputStream(result.getBytes(StandardCharsets.UTF_8), 0, result.length());
    }
}
