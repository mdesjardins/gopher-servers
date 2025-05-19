defmodule GopherServer.RequestHandler do
  require Logger
  require File
  require Path

  def serve(_root, selector, stat) do
    Logger.info "serve"
    case stat.type do
      :regular -> Logger.info "Serve a regular file #{selector}"
      :directory -> Logger.info "Oops, it's a directory #{selector}"
      _ -> Logger.info "What's this then? #{stat}"
    end
  end

  def process_request(selector) do
    Logger.info "handle_request"
    root = Application.get_env(:gopher_server, :root)
    target = Path.expand(Path.join(root, selector))
    {_err, _stat} = File.stat(target)
    case File.stat(target) do
      {:error, :enoent} -> Logger.info "File not found"
      {:error, posix_err} -> Logger.info "Got an error #{posix_err}"
      {:ok, stat} -> serve(root, selector, stat)
    end
    selector
  end
end
