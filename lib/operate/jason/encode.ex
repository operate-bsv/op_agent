defimpl Jason.Encoder, for: Function do
  def encode(_func, _opts) do
    "\"function()\""
  end
end