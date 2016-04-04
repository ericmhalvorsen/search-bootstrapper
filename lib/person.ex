defmodule SearchBootstrapper.Person do
  use Ecto.Model

  schema "rpt.CommonReportFields" do
    field :"patinfo-Address_1"
    field :"patinfo-City"
    field :"patinfo-DOB__dt"
    field :"PersonID"
    field :"Name"
    field :"patinfo-Sex"
    field :"patinfo-State"
    field :"patinfo-Zip"
    field :PersonActiveInd, :integer
  end
end
