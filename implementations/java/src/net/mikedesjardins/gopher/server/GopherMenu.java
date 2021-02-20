package net.mikedesjardins.gopher.server;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.stream.Collectors;

import static java.util.function.Predicate.isEqual;
import static java.util.function.Predicate.not;

/**
 * Represents a Menu that may be rendered by the server. A Gopher Menu can be generated either by reading a readable
 * Gopher Map file from a directory, or by reading the readable contents of a directory itself. The output may be
 * streamed.
 */
public class GopherMenu {
    private final List<GopherMenuItem> gopherMenuItems;

    public GopherMenu(List<GopherMenuItem> gopherMenuItems) {
        this.gopherMenuItems = gopherMenuItems;
    }

    public InputStream stream() {
        List<String> lines =
                gopherMenuItems
                        .stream()
                        .filter(not(isEqual(null)))
                        .map(GopherMenuItem::toString)
                        .collect(Collectors.toList());
        String emit = String.join("\r\n", lines) + "\r\n.\r\n";
        return new ByteArrayInputStream(emit.getBytes(StandardCharsets.UTF_8));
    }
}
