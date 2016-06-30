grant do
  role group("everyone")
  member group("developers")
  member group("support")
  member group("marketing")
  member group("ops"), admin: true
end

grant do
  role automatic_role(layer("webservice"), "use_host")
  member group("developers")
  replace true
end
