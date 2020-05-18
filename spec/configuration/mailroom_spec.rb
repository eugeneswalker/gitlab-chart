require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Mailroom configuration' do
  let(:default_values) do
    { 'certmanager-issuer' => { 'email' => 'test@example.com' } }
  end

  describe 'When globa.redis.queues is present' do
    let(:values) do
      {
        'global' => {
          'appConfig' => {
            'incomingEmail' => {
              'enabled' => true,
              'password' => { 'secret' => 'mailroom-password'}
            }
          },
          'redis' => {
            'host' => 'resque.redis',
            'port' => 6379,
            'sentinels' => [
              {'host' => 's1.resque.redis', 'port' => 26379},
              {'host' => 's2.resque.redis', 'port' => 26379}
            ],
            'queues' => {
              'host' => 'queue.redis',
              'sentinels' => [
                {'host' => 's1.queue.redis', 'port' => 26379},
                {'host' => 's2.queue.redis', 'port' => 26379}
              ]
            }
          }
        },
        'redis' => { 'install' => false }
      }.merge(default_values)
    end

    it 'populates the Queues instance' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0)
      # check the `queue.redis` is populated instread of `resque.redis`
      expect(t.dig('ConfigMap/test-mailroom','data','mail_room.yml')).not_to include("resque.redis")
      expect(t.dig('ConfigMap/test-mailroom','data','mail_room.yml')).to include("queue.redis")
    end

    it 'separate sentinels are populated' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0)
      # check that queues.sentinels are used instead of global.sentinels
      expect(t.dig('ConfigMap/test-mailroom','data','mail_room.yml')).to include(":sentinels:")
      expect(t.dig('ConfigMap/test-mailroom','data','mail_room.yml')).to include("s1.queue.redis")
      expect(t.dig('ConfigMap/test-mailroom','data','mail_room.yml')).not_to include("s1.resque.redis")
    end
  end
end
