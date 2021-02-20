package net.mikedesjardins.gopher.server;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Stream;

/**
 * Emits a stream that corresponds to a file that the client requested.
 */
public class GopherFileOutput extends GopherOutput {
    private static final Logger LOGGER = Logger.getLogger(GopherFileOutput.class.getName());

    public GopherFileOutput(String selector) {
        super(selector);
    }

    @Override
    public InputStream stream() {
        Path path = selectorToPath();
        if (isTextFile(path)) {
            // We treat text files slightly differently. Because we want to ensure that the carriage-return follows
            // the MS-DOS "line feed plus carriage return" pattern as dictated by the Gopher protocol, we instead read
            // the file content and carefully convert all the line endings as needed before streaming. I'm not really
            // certain how necessary this is tbh.
            StringBuffer sb = new StringBuffer();
            try (Stream<String> stream = Files.lines(path)) {
                stream.forEach((line) -> sb.append(line.stripTrailing()).append("\r\n"));
            } catch (IOException e) {
                LOGGER.log(Level.WARNING, "Unable to open: " + path.toString());
            }
            return new ByteArrayInputStream(sb.toString().getBytes(StandardCharsets.UTF_8));
        }
        try {
            return new FileInputStream(path.toFile());
        } catch (FileNotFoundException e) {
            // Race condition maybe? I dunno.
            LOGGER.log(Level.WARNING, "File not found even though it was just there: " + path.toString());
        }
        return null;
    }

    private boolean isTextFile(Path path) {
        int index = path.getFileName().toString().lastIndexOf('.');
        if (index > 0) {
            String extension = path.getFileName().toString().substring(index + 1);
            return FileType.getFromExtension(extension) == FileType.TEXT;
        }
        return false;
    }
}
