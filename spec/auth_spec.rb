# frozen_string_literal: true

RSpec.describe Casdoor::Api::Auth do
  def self_signed_cert(key)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse('/CN=Casdoor Cert')
    cert.public_key = key
    cert.not_before = Time.now
    cert.not_after = Time.now + 3600
    cert.sign(key, OpenSSL::Digest.new('SHA256'))
    cert.to_pem
  end

  def new_client(certificate = nil)
    Casdoor::Client.new(endpoint: 'https://door.example.com', client_id: 'id', client_secret: 'secret',
                        organization_name: 'casbin', application_name: 'app-casbin', certificate: certificate)
  end

  let(:key) { OpenSSL::PKey::RSA.new(2048) }
  let(:client) { new_client(self_signed_cert(key)) }
  let(:claims) do
    { 'owner' => 'casbin', 'name' => 'alice', 'displayName' => 'Alice', 'tokenType' => 'access-token',
      'aud' => ['id'], 'exp' => Time.now.to_i + 600, 'iat' => Time.now.to_i }
  end
  let(:token_url) { 'https://door.example.com/api/login/oauth/access_token' }

  describe 'URLs' do
    it 'builds the sign-in URL' do
      expect(client.get_signin_url('https://app.example.com/callback')).to eq(
        'https://door.example.com/login/oauth/authorize?client_id=id&response_type=code' \
        '&redirect_uri=https%3A%2F%2Fapp.example.com%2Fcallback&scope=read&state=app-casbin'
      )
    end

    it 'builds the sign-up URLs' do
      expect(client.get_signup_url).to eq('https://door.example.com/signup/app-casbin')
      expect(client.get_signup_url('https://app.example.com/callback', state: 'xyz'))
        .to start_with('https://door.example.com/signup/oauth/authorize?client_id=id')
        .and end_with('&state=xyz')
    end

    it 'builds the profile URLs' do
      expect(client.get_user_profile_url('alice')).to eq('https://door.example.com/users/casbin/alice')
      expect(client.get_my_profile_url('a b')).to eq('https://door.example.com/account?access_token=a+b')
    end
  end

  describe 'OAuth tokens' do
    it 'exchanges the code for the tokens' do
      stub = stub_request(:post, token_url)
             .with(body: { grant_type: 'authorization_code', client_id: 'id', client_secret: 'secret', code: 'abc' })
             .to_return(body: { access_token: 'at', refresh_token: 'rt', token_type: 'Bearer' }.to_json)
      expect(client.get_oauth_token('abc')).to include('access_token' => 'at', 'refresh_token' => 'rt')
      expect(stub).to have_been_requested
    end

    it 'gets the token with a password' do
      stub_request(:post, token_url).with(body: hash_including(grant_type: 'password', username: 'alice'))
                                    .to_return(body: { access_token: 'at' }.to_json)
      expect(client.get_oauth_token_by_password('alice', '123')['access_token']).to eq('at')
    end

    it 'refreshes the token' do
      stub_request(:post, token_url).with(body: hash_including(grant_type: 'refresh_token', refresh_token: 'rt'))
                                    .to_return(body: { access_token: 'at2' }.to_json)
      expect(client.refresh_oauth_token('rt')['access_token']).to eq('at2')
    end

    it 'raises the OAuth errors' do
      stub_request(:post, token_url)
        .to_return(status: 400, body: { error: 'invalid_grant',
                                        error_description: 'authorization code is invalid' }.to_json)
      expect { client.get_oauth_token('bad') }
        .to raise_error(Casdoor::ApiError, 'invalid_grant: authorization code is invalid')
    end

    it 'raises the errors put into the access token' do
      stub_request(:post, token_url).to_return(body: { access_token: 'error: invalid client_id' }.to_json)
      expect { client.get_oauth_token('abc') }.to raise_error(Casdoor::ApiError, 'invalid client_id')
    end

    it 'introspects the token' do
      stub_request(:post, 'https://door.example.com/api/login/oauth/introspect')
        .with(basic_auth: %w[id secret], body: { token: 'at', token_type_hint: 'access_token' })
        .to_return(body: { active: true, username: 'alice' }.to_json)
      expect(client.introspect_token('at')).to include('active' => true)
    end

    it 'logs the user out with their token' do
      stub = stub_request(:post, 'https://door.example.com/api/sso-logout?logoutAll=false')
             .with(headers: { 'Authorization' => 'Bearer at' })
             .to_return(body: { status: 'ok' }.to_json)
      expect(client.logout('at', all_sessions: false)).to be(true)
      expect(stub).to have_been_requested
    end
  end

  describe '#parse_jwt_token' do
    it 'returns the claims of a valid token' do
      result = client.parse_jwt_token(JWT.encode(claims, key, 'RS256'))
      expect(result).to be_a(Casdoor::Claims)
      expect(result.name).to eq('alice')
      expect(result.display_name).to eq('Alice')
      expect(result.user).to be_a(Casdoor::User)
      expect(result.refresh_token?).to be(false)
    end

    it 'accepts a public key instead of a certificate' do
      client = new_client(key.public_key.to_pem)
      expect(client.parse_jwt_token(JWT.encode(claims, key, 'RS512')).owner).to eq('casbin')
    end

    it 'accepts EC keys' do
      ec_key = OpenSSL::PKey::EC.generate('prime256v1')
      client = new_client(self_signed_cert(ec_key))
      expect(client.parse_jwt_token(JWT.encode(claims, ec_key, 'ES256')).name).to eq('alice')
    end

    it 'accepts the tokens of shared applications' do
      token = JWT.encode(claims.merge('aud' => ['id-org-other']), key, 'RS256')
      expect(client.parse_jwt_token(token).name).to eq('alice')
    end

    it 'rejects the tokens signed by another key' do
      token = JWT.encode(claims, OpenSSL::PKey::RSA.new(2048), 'RS256')
      expect { client.parse_jwt_token(token) }.to raise_error(Casdoor::InvalidTokenError)
    end

    it 'rejects the expired tokens' do
      token = JWT.encode(claims.merge('exp' => Time.now.to_i - 10), key, 'RS256')
      expect { client.parse_jwt_token(token) }.to raise_error(Casdoor::InvalidTokenError, /expired/i)
    end

    it 'rejects the tokens issued to other applications' do
      token = JWT.encode(claims.merge('aud' => ['other-app']), key, 'RS256')
      expect { client.parse_jwt_token(token) }.to raise_error(Casdoor::InvalidTokenError, /other-app/)
      expect(client.parse_jwt_token(token, audience: 'other-app').name).to eq('alice')
      expect(client.parse_jwt_token(token, audience: false).name).to eq('alice')
    end

    it 'rejects the unsigned tokens' do
      token = JWT.encode(claims, nil, 'none')
      expect { client.parse_jwt_token(token) }.to raise_error(Casdoor::InvalidTokenError)
    end

    it 'requires the certificate' do
      expect { new_client.parse_jwt_token('a.b.c') }.to raise_error(Casdoor::Error, /certificate/)
    end
  end
end
