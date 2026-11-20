data "nutanix_users_v2" "all" {
  limit = 100
}

data "nutanix_directory_services_v2" "all" {
  limit = 100
}

data "nutanix_roles_v2" "all" {
  limit = 100
}

locals {
  admin_user = [
    for u in data.nutanix_users_v2.all.users : u
    if u.username == "admin" && u.user_type == "LOCAL"
  ][0]

  ntnxlab_idp = [
    for d in data.nutanix_directory_services_v2.all.directory_services : d
    if d.name == "ntnxlab"
  ][0]

  super_admin_role = [
    for r in data.nutanix_roles_v2.all.roles : r
    if r.display_name == "Super Admin"
  ][0]

  operator_role = [
    for r in data.nutanix_roles_v2.all.roles : r
    if r.display_name == "Operator"
  ][0]
}

output "ntnxlab_idp_id" {
  value = local.ntnxlab_idp.ext_id
}

resource "nutanix_directory_services_v2" "ntnxlab" {
  name              = local.ntnxlab_idp.name
  directory_type    = local.ntnxlab_idp.directory_type
  domain_name       = local.ntnxlab_idp.domain_name
  url               = local.ntnxlab_idp.url
  group_search_type = local.ntnxlab_idp.group_search_type

  service_account {
    username = local.ntnxlab_idp.service_account[0].username
    password = var.ad_password
  }

  shared_with_projects = distinct(concat(
    tolist(coalesce(local.ntnxlab_idp.shared_with_projects, toset([]))),
    [nutanix_project_v2.this.ext_id]
  ))

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      service_account,
      secondary_urls,
      white_listed_groups,
      share_with_all_projects,
    ]
  }
}

resource "nutanix_user_groups_v2" "ad_administrators" {
  group_type         = "LDAP"
  idp_id             = local.ntnxlab_idp.ext_id
  distinguished_name = "cn=administrators,cn=builtin,dc=ntnxlab,dc=local"
}

resource "nutanix_user_groups_v2" "ad_users" {
  group_type         = "LDAP"
  idp_id             = local.ntnxlab_idp.ext_id
  distinguished_name = "cn=users,cn=builtin,dc=ntnxlab,dc=local"
}

resource "nutanix_role_membership_v2" "local_admin" {
  identity_ext_id     = local.admin_user.ext_id
  identity_type       = "USER"
  idp_ext_id          = local.admin_user.idp_id
  project_ext_id      = nutanix_project_v2.this.ext_id
  role_ext_id         = local.super_admin_role.ext_id
  scope_template_name = "ProjectsScopeTemplate"

  scope_template_name_values {
    name  = "projectExtId"
    value = nutanix_project_v2.this.ext_id
  }
}

resource "nutanix_role_membership_v2" "ad_administrators" {
  identity_ext_id     = coalesce(nutanix_user_groups_v2.ad_administrators.ext_id, nutanix_user_groups_v2.ad_administrators.id)
  identity_type       = "GROUP"
  idp_ext_id          = local.ntnxlab_idp.ext_id
  project_ext_id      = nutanix_project_v2.this.ext_id
  role_ext_id         = local.super_admin_role.ext_id
  scope_template_name = "ProjectsScopeTemplate"

  scope_template_name_values {
    name  = "projectExtId"
    value = nutanix_project_v2.this.ext_id
  }

  depends_on = [nutanix_directory_services_v2.ntnxlab]
}

resource "nutanix_role_membership_v2" "ad_users" {
  identity_ext_id     = coalesce(nutanix_user_groups_v2.ad_users.ext_id, nutanix_user_groups_v2.ad_users.id)
  identity_type       = "GROUP"
  idp_ext_id          = local.ntnxlab_idp.ext_id
  project_ext_id      = nutanix_project_v2.this.ext_id
  role_ext_id         = local.operator_role.ext_id
  scope_template_name = "ProjectsScopeTemplate"

  scope_template_name_values {
    name  = "projectExtId"
    value = nutanix_project_v2.this.ext_id
  }

  depends_on = [nutanix_directory_services_v2.ntnxlab]
}