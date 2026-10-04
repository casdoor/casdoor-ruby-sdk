# casdoor-ruby-sdk

[![CI](https://github.com/casdoor/casdoor-ruby-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/casdoor/casdoor-ruby-sdk/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/casdoor-ruby-sdk.svg)](https://rubygems.org/gems/casdoor-ruby-sdk)
[![Gem Downloads](https://img.shields.io/gem/dt/casdoor-ruby-sdk.svg)](https://rubygems.org/gems/casdoor-ruby-sdk)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7-CC342D.svg?logo=ruby)](https://www.ruby-lang.org/)
[![Code Style: RuboCop](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
[![License](https://img.shields.io/github/license/casdoor/casdoor-ruby-sdk.svg)](LICENSE)
[![Discord](https://img.shields.io/discord/1022748306096537660?logo=discord&label=discord&color=5865F2)](https://discord.gg/5rPsrAzK7S)

The Ruby SDK of [Casdoor](https://casdoor.ai/). It lets a Ruby application (Rails, Sinatra, Hanami, ...) sign users in
with Casdoor, verify the tokens issued by Casdoor, and manage the users, applications, roles, permissions and all the
other objects of Casdoor through its API.

It has the same APIs as the [Go SDK](https://github.com/casdoor/casdoor-go-sdk), in snake_case: `GetUsers()` is
`get_users`, `UpdateUserForColumns(user, columns)` is `update_user_for_columns(user, columns)`, and so on. The files
under `lib/casdoor/` match the files of the Go SDK's `casdoorsdk` package.

## Installation

Add it to the `Gemfile`:

```ruby
gem 'casdoor-ruby-sdk'
```

or install it directly with `gem install casdoor-ruby-sdk`.

It requires Ruby 2.7 or later, and depends only on the [jwt](https://github.com/jwt/ruby-jwt) gem.

## Configuration

| Name              | Must | Description                                                                         |
|-------------------|------|-------------------------------------------------------------------------------------|
| endpoint          | Yes  | The URL of Casdoor, such as `https://door.casdoor.com`                              |
| client_id         | Yes  | The "Client ID" of the application                                                  |
| client_secret     | Yes  | The "Client secret" of the application                                              |
| certificate       | No   | The "Certificate" of the application's cert (PEM), only needed to verify JWT tokens |
| organization_name | Yes  | The organization of the users                                                       |
| application_name  | Yes  | The name of the application                                                         |

Like the Go SDK, either create a client:

```ruby
require 'casdoor'

client = Casdoor.new_client(endpoint, client_id, client_secret, certificate, organization_name, application_name)
users = client.get_users
```

or initialize the global client, then call the APIs on the `Casdoor` module:

```ruby
Casdoor.init_config(endpoint, client_id, client_secret, certificate, organization_name, application_name)
users = Casdoor.get_users
```

`Casdoor::Client.new` takes the same settings as keyword arguments, plus `custom_headers:` (added to every request),
`open_timeout:` and `read_timeout:`.

The certificate is shown on the edit page of the cert that the application uses ("Certs" → the application's cert →
"Certificate"). A public key in PEM format works too.

## Signing users in

Casdoor signs users in with the OAuth 2.0 authorization code flow:

```ruby
# 1. Redirect the browser to the sign-in page of Casdoor
redirect_to client.get_signin_url('https://your-app.example.com/callback', state: session[:state] = SecureRandom.hex)

# 2. Casdoor redirects back to the callback with "code" and "state", exchange the code for the tokens
raise 'Invalid state' unless params[:state] == session[:state]
token = client.get_oauth_token(params[:code], params[:state])
# => {"access_token" => "...", "id_token" => "...", "refresh_token" => "...", "expires_in" => 604800, ...}

# 3. Verify the access token and read the user in it
claims = client.parse_jwt_token(token['access_token'])
claims.name          # => "alice"
claims.owner         # => "casbin", the organization
claims.user          # => Casdoor::User with the fields of the user
```

`parse_jwt_token` verifies the signature with the certificate, the expiration time, and that the token is issued to
this application (its client ID); otherwise it raises `Casdoor::InvalidTokenError`.

Other helpers:

```ruby
client.get_signup_url(true, '')                          # the sign-up page of the application
client.get_user_profile_url('alice', access_token)       # the profile page of a user
client.get_my_profile_url(access_token)                  # the profile page of the signed-in user
client.refresh_oauth_token(token['refresh_token'])
client.get_oauth_token_by_password('alice', 'password')   # needs the "password" grant type in the application
client.impersonate_user('alice', 'master-password')      # an admin acts as a user, with the organization's master password
client.introspect_token(token['access_token'])           # => {"active" => true, ...}
client.logout(token['access_token'])                     # signs the user out of all their sessions
client.logout_current_session(token['access_token'])     # signs the user out of the current session only
```

## Calling the API as a user

By default the client calls the API as the application, with the client ID and secret. To call it as the signed-in
user instead, which is subject to the user's own permissions:

```ruby
user_client = client.with_access_token(token['access_token'])
user = user_client.get_account
user.display_name = 'Alice'
user_client.update_user(user)
```

## Users

```ruby
user = client.get_user('alice')                 # in the client's organization, or client.get_user('org/alice')
user.display_name = 'Alice Smith'
user.properties = (user.properties || {}).merge('department' => 'R&D')
client.update_user(user)                         # => true when something changed
client.update_user_for_columns(user, %w[displayName email])   # only update these fields

client.add_user(Casdoor::User.new(name: 'bob', display_name: 'Bob', password: '123456'))
client.delete_user(client.get_user('bob'))

client.get_users                                 # => [Casdoor::User]
users, total = client.get_pagination_users(1, 20, field: 'name', value: 'a', sort_field: 'created_time')
client.get_sorted_users('created_time', 10)
client.get_global_users                          # the users of all the organizations
client.get_user_by_email('alice@example.com')
client.get_user_by_phone('13800000000')
client.get_user_by_user_id('uuid')               # by the "id" field of the user
client.update_user_by_id('casbin/alice', user)   # e.g. to rename the user
client.get_user_count('')                        # "" for all, "1" for the online users, "0" for the offline ones
client.set_password('casbin', 'alice', 'old-password', 'new-password')   # an admin can leave the old password empty
client.check_user_password(Casdoor::User.new(name: 'alice', password: 'password'))   # => true or false
```

The objects (`Casdoor::User`, `Casdoor::Application`, ...) keep all the fields returned by Casdoor, so an object that is
read, changed and updated never loses the fields this SDK doesn't know about. The fields can be read and written in
snake_case (`user.display_name`, `user.is_admin?`), or with their names in Casdoor (`user['displayName']`). The fields
whose names are taken by Ruby (e.g. `hash` of a user) can only be accessed with `[]`.

## The other objects

These methods exist for all the objects: adapters, applications, certs, enforcers, groups, invitations, models,
orders, organizations, payments, permissions, plans, pricings, products, providers, records, roles, sessions,
subscriptions, syncers, tokens, transactions, users and webhooks (the same as the Go SDK, e.g. records can't be
updated or deleted):

```ruby
client.get_roles                                  # => [Casdoor::Role]
client.get_pagination_roles(1, 20)                # => [[Casdoor::Role], total]
client.get_role('admin')                          # => Casdoor::Role or nil
client.add_role(Casdoor::Role.new(name: 'admin', users: ['casbin/alice']))
client.update_role(role)
client.update_role_for_columns(role, %w[users])
client.delete_role(role)
```

Organizations, applications, tokens and LDAP servers belong to `admin`, the other objects belong to the client's
organization. A different owner can be given by `"owner/name"` or by the `owner` field of the object.

More APIs of the objects:

```ruby
client.get_organization_applications                # the applications of the client's organization
client.get_organization_names
client.get_global_certs
client.get_permissions_by_role('admin')
client.get_invitation_info('CODE', 'app-example')
client.get_session('alice', 'app-example')
client.get_user_orders('alice')
client.cancel_order('order-1')
client.get_user_payments('alice')
client.notify_payment(payment)
client.invoice_payment(payment)
client.get_user_transactions('alice')
affected, transaction_id = client.add_transaction(transaction)
client.add_transaction_with_dry_run(transaction, true)
```

## Permissions and policies

```ruby
# One of the permission ID, model ID, resource ID, enforcer ID or owner chooses the policies to check
client.enforce('casbin/permission-1', '', '', '', '', %w[alice data1 read])   # => true or false
client.batch_enforce('', '', '', 'casbin/enforcer-1', '', [%w[alice data1 read], %w[bob data2 write]])
# => [[true, false]], the results of each permission

rule = Casdoor::CasbinRule.new(ptype: 'p', v0: 'alice', v1: 'data1', v2: 'read')
client.add_policy(enforcer, rule)
client.update_policy(enforcer, rule, new_rule)
client.remove_policy(enforcer, rule)
client.get_policies('enforcer-1', '')
client.get_filtered_policies('casbin/enforcer-1', [Casdoor::PolicyFilter.new(ptype: 'p', field_index: 0, field_values: ['alice'])])
```

## Orders and payments

```ruby
order = client.place_order([Casdoor::ProductInfo.new(name: 'product-1', quantity: 1)], 'alice')
payment = client.pay_order(order.name, 'provider_payment_dummy')
order = client.buy_product('product-1', 'provider_payment_dummy', 'alice')
```

## Resources, emails, SMS and notifications

```ruby
file_url, name = client.upload_resource('alice', 'avatar', '', 'alice.png', File.binread('alice.png'))
client.get_resources('casbin', 'alice', '', '', '', '')
client.delete_resource(client.get_resource("casbin/#{name}"))

client.send_email('Title', 'Content', 'sender', 'alice@example.com', 'bob@example.com')
client.send_email_by_provider('Title', 'Content', 'sender', 'provider_email', 'alice@example.com')
client.send_sms('Your code is 123456', '+15555550100')
client.send_sms_by_provider('Your code is 123456', 'provider_sms', '+15555550100')
client.send_notification('Content', 'recipient')
```

## MFA and LDAP

```ruby
response = client.initiate('casbin', 'app', 'alice')    # => {"status" => "ok", "data" => {"secret" => ..., "url" => ...}}
client.verify('casbin', 'app', 'alice', secret, passcode)
client.enable('casbin', 'app', 'alice', secret, recovery_code)
client.set_preferred('casbin', 'app', 'alice', secret)
client.delete('casbin', 'alice')                        # disables the MFA of the user

client.get_ldaps
client.get_ldap_users('ldap-id')                        # => {"users" => [Casdoor::LdapUser], ...}
client.sync_ldap_users_from_server('ldap-id')           # imports the LDAP users into Casdoor
```

## Errors

- `Casdoor::ApiError`: Casdoor rejected the request, e.g. "Unauthorized operation", or an OAuth error
- `Casdoor::HttpError`: an unexpected HTTP status, with `status` and `body`
- `Casdoor::InvalidTokenError`: `parse_jwt_token` can't verify the token
- All of them inherit from `Casdoor::Error`.

## Other APIs

Like `DoGetBytes` and `DoPost` of the Go SDK, any other API of Casdoor (see
[the Swagger docs](https://door.casdoor.com/swagger)) can be called with the authentication of the client:

```ruby
client.do_get_bytes(client.get_url('get-organization-applications', 'owner' => 'admin', 'organization' => 'casbin'))
client.do_get_response(client.get_url('get-sessions', 'owner' => 'casbin'))   # the whole response, e.g. "data2"
client.do_post('add-ldap', nil, ldap)                   # POST with a JSON body
client.do_post('set-password', nil, form, true)         # POST with a form body
```

## Development

```shell
bundle install
bundle exec rubocop
bundle exec rspec
```

Like the Go SDK, the tests of the APIs (`spec/<object>_spec.rb`, one for each `<object>_test.go`) run against a local
Casdoor started with `.ci/casdoor/init_data.json`; they are skipped unless `CASDOOR_TEST_ENDPOINT` is set:

```shell
docker run -d -p 8000:8000 -e driverName=sqlite -e dataSourceName='file:casdoor.db?cache=shared' \
  -e initDataFile=/init_data.json -v "$PWD/.ci/casdoor/init_data.json:/init_data.json:ro" casbin/casdoor-all-in-one
CASDOOR_TEST_ENDPOINT=http://localhost:8000 bundle exec rspec
```

## License

[Apache-2.0](LICENSE)
