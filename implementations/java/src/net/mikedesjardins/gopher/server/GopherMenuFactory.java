package net.mikedesjardins.gopher.server;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Generates a GopherMenu from either a directory, or based on a Gophermap in a directory.
 */
public class GopherMenuFactory {
    private static final Logger LOGGER = Logger.getLogger(GopherMenuFactory.class.getName());
    private static final Map<Character, FileType> gopherFileType = new HashMap<>();

    static {
        Arrays.stream(FileType.values()).forEach((type -> gopherFileType.put(type.gopherType, type)));
    }

    /**
     * Creates a new GopherMenu for the supplied directory. If there is a gophermap in the directory, the menu will
     * be based on the content of the Gophermap. Otherwise we will try to synthesize a GopherMenu based on the content
     * of the directory.
     * @param path Path to the directory for which a GopherMenu is to be generated
     * @return A GopherMenu.
     */
    public static GopherMenu create(Path path) {
        if (hasGopherMap(path)) {
            return GopherMenuFactory.createFromGopherMap(path);
        } else {
            return GopherMenuFactory.createFromDirectory(path);
        }
    }

    /**
     * Reads the contents of the directory at the supplied path and generates a GopherMenu based on those contents.
     * @param path Directory from which a GopherMenu is to be created.
     * @return A GopherMenu.
     */
    private static GopherMenu createFromDirectory(Path path) {
        List<GopherMenuItem> gopherMenuItems = new ArrayList<>();
        try {
            gopherMenuItems.addAll(
                Files.list(path).filter(Files::isReadable).map(GopherMenuFactory::processDirectoryEntry).collect(Collectors.toList())
            );
            return new GopherMenu(gopherMenuItems);
        } catch (IOException e) {
            e.printStackTrace();
        }

        return new GopherMenu(gopherMenuItems);
    }

    /**
     * Parses a GopherMap and returns a GopherMenu based on the content.
     * @param path Path to the Gophermap to be parsed
     * @return A new GopherMenu
     */
    private static GopherMenu createFromGopherMap(Path path) {
        final List<GopherMenuItem> gopherMenuItems = new ArrayList<>();
        Path gopherMapPath = Paths.get(path.toString(), Config.getMapFilename());

        try (Stream<String> stream = Files.lines(gopherMapPath)) {
            stream.forEach( (line) -> {
                GopherMenuItem gopherMenuItem = processGopherMapLine(line);
                if (gopherMenuItem != null) {
                    gopherMenuItems.add(gopherMenuItem);
                }
            });
        } catch (IOException e) {
            LOGGER.log(Level.WARNING, "Unable to open: " + path.toString());
        }
        return new GopherMenu(gopherMenuItems);
    }

    /**
     * Parses one line of a GopherMap into a GopherMenuItem.
     * @param line a string representing a line in a GopherMap.
     * @return A GopherMenuItem.
     */
    private static GopherMenuItem processGopherMapLine(String line) {
        // If there are no tabs in the line, call it informational.
        if (line.startsWith("#")) {
            return null;
        }
        if (!line.contains("\t")) {
            line = "i" + line;
        }

        String[] fields = line.split("\t");
        String typeAndName = fields[0];
        char type = typeAndName.charAt(0);
        String selector, host, port, name = null;

        if (fields.length > 1) {
            selector = fields[1];
            host = fields[2];
            port = fields[3];
            FileType fileType = gopherFileType.getOrDefault(type, null);
            if (fileType != null) {
                name = typeAndName.substring(1);
                return new GopherMenuItem(host, Integer.parseInt(port), fileType, selector, name);
            } else {
                LOGGER.log(Level.WARNING, "Invalid line in Gophermap: " + line);
                return null;
            }
        }
        return new GopherMenuItem(FileType.INFO, line.substring(1));
    }

    /**
     * Processes one entry in a directory and returns a correponsponding GopherMenuItem for each entry.
     * @param path Path to the directory entry to be processed.
     * @return a new GopherMenuItem.
     */
    private static GopherMenuItem processDirectoryEntry(Path path) {
        FileType fileType = FileType.BINARY;
        if (Files.isDirectory(path) && Files.isExecutable(path)) {
            fileType = FileType.DIRECTORY;
        } else {
            String fileName = path.getFileName().toString();
            int index = path.getFileName().toString().lastIndexOf('.');
            if (index > 0) {
                String extension = fileName.substring(index + 1);
                fileType = FileType.getFromExtension(extension);
            }
        }
        return new GopherMenuItem(Config.getHost(), Config.getPort(), fileType, path.toString(), path.getFileName().toString());
    }

    /**
     * Checks the supplied path to see if a gophermap is present and readable.
     * @param path Path to the directory to be checked.
     * @return true if a Gophermap exists and is readable.
     */
    private static boolean hasGopherMap(Path path) {
        Path pathToPossibleGophermap = Paths.get(path.toString(), Config.getMapFilename());
        return Files.exists(pathToPossibleGophermap) && Files.isReadable(pathToPossibleGophermap);
    }
}
