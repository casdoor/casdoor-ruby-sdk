# casdoor-ruby-sdk

[![CI](https://github.com/casdoor/casdoor-ruby-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/casdoor/casdoor-ruby-sdk/actions/workflows/ci.yml)

The Ruby SDK of [Casdoor](https://casdoor.ai/). It lets a Ruby application (Rails, Sinatra, Hanami, ...) sign users in
with Casdoor, verify the tokens issued by Casdoor, and manage the users, applications, roles, permissions and the
other objects of Casdoor through its API.

## Installation

Add it to the `Gemfile`:

```ruby
gem 'casdoor-ruby-sdk', git: 'https://github.com/casdoor/casdoor-ruby-sdk'
```

It requires Ruby 2.7 or later, and depends only on the [jwt](https://github.com/jwt/ruby-jwt) gem.

## Configuration

```ruby
require 'casdoor'

client = Casdoor::Client.new(
  endpoint: 'https://door.casdoor.com',      # the URL of your Casdoor
  client_id: 'xxx',                          # "Client ID" of the application in Casdoor
  client_secret: 'xxx',                      # "Client secret" of the application in Casdoor
  certificate: File.read('cert.pem'),        # "Certificate" of the application's cert, only needed to verify tokens
  organization_name: 'casbin',               # the organization of the users
  application_name: 'app-example'            # the application in Casdoor
)
```

The certificate is the public certificate shown on the edit page of the cert that the application uses
("Certs" → the application's cert → "Certificate"). A public key in PEM format works too.

`Casdoor::Client.new` also accepts `headers:` (added to every request), `open_timeout:` and `read_timeout:`.

## Signing users in

Casdoor signs users in with the OAuth 2.0 authorization code flow:

```ruby
# 1. Redirect the browser to the sign-in page of Casdoor
redirect_to client.get_signin_url('https://your-app.example.com/callback', state: session[:state] = SecureRandom.hex)

# 2. Casdoor redirects back to the callback with "code" and "state", exchange the code for the tokens
raise 'Invalid state' unless params[:state] == session[:state]
token = client.get_oauth_token(params[:code])
# => {"access_token" => "...", "id_token" => "...", "refresh_token" => "...", "expires_in" => 604800, ...}

# 3. Verify the access token and read the user in it
claims = client.parse_jwt_token(token['access_token'])
claims.name          # => "alice"
claims.owner         # => "casbin", the organization
claims.email
claims.user          # => Casdoor::User with the fields of the user
```

`parse_jwt_token` verifies the signature with the certificate, the expiration time, and that the token is issued to
this application (its client ID); otherwise it raises `Casdoor::InvalidTokenError`.

Other helpers:

```ruby
client.get_signup_url                                  # the sign-up page of the application
client.get_user_profile_url('alice', access_token)     # the profile page of a user
client.get_my_profile_url(access_token)                # the profile page of the signed-in user
client.refresh_oauth_token(token['refresh_token'])
client.get_oauth_token_by_password('alice', 'password') # needs the "password" grant type in the application
client.get_oauth_token_by_client_credentials           # needs the "client_credentials" grant type
client.introspect_token(token['access_token'])         # => {"active" => true, ...}
client.logout(token['access_token'])                   # signs the user out of Casdoor
```

## Calling the API as a user

By default the client calls the API as the application, with the client ID and secret, which has the permissions of
an admin of the application's organization. To call the API as the signed-in user instead:

```ruby
user_client = client.with_access_token(token['access_token'])
user = user_client.get_account
user.display_name = 'Alice'
user_client.update_user(user)
```

## Managing users

```ruby
user = client.get_user('alice')                 # in the client's organization, or client.get_user('org/alice')
user.display_name = 'Alice Smith'
user.email = 'alice@example.com'
user.properties = (user.properties || {}).merge('department' => 'R&D')
client.update_user(user)                         # => true when something changed

client.update_user(user, columns: %i[display_name email])   # only update these fields

client.add_user(Casdoor::User.new(name: 'bob', display_name: 'Bob', password: '123456'))
client.delete_user('bob')

client.get_users                                 # => [Casdoor::User]
users, total = client.get_pagination_users(1, 20, sort_field: 'created_time', sort_order: 'descend')
client.get_user_by_email('alice@example.com')
client.get_user_by_phone('13800000000')
client.get_user_by_user_id('uuid')               # by the "id" field of the user
client.get_user_count
client.set_password('casbin', 'alice', 'new-password')
client.check_user_password(name: 'alice', password: 'password')  # => true or false
```

The objects (`Casdoor::User`, `Casdoor::Application`, ...) keep all the fields returned by Casdoor, so an object that is
read, changed and updated never loses the fields this SDK doesn't know about. The fields can be read and written in
snake_case (`user.display_name`, `user.is_admin?`), or with their names in Casdoor (`user['displayName']`). The fields
whose names are taken by Ruby (e.g. `hash` of a user) can only be accessed with `[]`.

## Managing the other objects

The same methods exist for all the objects of Casdoor: adapters, applications, certs, enforcers, groups,
invitations, models, orders, organizations, payments, permissions, plans, pricings, products, providers, resources,
roles, subscriptions, syncers, tokens, transactions, users and webhooks.

```ruby
client.get_roles                                  # => [Casdoor::Role]
client.get_pagination_roles(1, 20)                # => [[Casdoor::Role], total]
client.get_role('admin')                          # => Casdoor::Role or nil
client.add_role(Casdoor::Role.new(name: 'admin', users: ['casbin/alice']))
client.update_role(role, columns: %i[users])
client.delete_role('admin')                       # by name, or by the object
```

Organizations, applications and tokens belong to `admin`, the other objects belong to the client's organization.
A different owner can be given by `"owner/name"`, by the `owner` field of the object, or by `owner:` in the list
methods. Extra query parameters of the list methods can be given in snake_case, e.g.
`client.get_applications(organization: 'casbin')`.

## Checking permissions

```ruby
client.enforce(%w[alice data1 read], permission_id: 'casbin/permission-1')   # => true or false
client.batch_enforce([%w[alice data1 read], %w[bob data2 write]], model_id: 'casbin/model-1')
# => [[true, false]], the results for each permission
```

One of `permission_id:`, `model_id:`, `resource_id:`, `enforcer_id:` or `owner:` chooses the policies to check.

## Errors

- `Casdoor::ApiError`: Casdoor rejected the request, e.g. "Unauthorized operation", or an OAuth error
- `Casdoor::HttpError`: an unexpected HTTP status, with `status` and `body`
- `Casdoor::InvalidTokenError`: `parse_jwt_token` can't verify the token
- All of them inherit from `Casdoor::Error`.

## Other APIs

The SDK covers the common APIs. Any other API of Casdoor (see [the Swagger docs](https://door.casdoor.com/swagger))
can be called with the authentication of the client:

```ruby
client.get_data('get-organization-applications', owner: 'admin', organization: 'casbin')  # GET, returns "data"
client.get_response('get-sessions', owner: 'casbin')    # GET, returns the whole response, e.g. "data2"
client.post_json('add-ldap', {}, ldap)                  # POST with a JSON body
client.post_form('set-password', {}, form)              # POST with a form body
```

## Development

```shell
bundle install
bundle exec rubocop
bundle exec rspec
```

The integration tests run against a real Casdoor, they are skipped unless `CASDOOR_TEST_ENDPOINT` is set. Start a
Casdoor with the test data, then run them:

```shell
docker run -d -p 8000:8000 -e driverName=sqlite -e dataSourceName='file:casdoor.db?cache=shared' \
  -e initDataFile=/init_data.json -v "$PWD/.ci/casdoor/init_data.json:/init_data.json:ro" casbin/casdoor-all-in-one
CASDOOR_TEST_ENDPOINT=http://localhost:8000 bundle exec rspec
```

## License

[Apache-2.0](LICENSE)
