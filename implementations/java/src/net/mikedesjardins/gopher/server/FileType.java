package net.mikedesjardins.gopher.server;
import java.util.HashMap;
import java.util.Map;

public enum FileType {
    TEXT('0'),
    DIRECTORY('1'),
    NAMESERVER('2'),
    ERROR('3'),
    HQX('4'),
    ARCHIVE('5'),
    SEARCH('7'),
    BINARY('9'),
    MIRROR('+'),
    GIF('g'),
    IMAGE('I'),
    // unofficial
    DOC('d'),
    HTML('h'),
    INFO('i'),
    SOUND('s'),
    VIDEO(';'),
    CALENDAR('c');

    public char gopherType;
    FileType(char gopherType) {
        this.gopherType = gopherType;
    }

    private final static Map<String, FileType> extensionMap = new HashMap<>();
    static {
        extensionMap.put("txt", FileType.TEXT);
        extensionMap.put("md", FileType.TEXT);
        extensionMap.put("pl", FileType.TEXT);
        extensionMap.put("py", FileType.TEXT);
        extensionMap.put("sh", FileType.TEXT);
        extensionMap.put("tcl", FileType.TEXT);
        extensionMap.put("c", FileType.TEXT);
        extensionMap.put("cpp", FileType.TEXT);
        extensionMap.put("h", FileType.TEXT);
        extensionMap.put("log", FileType.TEXT);
        extensionMap.put("conf", FileType.TEXT);
        extensionMap.put("php", FileType.TEXT);
        extensionMap.put("php3", FileType.TEXT);
        extensionMap.put("hqx", FileType.HQX);
        extensionMap.put("zip", FileType.ARCHIVE);
        extensionMap.put("gz", FileType.ARCHIVE);
        extensionMap.put("Z", FileType.ARCHIVE);
        extensionMap.put("tgz", FileType.ARCHIVE);
        extensionMap.put("bz2", FileType.ARCHIVE);
        extensionMap.put("rar", FileType.ARCHIVE);
        extensionMap.put("ics", FileType.CALENDAR);
        extensionMap.put("ical", FileType.CALENDAR);
        extensionMap.put("gif", FileType.GIF);
        extensionMap.put("jpg", FileType.IMAGE);
        extensionMap.put("jpeg", FileType.IMAGE);
        extensionMap.put("png", FileType.IMAGE);
        extensionMap.put("bmp", FileType.IMAGE);
        extensionMap.put("mp3", FileType.SOUND);
        extensionMap.put("wav", FileType.SOUND);
        extensionMap.put("flac", FileType.SOUND);
        extensionMap.put("ogg", FileType.SOUND);
        extensionMap.put("avi", FileType.VIDEO);
        extensionMap.put("mp4", FileType.VIDEO);
        extensionMap.put("mpg", FileType.VIDEO);
        extensionMap.put("mov", FileType.VIDEO);
        extensionMap.put("qt", FileType.VIDEO);
        extensionMap.put("pdf", FileType.DOC);
        extensionMap.put("ps", FileType.DOC);
        extensionMap.put("doc", FileType.DOC);
        extensionMap.put("docx", FileType.DOC);
        extensionMap.put("ppt", FileType.DOC);
        extensionMap.put("pptx", FileType.DOC);
        extensionMap.put("xls", FileType.DOC);
        extensionMap.put("xlsx", FileType.DOC);
    }

    public static FileType getFromExtension(String extension) {
        return extensionMap.getOrDefault(extension, FileType.BINARY);
    }
}
