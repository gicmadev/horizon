defmodule Horizon.DownloadManager.Download do
  @moduledoc """
    Manage multiple download, in an unique way by using url for key
  """

  use GenServer
  require Logger

  alias Horizon.DownloadManager.DownloadStream
  alias Horizon.DownloadManager.Downloader

  @registry :downloads_registry

  ## API
  def start(url, opts),
    do: GenServer.start_link(__MODULE__, {url, opts}, name: via_tuple(url))

  def get_status(url) do
    data = Registry.lookup(@registry, url)
    Logger.debug("hello le status voila les data : #{inspect(data)}")

    with [{_pid, _}] <- data do
      GenServer.call(via_tuple(url), :status)
    else
      _ -> {:not_found, %{}, %{}}
    end
  end

  def get_download_stream(url) do
    GenServer.call(via_tuple(url), :get_download_stream)
  end

  ## Callbacks
  def init({url, opts}) do
    Logger.info("starting download of #{inspect(url)}")

    opts =
      opts
      |> Map.put(
        :filename,
        with %URI{path: url_path} <- URI.parse(url),
             url_filename <- Path.basename(url_path),
             true <- String.length(url_filename) > 0 do
          url_filename
        else
          _ -> Path.basename(opts.path)
        end
      )

    case spawn_downloader(url, opts) do
      {:ok, _pid} ->
        Logger.info("started download of #{inspect(url)}")

        {:ok,
         {:started,
          %{
            url: url,
            path: opts.path,
            filename: opts.filename,
            opts: opts
          }, %{}}}

      err ->
        {:errored, err}
    end
  end

  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_download_stream, _from, state) do
    {_, %{url: url, path: path, opts: opts}, _} = state

    {
      :reply,
      %DownloadStream{
        url: url,
        path: path,
        full_size: Map.get(opts, :expected_size, 0)
      },
      state
    }
  end

  def handle_info({:update_progress, {:add_downloaded_bytes, bytes}}, state) do
    {status, request, progress} = state

    {
      :noreply,
      {
        status,
        request
        |> set_expected_size_if_less(bytes),
        progress
        |> Map.update(:downloaded, 0, &(&1 + bytes))
        |> update_percent_downloaded
      }
    }
  end

  def handle_info({:update_progress, {:set_content_length, bytes}}, state) do
    {status, request, progress} = state

    Logger.debug("content lenght : #{inspect(bytes)}")

    {
      :noreply,
      {
        status,
        request
        |> set_expected_size_if_less(bytes),
        progress
        |> Map.put(:content_length, bytes)
      }
    }
  end

  def handle_info({:update_progress, {:set_filename, filename}}, state) do
    {status, request, progress} = state

    Logger.debug("set filename : #{filename}")

    {
      :noreply,
      {
        status,
        request
        |> Map.put(:filename, filename),
        progress
      }
    }
  end

  def handle_info({:update_status, :finished}, state) do
    {_, request, progress} = state

    Logger.info("Finished download of #{inspect(request.url)}")

    request |> exec_callback(:on_download_complete)

    {:stop, :normal, {:finished, request, progress}}
  end

  def handle_info({:update_status, {:errored, reason}}, state) do
    {_, request, progress} = state

    Logger.error("Download of #{inspect(request.url)} ERRORED : #{inspect(reason)}")

    request
    |> add_error(reason)
    |> exec_callback(:on_download_failed)

    {:stop, :normal, {:errored, request, progress}}
  end

  def handle_info({:update_status, {:crashed, reason}}, state) do
    {_, request, progress} = state

    Logger.error("Download of #{inspect(request.url)} CRASHED")

    request
    |> add_error(reason)
    |> exec_callback(:on_download_failed)

    {:stop, reason, {:crashed, request, progress}}
  end

  def handle_info({:update_status, status}, state) do
    {_, request, progress} = state

    Logger.info("Download of #{inspect(request.url)} status changed to #{inspect(status)}")

    {:noreply, {status, request, progress}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  ## Private

  defp add_error(request, error) do
    request
    |> Map.put(
      :error,
      case error do
        {reason, detail} -> %{error: reason, detail: detail}
        {reason} -> %{error: reason, detail: nil}
        reason when is_atom(reason) or is_binary(reason) -> %{error: reason, detail: nil}
        _ -> %{error: "unknown"}
      end
    )
  end

  defp exec_callback(request, which) do
    Logger.debug("exec_callback")
    Logger.debug(inspect(request))
    Logger.debug(inspect(which))

    with cb <- Map.get(request.opts, which, nil),
         true <- is_function(cb) do
      Logger.debug("executing callback #{inspect(which)}")
      cb.(request)
    else
      err -> Logger.debug("not executing callback #{inspect(err)}")
    end
  end

  defp set_expected_size_if_less(request, bytes) do
    with %{opts: opts} <- request,
         exp_size <- Map.get(opts, :expected_size, 0),
         true <- is_integer(exp_size) and exp_size > bytes do
      request
    else
      _ ->
        Map.update!(
          request,
          :opts,
          &Map.put(&1, :expected_size, bytes)
        )
    end
  end

  defp update_percent_downloaded(progress = %{downloaded: dl, content_length: tl}) do
    Logger.debug("trying to update percent_download with progress : #{inspect(progress)}")

    progress
    |> Map.put(
      :percent,
      case tl do
        tl when is_integer(tl) and tl > 0 -> dl * 100 / tl
        _ -> nil
      end
    )
  end

  defp update_percent_downloaded(progress) do
    Logger.debug("inspect : #{inspect(progress)}")

    progress
    |> Map.put(:percent, nil)
  end

  defp via_tuple(url),
    do: {:via, Registry, {@registry, url}}

  defp spawn_downloader(url, %{path: path, filename: filename}) do
    opts = %{
      download_pid: self(),
      path: path,
      filename: filename,
      url: url
    }

    {:ok, spawn_link(Downloader, :run, [opts])}
  end
end
