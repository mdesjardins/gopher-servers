package net.mikedesjardins.gopher.server;

import java.io.*;
import java.net.Socket;
import java.net.SocketException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * This class processes every client we accept a connection from.
 */
public class GopherServerThread extends Thread {
    private static final Logger LOGGER = Logger.getLogger(GopherServerThread.class.getName());
    private final int BUFFER_SIZE = 16384;
    private final Socket socket;

    public GopherServerThread(Socket socket) {
        this.socket = socket;
    }

    /**
     * Runs on every thread. Read the input from the socket, which should be the selector, figure out what to do with
     * it, and stream some output back.
     */
    public void run() {
        try {
            // Get the selector
            InputStream inputStream = socket.getInputStream();
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
            String selector = reader.readLine();

            LOGGER.log(Level.INFO, "Requested: " + Paths.get(Config.getRoot(), selector).toString());

            // Figure out what to do (is it a file? directory? neither?). Default to not found.
            GopherOutput result = new GopherNotFoundOutput(selector);
            if (isDirectory(selector)) {
                result = new GopherMenuOutput(selector);
            } else if (isFile(selector)) {
                result = new GopherFileOutput(selector);
            }

            // Pick up the stream from the GopherOutput and stream it out.
            InputStream in = result.stream();
            if (in != null) {
                OutputStream out = socket.getOutputStream();
                streamResult(in, out);
            } else {
                LOGGER.log(Level.WARNING, "Well, that's weird. The input stream from GopherOutput was null.");
            }
        } catch (SocketException e) {
            // One cause of this can be if the server disconnects prematurely, resulting in a broken pipe.
            LOGGER.log(Level.WARNING, "Socket Exception: " + e.getMessage());
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "There's a wocket in my socket!", e);
        } finally {
            try {
                socket.close();
            } catch (IOException e) {
                LOGGER.log(Level.SEVERE, "Unable to close socket.", e);
            }
        }
    }

    /**
     * Does the loop where we read the buffer and write it out.
     * @param in an input stream from a GopherOutput
     * @param out an output stream tied to the socket.
     * @throws IOException if we have an I/O problem (duh).
     */
    private void streamResult(InputStream in, OutputStream out) throws IOException {
        byte[] bytes = new byte[BUFFER_SIZE];
        int count;
        while ((count = in.read(bytes)) > 0) {
            out.write(bytes, 0, count);
        }
    }

    /**
     * Does this selector correspond to a directory in our gopher root?
     * @param selector the selector from the client.
     * @return true if selector is a directory we can read and serve.
     */
    private boolean isDirectory(String selector) {
        Path path = Paths.get(Config.getRoot(), selector);
        return Files.exists(path) && Files.isReadable(path) && Files.isDirectory(path);
    }

    /**
     * Does this selector correspond to a file in our gopher root?
     * @param selector the selector from the client.
     * @return true if selector is a file we can read and serve.
     */
    private boolean isFile(String selector) {
        Path path = Paths.get(Config.getRoot(), selector);
        return Files.exists(path) && Files.isReadable(path) && Files.isRegularFile(path);
    }
}
