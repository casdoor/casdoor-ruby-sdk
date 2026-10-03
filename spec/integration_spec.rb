# frozen_string_literal: true

require 'securerandom'

# Runs against a real Casdoor started with .ci/casdoor/init_data.json, see .github/workflows/ci.yml:
#
#   CASDOOR_TEST_ENDPOINT=http://localhost:8000 bundle exec rspec
RSpec.describe 'Casdoor API', :integration do
  def env(key, default)
    value = ENV.fetch(key, '')
    value.empty? ? default : value
  end

  def random_name(prefix)
    "#{prefix}_#{SecureRandom.hex(4)}"
  end

  let(:client) do
    Casdoor::Client.new(
      endpoint: env('CASDOOR_TEST_ENDPOINT', 'http://localhost:8000'),
      client_id: env('CASDOOR_TEST_CLIENT_ID', 'casdoor-ruby-sdk-ci-client'),
      client_secret: env('CASDOOR_TEST_CLIENT_SECRET', 'casdoor-ruby-sdk-ci-secret'),
      organization_name: env('CASDOOR_TEST_ORGANIZATION', 'casbin'),
      application_name: env('CASDOOR_TEST_APPLICATION', 'app-vue-python-example')
    )
  end

  it 'adds, gets, updates and deletes an application' do
    name = random_name('application')
    application = Casdoor::Application.new(owner: 'admin', name: name, display_name: name, organization: 'casbin',
                                           homepage_url: 'https://casdoor.org', description: 'Casdoor Website')
    expect(client.add_application(application)).to be(true)

    expect(client.get_applications.map(&:name)).to include(name)
    expect(client.get_applications(organization: 'casbin').map(&:name)).to include(name)

    application = client.get_application(name)
    expect(application.homepage_url).to eq('https://casdoor.org')

    application.description = 'Updated Casdoor Website'
    expect(client.update_application(application)).to be(true)
    updated = client.get_application(name)
    expect(updated.description).to eq('Updated Casdoor Website')
    # The fields that weren't changed are kept
    expect(updated.homepage_url).to eq('https://casdoor.org')

    expect(client.delete_application(name)).to be(true)
    expect(client.get_application(name)).to be_nil
  end

  it 'adds, gets, updates and deletes a user' do
    name = random_name('user')
    user = Casdoor::User.new(name: name, display_name: 'Alice', email: "#{name}@example.com", password: '123456')
    expect(client.add_user(user)).to be(true)

    user = client.get_user(name)
    expect(user.owner).to eq('casbin')
    expect(user.display_name).to eq('Alice')
    expect(client.get_user_by_email("#{name}@example.com").name).to eq(name)
    expect(client.get_user_by_user_id(user.id).name).to eq(name)
    expect(client.get_users.map(&:name)).to include(name)
    users, total = client.get_pagination_users(1, 100)
    expect(users.size).to be <= 100
    expect(total).to be >= 1
    expect(client.get_user_count).to be >= 1

    user.display_name = 'Alice Updated'
    user.title = 'Engineer'
    expect(client.update_user(user)).to be(true)
    user = client.get_user(name)
    expect(user.display_name).to eq('Alice Updated')
    expect(user.title).to eq('Engineer')

    # Only the given columns are updated
    user.display_name = 'Ignored'
    user.affiliation = 'Casbin'
    expect(client.update_user(user, columns: %i[affiliation])).to be(true)
    user = client.get_user(name)
    expect(user.display_name).to eq('Alice Updated')
    expect(user.affiliation).to eq('Casbin')

    expect(client.check_user_password(name: name, password: '123456')).to be(true)
    expect(client.check_user_password(name: name, password: 'wrong')).to be(false)
    expect(client.set_password('casbin', name, '654321')).to be(true)
    expect(client.check_user_password(name: name, password: '654321')).to be(true)

    expect(client.delete_user(name)).to be(true)
    expect(client.get_user(name)).to be_nil
  end

  it 'adds, gets, updates and deletes a role' do
    name = random_name('role')
    expect(client.add_role(name: name, display_name: name, users: [], roles: [], domains: [], is_enabled: true))
      .to be(true)
    role = client.get_role(name)
    role.description = 'Role of the Ruby SDK'
    expect(client.update_role(role)).to be(true)
    expect(client.get_role(name).description).to eq('Role of the Ruby SDK')
    expect(client.delete_role(role)).to be(true)
    expect(client.get_role(name)).to be_nil
  end

  it 'signs a user in and verifies the token' do
    application = client.get_application(client.application_name)
    cert = client.get_cert("admin/#{application.cert}")
    app_client = Casdoor::Client.new(
      endpoint: client.endpoint, client_id: client.client_id, client_secret: client.client_secret,
      organization_name: application.organization, application_name: application.name,
      certificate: cert.certificate
    )

    token = app_client.get_oauth_token_by_password('admin', '123')
    claims = app_client.parse_jwt_token(token['access_token'])
    expect(claims.owner).to eq(application.organization)
    expect(claims.name).to eq('admin')
    expect(app_client.parse_jwt_token(token['refresh_token']).refresh_token?).to be(true)

    account = app_client.with_access_token(token['access_token']).get_account
    expect(account.name).to eq('admin')
    expect(app_client.introspect_token(token['access_token'])['active']).to be(true)

    refreshed = app_client.refresh_oauth_token(token['refresh_token'])
    expect(app_client.parse_jwt_token(refreshed['access_token']).name).to eq('admin')

    expect { app_client.get_oauth_token_by_password('admin', 'wrong') }.to raise_error(Casdoor::ApiError)
  end
end
