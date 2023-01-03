defmodule Line.OAuth do
  @channel_token Application.compile_env!(:roule_avec_spot, [Line, :channel_token])

  def channel_token() do
    @channel_token
  end

  defmodule Middleware do
    @behaviour Tesla.Middleware

    def call(env, next, _) do
      env
      |> Map.update!(:headers, &[{"Authorization", "Bearer #{Line.OAuth.channel_token()}"} | &1])
      |> Tesla.run(next)
    end
  end
end
