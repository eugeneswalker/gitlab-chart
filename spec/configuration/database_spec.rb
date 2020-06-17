require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Database configuration' do
  let(:default_values) do
    {
      'certmanager-issuer' => { 'email' => 'test@example.com' },
      'global' => {
        'psql' => {
          'host' => '',
          'serviceName' => '',
          'port' => nil,
          'pool' => '',
          'username' => '',
          'database' => '',
          'preparedStatements' => '',
          'password' => { 'secret' => '', 'key' => '' },
          'load_balancing' => {}
        }
      },
      'postgresql' => { 'install' => true }
    }
  end

  describe 'global.psql.load_balancing' do
    context 'when PostgreSQL is installed' do
      let(:values) do
        # merging in this order, so the local overrides win.
        default_values.merge({
          'global' => {
            'psql' => {
              'host' => 'primary',
              'load_balancing' => {
                'hosts' => [ 'secondary-1', 'secondary-2']
              }
            }
          },
        })
      end

      it 'fail due to checkConfig' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).not_to eq(0)
        expect(t.stderr).to include("PostgreSQL is set to install, but database load balancing is also enabled.")
      end
    end

    describe 'global.psql.load_balancing.hosts' do
      let(:values) do
        default_values.merge({
          'global' => {
            'psql' => {
              'host' => 'primary',
              'load_balancing' => {
                'hosts' => [ 'secondary-1', 'secondary-2']
              }
            }
          },
          'postgresql' => { 'install' => false }
        })
      end

      context 'when configured' do
        it 'populate configuration with load_balancing.hosts array' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).to eq(0)
          expect(t.dig('ConfigMap/test-webservice','data','database.yml.erb')).to include("host: \"primary\"")
          expect(t.dig('ConfigMap/test-webservice','data','database.yml.erb')).to include("load_balancing:")
          expect(t.dig('ConfigMap/test-webservice','data','database.yml.erb')).to include("hosts:")
          expect(t.dig('ConfigMap/test-webservice','data','database.yml.erb')).to include("- secondary-1")
        end
      end   
    end

    describe 'global.psql.load_balancing.discover' do
      let(:values) do
        default_values.merge({
          'global' => {
            'psql' => {
              'host' => 'primary',
              'load_balancing' => {
                'discover' => {
                  # this is the only required setting
                  'record' => 'secondary.db.service'
                }
              }
            }
          },
          'postgresql' => { 'install' => false }
        })
      end

      context 'when configured' do
        it 'populate configuration wtih load_balancing.discover.record' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).to eq(0)
          expect(t.dig('ConfigMap/test-webservice','data','database.yml.erb')).to include("host: \"primary\"")
          expect(t.dig('ConfigMap/test-webservice','data','database.yml.erb')).to include("load_balancing:")
          expect(t.dig('ConfigMap/test-webservice','data','database.yml.erb')).to include("discover:")
          expect(t.dig('ConfigMap/test-webservice','data','database.yml.erb')).to include("record: \"secondary.db.service\"")
        end
      end   
    end
  end
end
