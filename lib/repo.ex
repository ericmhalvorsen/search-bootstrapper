defmodule SearchBootstrapper.Repo do
  use Ecto.Repo, otp_app: :search_bootstrapper, adapter: Tds.Ecto
end

