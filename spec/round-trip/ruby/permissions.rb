permit "read" do
  role group("ops")
  resource variable("foobar")
end

permit %w(read execute) do
  role group("developers"), grant_option: true
  role group("support")
  resource variable("foobar")
  resource group('users')

  replace true
end
