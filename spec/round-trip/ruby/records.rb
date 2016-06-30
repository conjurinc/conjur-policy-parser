user "bob" do
  uidnumber 1001
  annotation "email", "bob@example.com"
end

group "ci-admins" do
  gidnumber  1234
  annotation "description", "Admins of the CI team"
end

host "a-host"

layer "a-layer"

variable "db-password" do
  mime_type "text/plain"
  kind "Database password"
end

webservice "api"

role "job", "cook"

resource "food", "bacon"
